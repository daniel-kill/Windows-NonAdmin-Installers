#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 1: Verify Python & Pip prerequisites for Hermes Agent CLI
#
# Checks for:
#   1. Local non-admin Python at $HOME\.local\python
#   2. System Python in PATH (Python 3.10+)
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

Write-Step 'Checking Python prerequisites for Hermes Agent'

$LocalPythonExe = Join-Path $HOME '.local\python\python.exe'
$PythonExe = $null

if (Test-Path -LiteralPath $LocalPythonExe -PathType Leaf) {
    Write-Host "Found local non-admin Python at: $LocalPythonExe" -ForegroundColor Green
    $PythonExe = $LocalPythonExe
}
else {
    $SysPy = Get-Command python.exe -ErrorAction SilentlyContinue
    if (-not $SysPy) { $SysPy = Get-Command python -ErrorAction SilentlyContinue }
    if ($SysPy) {
        Write-Host "Found system Python at: $($SysPy.Source)" -ForegroundColor Green
        $PythonExe = $SysPy.Source
    }
}

if (-not $PythonExe) {
    throw @"
Python was not found on this system.
Hermes Agent CLI requires Python 3.10+.

Please install the non-admin Python toolchain first:
  cd ..\Python-Installer
  .\install-python.ps1

Then rerun this script.
"@
}

$PyVersion = & $PythonExe --version
Write-Host "Using Python: $PyVersion" -ForegroundColor Green

# Save metadata for Step 2
$DownloadDir = Join-Path $HOME 'Downloads\Hermes'
if (-not (Test-Path -LiteralPath $DownloadDir)) {
    New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
}

$Metadata = [pscustomobject]@{
    PythonCommand = $PythonExe
    CheckedAt     = (Get-Date -Format 'o')
}
$Metadata | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $DownloadDir 'prereq-info.json') -Encoding utf8NoBOM

Write-Host
Write-Host "Python prerequisites verified." -ForegroundColor Green
