#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 3: Configure User PATH and verify Herdr execution (hc & herdr-core)
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$InstallDir = Join-Path $HOME '.local\herdr'
$BinDir = Join-Path $InstallDir 'bin'
$HerdrExe = Join-Path $BinDir 'herdr-core.exe'
$HcExe = Join-Path $BinDir 'hc.exe'

if (-not (Test-Path -LiteralPath $HerdrExe -PathType Leaf)) {
    throw "Herdr binary not found at: $HerdrExe"
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

Write-Step "Validating Herdr execution"
$HcVer = & $HcExe --version
Write-Host "hc Version:         $HcVer" -ForegroundColor Green

$HerdrVer = & $HerdrExe --version
Write-Host "herdr-core Version: $HerdrVer" -ForegroundColor Green

Write-Host "✓ Herdr environment verified successfully." -ForegroundColor Green
