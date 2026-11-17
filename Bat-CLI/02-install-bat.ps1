#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 2: Extract and install bat into $HOME\.local\bat\bin
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$InstallDir = Join-Path $HOME '.local\bat'
$BinDir = Join-Path $InstallDir 'bin'
$BatExe = Join-Path $BinDir 'bat.exe'
$DownloadDir = Join-Path $HOME 'Downloads\bat'
$MetadataFile = Join-Path $DownloadDir 'release-info.json'

if (-not (Test-Path -LiteralPath $MetadataFile -PathType Leaf)) {
    throw "Metadata file missing at '$MetadataFile'. Run 01-download-bat.ps1 first."
}

$Metadata = Get-Content -LiteralPath $MetadataFile -Raw | ConvertFrom-Json
$ZipPath = $Metadata.archive_path

if (-not (Test-Path -LiteralPath $ZipPath -PathType Leaf)) {
    throw "Archive not found at '$ZipPath'. Re-run 01-download-bat.ps1."
}

Write-Step "Checking destination directory: $InstallDir"
if (Test-Path -LiteralPath $BatExe -PathType Leaf) {
    if (-not $Force) {
        Write-Host "bat is already installed at $BatExe." -ForegroundColor Green
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

Write-Step "Extracting bat archive: $ZipPath"
Expand-Archive -LiteralPath $ZipPath -DestinationPath $TempExtractDir -Force

$ExtractedBat = Get-ChildItem -LiteralPath $TempExtractDir -Filter 'bat.exe' -Recurse | Select-Object -First 1
if (-not $ExtractedBat) {
    throw "bat.exe not found in extracted archive: $TempExtractDir"
}

Copy-Item -LiteralPath $ExtractedBat.FullName -Destination $BatExe -Force
Remove-Item -LiteralPath $TempExtractDir -Recurse -Force

if (-not (Test-Path -LiteralPath $BatExe -PathType Leaf)) {
    throw "bat binary missing after installation: $BatExe"
}

Write-Host "✓ bat installed successfully to: $BatExe" -ForegroundColor Green
