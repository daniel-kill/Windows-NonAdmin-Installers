#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 2: Extract and install delta into $HOME\.local\delta\bin
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$InstallDir = Join-Path $HOME '.local\delta'
$BinDir = Join-Path $InstallDir 'bin'
$DeltaExe = Join-Path $BinDir 'delta.exe'
$DownloadDir = Join-Path $HOME 'Downloads\delta'
$MetadataFile = Join-Path $DownloadDir 'release-info.json'

if (-not (Test-Path -LiteralPath $MetadataFile -PathType Leaf)) {
    throw "Metadata file missing at '$MetadataFile'. Run 01-download-delta.ps1 first."
}

$Metadata = Get-Content -LiteralPath $MetadataFile -Raw | ConvertFrom-Json
$ZipPath = $Metadata.archive_path

if (-not (Test-Path -LiteralPath $ZipPath -PathType Leaf)) {
    throw "Archive not found at '$ZipPath'. Re-run 01-download-delta.ps1."
}

Write-Step "Checking destination directory: $InstallDir"
if (Test-Path -LiteralPath $DeltaExe -PathType Leaf) {
    if (-not $Force) {
        Write-Host "delta is already installed at $DeltaExe." -ForegroundColor Green
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

Write-Step "Extracting delta archive: $ZipPath"
Expand-Archive -LiteralPath $ZipPath -DestinationPath $TempExtractDir -Force

$ExtractedDelta = Get-ChildItem -LiteralPath $TempExtractDir -Filter 'delta.exe' -Recurse | Select-Object -First 1
if (-not $ExtractedDelta) {
    throw "delta.exe not found in extracted archive: $TempExtractDir"
}

Copy-Item -LiteralPath $ExtractedDelta.FullName -Destination $DeltaExe -Force
Remove-Item -LiteralPath $TempExtractDir -Recurse -Force

if (-not (Test-Path -LiteralPath $DeltaExe -PathType Leaf)) {
    throw "delta binary missing after installation: $DeltaExe"
}

Write-Host "✓ delta installed successfully to: $DeltaExe" -ForegroundColor Green
