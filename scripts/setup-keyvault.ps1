<#
.SYNOPSIS
    Creates the production Key Vault, loads the secrets out of prod.env, and
    wires the `cmms` web app to read them as Key Vault references.

.DESCRIPTION
    Run once, by hand, before the first release. Everything it does is
    idempotent: re-running it re-reads prod.env and updates any secret whose
    value has changed, which is also how you rotate.

    Five steps:
      1. Create the vault (RBAC authorisation, soft delete, purge protection).
      2. Grant you Key Vault Secrets Officer and the web app's managed
         identity Key Vault Secrets User.
      3. Push db-password, jwt-secret-key and oauth2-client-secret from
         prod.env.
      4. Point keyVaultReferenceIdentity at the identity that actually exists.
         This is currently wrong on the app and is what stops the container
         from starting.
      5. Set DB_PWD / JWT_SECRET_KEY / OAUTH2_CLIENT_SECRET to unversioned
         @Microsoft.KeyVault(...) references.

    Secret VALUES are never written to the console, the transcript or a file.
    They are passed to `az` as arguments, which is briefly visible in the local
    process list - acceptable for an interactive admin run on your own machine,
    but do not run this on a shared or logged host.

.PARAMETER EnvFile
    The runtime env file holding the real secrets. Defaults to prod.env in the
    repository root. This is NOT .azure/env/prod.env, which is committed and
    non-secret.

.PARAMETER WhatIf
    Shows every change without making one. Worth doing first.

.EXAMPLE
    .\scripts\setup-keyvault.ps1 -WhatIf
    .\scripts\setup-keyvault.ps1

.NOTES
    Needs an `az login` session with rights to create a vault and role
    assignments in the resource group. Microsoft Graph is blocked by
    Conditional Access in this tenant, so the script reads your object id from
    the access token's `oid` claim rather than calling `az ad signed-in-user`.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string] $EnvFile,
    [string] $VaultName             = 'enkm-cmms-prod',
    [string] $ResourceGroup         = 'New-Implementations',
    [string] $WebAppName            = 'cmms',
    [string] $Location              = 'canadaeast',
    [string] $SubscriptionId        = 'd14f7b8e-d71d-4106-ab93-990c96df467c',

    # ua-id-9ca4, the user-assigned identity attached to the cmms web app.
    [string] $AppIdentityResourceId = '/subscriptions/d14f7b8e-d71d-4106-ab93-990c96df467c/resourcegroups/New-Implementations/providers/Microsoft.ManagedIdentity/userAssignedIdentities/ua-id-9ca4',
    [string] $AppPrincipalId        = '11b7cf2e-710f-4401-987d-4f98e466486b',

    # Purge protection cannot be turned off once enabled. On by default because
    # this is production; pass -NoPurgeProtection for a throwaway vault.
    [switch] $NoPurgeProtection,

    # Create the vault and secrets but leave the web app untouched.
    [switch] $SkipWebApp
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Secret name in the vault  ->  key in prod.env  ->  app setting on the web app.
# smtp-password is deliberately absent: Key Vault rejects an empty value, and
# application.yml declares ${SMTP_PWD:} so the app defaults it to empty.
$SecretMap = @(
    [pscustomobject]@{ Secret = 'db-password';          EnvKey = 'DB_PWD';               AppSetting = 'DB_PWD' }
    [pscustomobject]@{ Secret = 'jwt-secret-key';       EnvKey = 'JWT_SECRET_KEY';       AppSetting = 'JWT_SECRET_KEY' }
    [pscustomobject]@{ Secret = 'oauth2-client-secret'; EnvKey = 'OAUTH2_CLIENT_SECRET'; AppSetting = 'OAUTH2_CLIENT_SECRET' }
)

# ── helpers ───────────────────────────────────────────────────────────────

function Write-Step { param([string] $Text) Write-Host "`n=== $Text" -ForegroundColor Cyan }
function Write-Ok   { param([string] $Text) Write-Host "    $Text" -ForegroundColor Green }
function Write-Skip { param([string] $Text) Write-Host "    $Text" -ForegroundColor DarkGray }
function Write-Warn { param([string] $Text) Write-Host "    $Text" -ForegroundColor Yellow }

# Runs az, returns stdout, throws with az's own message on failure.
#
# Deliberately a SIMPLE function with no param() block. An advanced function
# would try to bind a leading-dash token as one of its own parameters, and
# `-o json` fails with "the parameter name 'o' is ambiguous" because it
# matches the common parameters -OutVariable and -OutBuffer. With no param
# block every token lands in the automatic $args and reaches az untouched.
function Invoke-Az {
    $azArgs = $args
    $out = & az @azArgs 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "az $($azArgs -join ' ')`n$($out -join "`n")"
    }
    return ($out -join "`n")
}

