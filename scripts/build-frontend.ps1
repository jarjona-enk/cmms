# Builds the React frontend and copies the compiled SPA into the api module's
# static resources (api/src/main/resources/static), so Spring Boot serves it.
#
# Use this for quick local iteration: rebuild the SPA, then run the API with
#   cd api; .\mvnw.cmd spring-boot:run      (or run the packaged jar)
# and browse http://localhost:8080.
#
# For a full server build (frontend + fat jar in one step) use `mvn package`
# at the repo root instead - see pom.xml.
#
# Reads dev.env (if present) to bake the public values into the bundle.
$ErrorActionPreference = 'Stop'

$RepoRoot  = (Resolve-Path "$PSScriptRoot/..").Path
$FrontDir  = Join-Path $RepoRoot 'frontend'
$StaticDir = Join-Path $RepoRoot 'api/src/main/resources/static'
$EnvFile   = Join-Path $RepoRoot 'dev.env'

function Read-Env([string]$Key, [string]$Default) {
    if (Test-Path $EnvFile) {
        $line = Get-Content $EnvFile | Where-Object { $_ -match "^$Key=" } | Select-Object -Last 1
        if ($line) { $v = ($line -split '=', 2)[1].Trim(); if ($v) { return $v } }
    }
    return $Default
}

# Bake public runtime values into the static bundle
$env:REACT_APP_API_URL         = Read-Env 'API_URL' (Read-Env 'PUBLIC_API_URL' 'http://localhost:8080')
$env:REACT_APP_ENABLE_SSO      = Read-Env 'ENABLE_SSO' 'false'
$env:REACT_APP_OAUTH2_PROVIDER = Read-Env 'OAUTH2_PROVIDER' ''
$env:REACT_APP_GOOGLE_KEY      = Read-Env 'GOOGLE_KEY' ''
$env:NODE_OPTIONS              = '--max_old_space_size=4096'

Write-Host "==> Building frontend (API_URL=$($env:REACT_APP_API_URL))"
Push-Location $FrontDir
try {
    npm ci    # exact, reproducible install from package-lock.json (.npmrc sets legacy-peer-deps)
    if ($LASTEXITCODE -ne 0) { throw "npm ci failed" }
    npm run build
    if ($LASTEXITCODE -ne 0) { throw "npm run build failed" }
} finally { Pop-Location }

Write-Host "==> Deploying SPA into $StaticDir"
# Remove only the SPA-owned subtree; keep committed api assets (api-docs.html, css/, images/)
$spaStatic = Join-Path $StaticDir 'static'
if (Test-Path $spaStatic) { Remove-Item -Recurse -Force $spaStatic }
New-Item -ItemType Directory -Force -Path $StaticDir | Out-Null
Copy-Item -Recurse -Force (Join-Path $FrontDir 'build/*') $StaticDir

Write-Host "Done. The SPA is now served by Spring from /static at http://localhost:8080"
