#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 3: Configure User PATH and verify delta execution
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$InstallDir = Join-Path $HOME '.local\delta'
$BinDir = Join-Path $InstallDir 'bin'
$DeltaExe = Join-Path $BinDir 'delta.exe'

if (-not (Test-Path -LiteralPath $DeltaExe -PathType Leaf)) {
    throw "delta binary not found at: $DeltaExe"
}

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
if ($PathParts -notcontains $BinDir) {
    $NewPath = ($PathParts + $BinDir) -join ';'
    [Environment]::SetEnvironmentVariable('Path', $NewPath, [EnvironmentVariableTarget]::User)
    Write-Host "Added to User PATH: $BinDir" -ForegroundColor Green
}
else {
    Write-Host "Bin directory is already present in User PATH: $BinDir" -ForegroundColor Yellow
}

$env:Path = "$BinDir;$env:Path"

Write-Step "Validating delta execution"
$DeltaVer = & $DeltaExe --version
Write-Host "delta Version: $DeltaVer" -ForegroundColor Green

Write-Host "✓ delta environment verified successfully." -ForegroundColor Green