# Same, but a non-zero exit is an expected answer rather than an error.
function Test-Az {
    $azArgs = $args
    & az @azArgs *> $null
    return ($LASTEXITCODE -eq 0)
}

<#
Parses a KEY=VALUE env file.

Splits on the FIRST '=' only. This matters: base64 values are padded with '='
(jwt-secret-key ends with one), and splitting on every '=' silently truncates
them - which would push a corrupt key into the vault and fail the app at
startup with "Illegal base64 character".
#>
function Read-EnvFile {
    param([Parameter(Mandatory)] [string] $Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Env file not found: $Path`nPass -EnvFile if it lives elsewhere. This is the gitignored runtime prod.env, not .azure/env/prod.env."
    }

    $map = @{}
    foreach ($rawLine in Get-Content -LiteralPath $Path) {
        $line = $rawLine.TrimEnd("`r")
        if ($line -match '^\s*(#|$)') { continue }

        $idx = $line.IndexOf('=')
        if ($idx -lt 1) { continue }

        $key = $line.Substring(0, $idx).Trim()
        $val = $line.Substring($idx + 1).Trim()

        # Strip one layer of matching surrounding quotes, if present.
        if ($val.Length -ge 2 -and
            (($val.StartsWith('"') -and $val.EndsWith('"')) -or
             ($val.StartsWith("'") -and $val.EndsWith("'")))) {
            $val = $val.Substring(1, $val.Length - 2)
        }
        $map[$key] = $val
    }
    return $map
}

# JwtTokenProvider.init() runs this through Base64.getDecoder().decode() and
# then Keys.hmacShaKeyFor(), so anything that is not strict base64 decoding to
# >= 32 bytes kills the container at startup rather than at first use.
function Test-JwtKey {
    param([Parameter(Mandatory)] [string] $Value)
    try   { $bytes = [Convert]::FromBase64String($Value) }
    catch { return "not valid base64 (JwtTokenProvider base64-decodes it; generate one with: openssl rand -base64 48)" }
    if ($bytes.Length -lt 32) {
        return "decodes to only $($bytes.Length) bytes; HMAC-SHA256 needs at least 32 (openssl rand -base64 48)"
    }
    return $null
}

# Graph is blocked by Conditional Access here, so `az ad signed-in-user show`
# fails. The access token carries the same object id in its `oid` claim.
function Get-SignedInObjectId {
    $tokenJson = Invoke-Az account get-access-token --resource https://management.azure.com/ -o json
    $payload   = ($tokenJson | ConvertFrom-Json).accessToken.Split('.')[1]
    $payload   = $payload.Replace('-', '+').Replace('_', '/')
    switch ($payload.Length % 4) { 2 { $payload += '==' } 3 { $payload += '=' } }
    $claims = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload)) | ConvertFrom-Json
    if (-not $claims.oid) { throw "Could not read an 'oid' claim from the access token; pass your object id another way." }
    return $claims.oid
}

