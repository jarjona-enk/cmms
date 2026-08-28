# Generates the AGPLv3 "complete corresponding source" archive of this
# repository. The same archive is produced automatically inside the API Docker
# image (see api/Dockerfile); this script is for generating it outside Docker,
# e.g. for a local (non-Docker) build or to hand a copy to whoever requests it.
#
# Usage: ./scripts/build-source-bundle.ps1 [-OutDir <path>]
#   Default output: api/src/main/resources/static/source/atlas-cmms-source.zip
#   (so a subsequent `mvn package` embeds it for /source-code/download)
param(
    [string]$OutDir
)
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path "$PSScriptRoot/..").Path
if (-not $OutDir) {
    $OutDir = Join-Path $RepoRoot 'api/src/main/resources/static/source'
}
$OutFile = Join-Path $OutDir 'atlas-cmms-source.zip'

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
if (Test-Path $OutFile) { Remove-Item $OutFile -Force }

$exclude = @(
    '\.git\', '\node_modules\', 'api\target\',
    '\build\', '\dist\', '\.gradle\', '\.idea\',
    'api\src\main\resources\static\source\'
)

$files = Get-ChildItem -Path $RepoRoot -Recurse -File | Where-Object {
    $full = $_.FullName
    -not ($exclude | Where-Object { $full -like "*$_*" })
}

Push-Location $RepoRoot
try {
    Compress-Archive -Path ($files | ForEach-Object { $_.FullName }) -DestinationPath $OutFile -Force
}
finally {
    Pop-Location
}

Write-Host "Source bundle written to: $OutFile"
