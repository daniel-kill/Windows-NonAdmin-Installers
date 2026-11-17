#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 3: Configure User Environment & PATH for Scoop
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$InstallDir = if ($env:SCOOP) { $env:SCOOP } else { Join-Path $HOME 'scoop' }
$ShimDir = Join-Path $InstallDir 'shims'
$ScoopShimPs1 = Join-Path $ShimDir 'scoop.ps1'

if (-not (Test-Path -LiteralPath $ScoopShimPs1 -PathType Leaf)) {
    throw "Scoop executable shim not found at: $ScoopShimPs1"
}

Write-Step "Configuring User Environment variable SCOOP"
[Environment]::SetEnvironmentVariable('SCOOP', $InstallDir, [EnvironmentVariableTarget]::User)
$env:SCOOP = $InstallDir
Write-Host "Set User Environment Variable: SCOOP = $InstallDir" -ForegroundColor Green

Write-Step "Configuring User PATH environment"
$BackupDir = Join-Path $InstallDir 'environment-backups'
if (-not (Test-Path -LiteralPath $BackupDir -PathType Container)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}

$CurrentPath = [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::User)
if ($null -eq $CurrentPath) { $CurrentPath = '' }

$Timestamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$BackupFile = Join-Path $BackupDir "path-backup-$Timestamp.txt"
$CurrentPath | Set-Content -LiteralPath $BackupFile -Encoding utf8
Write-Host "Current User PATH backed up to: $BackupFile" -ForegroundColor DarkGray

$PathParts = $CurrentPath -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
if ($PathParts -notcontains $ShimDir) {
    $NewPath = ($PathParts + $ShimDir) -join ';'
    [Environment]::SetEnvironmentVariable('Path', $NewPath, [EnvironmentVariableTarget]::User)
    Write-Host "Added to User PATH: $ShimDir" -ForegroundColor Green
}
else {
    Write-Host "Shim directory is already present in User PATH: $ShimDir" -ForegroundColor Yellow
}

$env:Path = "$ShimDir;$env:Path"

Write-Step "Validating Scoop execution"
$ScoopHelp = & $ScoopShimPs1 --help | Select-Object -First 3
Write-Host ($ScoopHelp -join "`n") -ForegroundColor Green
Write-Host "✓ Scoop non-admin environment verified successfully." -ForegroundColor Green