function Grant-Role {
    param(
        [Parameter(Mandatory)] [string] $ObjectId,
        [Parameter(Mandatory)] [ValidateSet('User', 'ServicePrincipal')] [string] $PrincipalType,
        [Parameter(Mandatory)] [string] $Role,
        [Parameter(Mandatory)] [string] $Scope,
        [Parameter(Mandatory)] [string] $Who
    )

    $existing = Invoke-Az role assignment list --scope $Scope --query "[?principalId=='$ObjectId'].roleDefinitionName" -o tsv
    if ($existing -and ($existing -split "`n") -contains $Role) {
        Write-Skip "$Who already has $Role"
        return
    }

    if (-not $PSCmdlet.ShouldProcess($Who, "grant $Role")) { return }
    Invoke-Az role assignment create --assignee-object-id $ObjectId --assignee-principal-type $PrincipalType `
        --role $Role --scope $Scope --only-show-errors | Out-Null
    Write-Ok "granted $Role to $Who"
}

# ── 0. context ────────────────────────────────────────────────────────────

if (-not $EnvFile) {
    $EnvFile = Join-Path (Split-Path -Parent $PSScriptRoot) 'prod.env'
}

Write-Step "Context"
if (-not (Test-Az account show)) { throw "Not logged in. Run: az login" }
$account = Invoke-Az account show -o json | ConvertFrom-Json
if ($account.id -ne $SubscriptionId) {
    Write-Warn "active subscription is $($account.id); switching to $SubscriptionId"
    Invoke-Az account set --subscription $SubscriptionId | Out-Null
}
Write-Ok "subscription : $SubscriptionId"
Write-Ok "signed in as : $($account.user.name)"
Write-Ok "env file     : $EnvFile"
Write-Ok "vault        : $VaultName  (rg $ResourceGroup, $Location)"
if ($WhatIfPreference) { Write-Warn "-WhatIf: nothing will be changed" }

# ── 1. read and validate the secrets before touching Azure ────────────────

Write-Step "Reading secrets from prod.env"
$envMap  = Read-EnvFile -Path $EnvFile
$secrets = @{}
$problems = @()

foreach ($row in $SecretMap) {
    $value = if ($envMap.ContainsKey($row.EnvKey)) { $envMap[$row.EnvKey] } else { $null }
    if ([string]::IsNullOrWhiteSpace($value)) {
        $problems += "$($row.EnvKey) is missing or empty in $EnvFile"
        continue
    }
    if ($row.EnvKey -eq 'JWT_SECRET_KEY') {
        $why = Test-JwtKey -Value $value
        if ($why) { $problems += "JWT_SECRET_KEY is $why"; continue }
    }
    $secrets[$row.Secret] = $value
    Write-Ok ("{0,-22} <- {1,-22} ({2} chars)" -f $row.Secret, $row.EnvKey, $value.Length)
}

if ($problems.Count -gt 0) {
    throw "Cannot continue:`n  - " + ($problems -join "`n  - ")
}
Write-Skip "smtp-password intentionally not stored: Key Vault rejects empty values and SMTP_PWD defaults to empty"

# ── 2. the vault ──────────────────────────────────────────────────────────

Write-Step "Key Vault"
$vaultExists = Test-Az keyvault show --name $VaultName --resource-group $ResourceGroup

if ($vaultExists) {
    Write-Skip "$VaultName already exists"
    $vault = Invoke-Az keyvault show --name $VaultName --resource-group $ResourceGroup -o json | ConvertFrom-Json
    if (-not $vault.properties.enableRbacAuthorization) {
        throw "$VaultName uses access policies, not RBAC. This script and the web app both assume RBAC. Convert it, or use a different vault name."
    }
} else {
    # A soft-deleted vault holds the name until it is purged or recovered.
    $deleted = Invoke-Az keyvault list-deleted --query "[?name=='$VaultName'].id" -o tsv
    if ($deleted) {
        throw "$VaultName exists in a soft-deleted state. Recover it with:`n  az keyvault recover --name $VaultName`nor purge it (if purge protection allows) before re-running."
    }

    if ($PSCmdlet.ShouldProcess($VaultName, "create Key Vault")) {
        $createArgs = @(
            'keyvault', 'create',
            '--name', $VaultName,
            '--resource-group', $ResourceGroup,
            '--location', $Location,
            '--enable-rbac-authorization', 'true',
            '--retention-days', '7',
            '--only-show-errors'
        )
        if (-not $NoPurgeProtection) { $createArgs += @('--enable-purge-protection', 'true') }
        Invoke-Az @createArgs | Out-Null
        Write-Ok "created $VaultName"
        if (-not $NoPurgeProtection) { Write-Warn "purge protection is ON and cannot be disabled" }
    }
}

$vaultScope = if ($WhatIfPreference -and -not $vaultExists) {
    "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.KeyVault/vaults/$VaultName"
} else {
    Invoke-Az keyvault show --name $VaultName --resource-group $ResourceGroup --query id -o tsv
}

# ── 3. roles ──────────────────────────────────────────────────────────────

Write-Step "Role assignments"
if ($WhatIfPreference -and -not $vaultExists) {
    Write-Skip "vault does not exist yet; roles would be granted after creation"
} else {
    $me = Get-SignedInObjectId
    Grant-Role -ObjectId $me -PrincipalType User `
        -Role 'Key Vault Secrets Officer' -Scope $vaultScope -Who "you ($($account.user.name))"
    Grant-Role -ObjectId $AppPrincipalId -PrincipalType ServicePrincipal `
        -Role 'Key Vault Secrets User' -Scope $vaultScope -Who 'the cmms web app identity (ua-id-9ca4)'
}

# ── 4. secrets ────────────────────────────────────────────────────────────

Write-Step "Secrets"
if ($WhatIfPreference -and -not $vaultExists) {
    foreach ($name in $secrets.Keys) { Write-Skip "would set $name" }
} else {
    # A role assignment made seconds ago may not have reached the data plane
    # yet, so the first write gets a few attempts before giving up.
    $first = $true
    foreach ($row in $SecretMap) {
        $name  = $row.Secret
        $value = $secrets[$name]
        if (-not $PSCmdlet.ShouldProcess("$VaultName/$name", 'set secret')) { continue }

        $attempts = if ($first) { 8 } else { 1 }
        for ($i = 1; $i -le $attempts; $i++) {
            try {
                Invoke-Az keyvault secret set --vault-name $VaultName --name $name --value $value `
                    --only-show-errors -o none | Out-Null
                Write-Ok "set $name"
                break
            } catch {
                if ($i -eq $attempts) {
                    throw "Could not write $name.`nIf this says Forbidden, the Key Vault Secrets Officer assignment has not propagated yet - wait a minute and re-run.`n$_"
                }
                if ($i -eq 1) { Write-Skip "waiting for RBAC to propagate..." }
                Start-Sleep -Seconds 15
            }
        }
        $first = $false
    }
}

