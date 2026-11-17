#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 2: Install cloudflared binary into $HOME\.local\cloudflared\bin
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$InstallDir = Join-Path $HOME '.local\cloudflared'
$BinDir = Join-Path $InstallDir 'bin'
$TargetExe = Join-Path $BinDir 'cloudflared.exe'
$DownloadDir = Join-Path $HOME 'Downloads\cloudflared'
$MetadataFile = Join-Path $DownloadDir 'release-info.json'

if (-not (Test-Path -LiteralPath $MetadataFile -PathType Leaf)) {
    throw "Metadata file missing at '$MetadataFile'. Run 01-download-cloudflared.ps1 first."
}

$Metadata = Get-Content -LiteralPath $MetadataFile -Raw | ConvertFrom-Json
$SourceExe = $Metadata.binary_path

if (-not (Test-Path -LiteralPath $SourceExe -PathType Leaf)) {
    throw "Binary not found at '$SourceExe'. Re-run 01-download-cloudflared.ps1."
}

Write-Step "Checking destination directory: $InstallDir"
if (Test-Path -LiteralPath $TargetExe -PathType Leaf) {
    if (-not $Force) {
        Write-Host "cloudflared is already installed at $TargetExe." -ForegroundColor Green
        Write-Host "Use -Force to reinstall." -ForegroundColor Yellow
        exit 0
    }
    Write-Host "Force reinstall requested. Cleaning up existing installation..." -ForegroundColor Yellow
    Remove-Item -LiteralPath $InstallDir -Recurse -Force
}

New-Item -ItemType Directory -Path $BinDir -Force | Out-Null

Write-Step "Installing cloudflared binary to $TargetExe"
Copy-Item -LiteralPath $SourceExe -Destination $TargetExe -Force

if (-not (Test-Path -LiteralPath $TargetExe -PathType Leaf)) {
    throw "cloudflared binary missing after installation: $TargetExe"
}

Write-Host "✓ cloudflared installed successfully to: $TargetExe" -ForegroundColor Green
