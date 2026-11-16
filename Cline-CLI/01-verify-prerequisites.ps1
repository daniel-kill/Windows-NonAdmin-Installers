#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 1: Verify Node.js and NPM prerequisites for Cline CLI
#
# Cline CLI requires Node.js (v20+ recommended) and npm.
# Checks for:
#   1. Local non-admin Node.js at $HOME\.local\node
#   2. System Node.js in PATH
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

Write-Step 'Checking Node.js & NPM prerequisites'

$LocalNodeDir = Join-Path $HOME '.local\node'
$LocalNodeExe = Join-Path $LocalNodeDir 'node.exe'
$LocalNpmCmd  = Join-Path $LocalNodeDir 'npm.cmd'

$NpmCmd = $null

if (Test-Path -LiteralPath $LocalNpmCmd -PathType Leaf) {
    Write-Host "Found local non-admin Node.js at: $LocalNodeDir" -ForegroundColor Green
    $NpmCmd = $LocalNpmCmd
}
else {
    $SysNpm = Get-Command npm.cmd -ErrorAction SilentlyContinue
    if (-not $SysNpm) {
        $SysNpm = Get-Command npm -ErrorAction SilentlyContinue
    }
    if ($SysNpm) {
        Write-Host "Found system NPM at: $($SysNpm.Source)" -ForegroundColor Green
        $NpmCmd = $SysNpm.Source
    }
}

if (-not $NpmCmd) {
    throw @"
Node.js and npm were not found on this system.
Cline CLI requires Node.js.

Please install the non-admin Node.js toolchain first:
  cd ..\Node-Installer
  .\install-node.ps1

Then rerun this script.
"@
}

$NpmVersion = & $NpmCmd --version
Write-Host "NPM Version: $NpmVersion" -ForegroundColor Green

# Save metadata for Step 2
$DownloadDir = Join-Path $HOME 'Downloads\Cline'
if (-not (Test-Path -LiteralPath $DownloadDir)) {
    New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
}

$Metadata = [pscustomobject]@{
    NpmCommand = $NpmCmd
    CheckedAt  = (Get-Date -Format 'o')
}
$Metadata | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $DownloadDir 'prereq-info.json') -Encoding utf8NoBOM

Write-Host
Write-Host "Node.js and npm prerequisites verified." -ForegroundColor Green
