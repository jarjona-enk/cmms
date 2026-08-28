# Runs a local MinIO container for testing, using the credentials from dev.env.
# The app auto-creates the bucket (MINIO_BUCKET) on startup, so nothing else
# is needed here. Console: http://localhost:9001  S3 API: http://localhost:9000
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path "$PSScriptRoot/..").Path
$EnvFile  = Join-Path $RepoRoot 'dev.env'

function Read-Env([string]$Key, [string]$Default) {
    if (Test-Path $EnvFile) {
        $line = Get-Content $EnvFile | Where-Object { $_ -match "^$Key=" } | Select-Object -Last 1
        if ($line) {
            $val = ($line -split '=', 2)[1].Trim()
            if ($val) { return $val }
        }
    }
    return $Default
}

$User = Read-Env 'MINIO_ACCESS_KEY' 'minio'
$Pass = Read-Env 'MINIO_SECRET_KEY' 'minio123'
$Name = 'atlas-minio'

if ($Pass.Length -lt 8) {
    Write-Error "MINIO_SECRET_KEY must be at least 8 characters (got $($Pass.Length))."
}

$existing = docker ps -a --format '{{.Names}}' | Where-Object { $_ -eq $Name }
if ($existing) {
    Write-Host "Container '$Name' exists - starting it..."
    docker start $Name | Out-Null
} else {
    Write-Host "Creating container '$Name' (user: $User)..."
    docker run -d --name $Name `
        -p 9000:9000 -p 9001:9001 `
        -e MINIO_ROOT_USER=$User `
        -e MINIO_ROOT_PASSWORD=$Pass `
        -v atlas_minio_data:/data `
        minio/minio server /data --console-address ":9001" | Out-Null
}

Write-Host "MinIO is up:"
Write-Host "  S3 API : http://localhost:9000"
Write-Host "  Console: http://localhost:9001  (user: $User)"
Write-Host "Stop with:  docker stop $Name"