# ── 5. the web app ────────────────────────────────────────────────────────

if ($SkipWebApp) {
    Write-Step "Web app"
    Write-Skip "-SkipWebApp: leaving $WebAppName untouched"
    return
}

Write-Step "Web app: keyVaultReferenceIdentity"
$currentIdentity = Invoke-Az webapp show --name $WebAppName --resource-group $ResourceGroup `
    --query keyVaultReferenceIdentity -o tsv

if ($currentIdentity -eq $AppIdentityResourceId) {
    Write-Skip "already points at ua-id-9ca4"
} else {
    Write-Warn "currently '$currentIdentity'"
    if ($currentIdentity -eq 'SystemAssigned') {
        Write-Warn "the app has no system-assigned identity, so every reference would fail to resolve and the container would not start"
    }
    if ($PSCmdlet.ShouldProcess($WebAppName, 'set keyVaultReferenceIdentity to ua-id-9ca4')) {
        Invoke-Az webapp update --name $WebAppName --resource-group $ResourceGroup `
            --set "keyVaultReferenceIdentity=$AppIdentityResourceId" --only-show-errors -o none | Out-Null
        Write-Ok "now points at ua-id-9ca4"
    }
}

Write-Step "Web app: application settings"
# Unversioned on purpose - rotation then takes effect on the next restart with
# no redeploy. The release pipeline never names these keys, so they survive it.
$settingArgs = foreach ($row in $SecretMap) {
    "$($row.AppSetting)=@Microsoft.KeyVault(VaultName=$VaultName;SecretName=$($row.Secret))"
}
if ($PSCmdlet.ShouldProcess($WebAppName, "set $($SecretMap.Count) Key Vault reference settings")) {
    Invoke-Az webapp config appsettings set --name $WebAppName --resource-group $ResourceGroup `
        --settings @settingArgs --only-show-errors -o none | Out-Null
    foreach ($row in $SecretMap) { Write-Ok "$($row.AppSetting) -> $VaultName/$($row.Secret)" }
}

# ── 6. verify ─────────────────────────────────────────────────────────────

Write-Step "Verifying reference resolution"
if ($WhatIfPreference) {
    Write-Skip "-WhatIf: nothing to verify"
} else {
    $siteId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Web/sites/$WebAppName"
    $url    = "https://management.azure.com$siteId/config/configreferences/appsettings?api-version=2022-03-01"
    try {
        $refs = Invoke-Az rest --method get --url $url -o json | ConvertFrom-Json
        $any = $false
        foreach ($r in $refs.value) {
            $status = $r.properties.status
            $any = $true
            if ($status -eq 'Resolved') { Write-Ok    "$($r.name): $status" }
            else                        { Write-Warn  "$($r.name): $status - $($r.properties.details)" }
        }
        if (-not $any) { Write-Skip "no references reported yet; App Service can take a minute" }
        Write-Host ""
        Write-Host "If anything is not Resolved, wait for RBAC to propagate and restart the app:" -ForegroundColor DarkGray
        Write-Host "  az webapp restart --name $WebAppName --resource-group $ResourceGroup" -ForegroundColor DarkGray
    } catch {
        Write-Skip "could not read reference status from ARM; check Configuration -> Application settings in the portal"
    }
}

Write-Host "`nDone. Remaining before the first release:" -ForegroundColor Cyan
Write-Host "  - git push origin main   (the tag alone is not enough for a clean history)"
Write-Host "  - decide the stgcaneastcmms public-network-access question; file downloads fail while it is off"
Write-Host ""
