# Produces the single self-contained Atlas CMMS fat jar (API + web UI) ready to
# run on a server, plus deployment helpers.
#
# Pipeline:
#   1. generate the AGPLv3 source bundle  -> api/src/main/resources/static/source/
#   2. `mvn package` at the repo root     -> builds the frontend, deploys it into
#                                            the api module's static resources, and
#                                            builds the fat jar (api/target/app.jar)
#   3. collect artifacts into ./dist
#
# Output:  dist/atlas-cmms.jar   (run with: java -jar atlas-cmms.jar)
#          dist/.env             (copy of dev.env to fill in on the server)
#          dist/cmms.service     (systemd unit for Linux deployment)
#
# Usage:   ./scripts/build.ps1 [-SkipFrontend] [-SkipSourceBundle]
#          The SPA's API base URL is taken from API_URL/PUBLIC_API_URL in dev.env.
param(
    [switch]$SkipFrontend,
    [switch]$SkipSourceBundle
)
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path "$PSScriptRoot/..").Path
$ApiDir   = Join-Path $RepoRoot 'api'
$Dist     = Join-Path $RepoRoot 'dist'
$EnvFile  = Join-Path $RepoRoot 'dev.env'

function Read-Env([string]$Key, [string]$Default) {
    if (Test-Path $EnvFile) {
        $line = Get-Content $EnvFile | Where-Object { $_ -match "^$Key=" } | Select-Object -Last 1
        if ($line) { $v = ($line -split '=', 2)[1].Trim(); if ($v) { return $v } }
    }
    return $Default
}

New-Item -ItemType Directory -Force -Path $Dist | Out-Null

# ── 1) AGPLv3 complete-corresponding-source bundle (embedded -> /source-code/download) ──
if (-not $SkipSourceBundle) {
    Write-Host "==> Generating source bundle"
    & (Join-Path $PSScriptRoot 'build-source-bundle.ps1')
}

# ── 2) Root maven build: frontend -> api static -> fat jar ──
$apiUrl   = Read-Env 'API_URL' (Read-Env 'PUBLIC_API_URL' 'http://localhost:8080')
$provider = Read-Env 'OAUTH2_PROVIDER' 'microsoft'
$sso      = Read-Env 'ENABLE_SSO' 'true'

$mvnArgs = @(
    '-DskipTests',
    "-DskipFrontend=$([bool]$SkipFrontend)".ToLower(),
    "-Dfrontend.api.url=$apiUrl",
    "-Dfrontend.oauth2.provider=$provider",
    "-Dfrontend.enable.sso=$sso",
    'clean', 'package'
)
Write-Host "==> (in api) mvn $($mvnArgs -join ' ')"
Push-Location $ApiDir
try {
    if (Test-Path (Join-Path $ApiDir 'mvnw.cmd')) {
        & (Join-Path $ApiDir 'mvnw.cmd') @mvnArgs
    } else {
        & mvn @mvnArgs
    }
    if ($LASTEXITCODE -ne 0) { throw "maven build failed" }
} finally { Pop-Location }

# ── 3) Collect artifacts ──
$jar = Get-ChildItem (Join-Path $ApiDir 'target') -Filter '*.jar' |
    Where-Object { $_.Name -notlike '*.original' } | Select-Object -First 1
if (-not $jar) { throw "No jar produced in api/target" }
Copy-Item $jar.FullName (Join-Path $Dist 'atlas-cmms.jar') -Force

if (Test-Path $EnvFile) { Copy-Item $EnvFile (Join-Path $Dist '.env') -Force }
Copy-Item (Join-Path $RepoRoot 'cmms.service') (Join-Path $Dist 'cmms.service') -Force

Write-Host ""
Write-Host "Build complete -> $Dist"
Write-Host "  dist/atlas-cmms.jar   single jar (API + web UI)"
Write-Host "  dist/.env             fill in real values before running"
Write-Host "  dist/cmms.service     systemd unit (Linux)"
Write-Host ""
Write-Host "Run locally:  set -a; source dist/.env; set +a; java -jar dist/atlas-cmms.jar"
Write-Host "Then open:    http://localhost:8080"
