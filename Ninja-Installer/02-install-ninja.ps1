#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 2: Extract and install Ninja binary into $HOME\.local\ninja\bin
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$InstallDir = Join-Path $HOME '.local\ninja'
$BinDir = Join-Path $InstallDir 'bin'
$NinjaExe = Join-Path $BinDir 'ninja.exe'
$DownloadDir = Join-Path $HOME 'Downloads\ninja'
$MetadataFile = Join-Path $DownloadDir 'release-info.json'

if (-not (Test-Path -LiteralPath $MetadataFile -PathType Leaf)) {
    throw "Metadata file missing at '$MetadataFile'. Run 01-download-ninja.ps1 first."
}

$Metadata = Get-Content -LiteralPath $MetadataFile -Raw | ConvertFrom-Json
$ZipPath = $Metadata.archive_path

if (-not (Test-Path -LiteralPath $ZipPath -PathType Leaf)) {
    throw "Archive not found at '$ZipPath'. Re-run 01-download-ninja.ps1."
}

Write-Step "Checking destination directory: $InstallDir"
if (Test-Path -LiteralPath $NinjaExe -PathType Leaf) {
    if (-not $Force) {
        Write-Host "Ninja is already installed at $NinjaExe." -ForegroundColor Green
        Write-Host "Use -Force to reinstall." -ForegroundColor Yellow
        exit 0
    }
    Write-Host "Force reinstall requested. Cleaning up existing installation..." -ForegroundColor Yellow
    Remove-Item -LiteralPath $InstallDir -Recurse -Force
}

New-Item -ItemType Directory -Path $BinDir -Force | Out-Null

$TempExtractDir = Join-Path $DownloadDir "temp_extract_$PID"
if (Test-Path -LiteralPath $TempExtractDir) {
    Remove-Item -LiteralPath $TempExtractDir -Recurse -Force
}
New-Item -ItemType Directory -Path $TempExtractDir -Force | Out-Null

Write-Step "Extracting Ninja archive: $ZipPath"
Expand-Archive -LiteralPath $ZipPath -DestinationPath $TempExtractDir -Force

$ExtractedExe = Join-Path $TempExtractDir 'ninja.exe'
if (-not (Test-Path -LiteralPath $ExtractedExe -PathType Leaf)) {
    throw "ninja.exe not found in extracted archive: $TempExtractDir"
}

Copy-Item -LiteralPath $ExtractedExe -Destination $NinjaExe -Force
Remove-Item -LiteralPath $TempExtractDir -Recurse -Force

if (-not (Test-Path -LiteralPath $NinjaExe -PathType Leaf)) {
    throw "Ninja binary missing after installation: $NinjaExe"
}

Write-Host "✓ Ninja installed successfully to: $NinjaExe" -ForegroundColor Green
