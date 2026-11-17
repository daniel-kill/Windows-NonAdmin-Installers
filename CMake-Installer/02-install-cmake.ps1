#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 2: Extract and install CMake Portable into $HOME\.local\cmake
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$InstallDir = Join-Path $HOME '.local\cmake'
$DownloadDir = Join-Path $HOME 'Downloads\cmake'
$MetadataFile = Join-Path $DownloadDir 'release-info.json'

if (-not (Test-Path -LiteralPath $MetadataFile -PathType Leaf)) {
    throw "Metadata file missing at '$MetadataFile'. Run 01-download-cmake.ps1 first."
}

$Metadata = Get-Content -LiteralPath $MetadataFile -Raw | ConvertFrom-Json
$ZipPath = $Metadata.archive_path

if (-not (Test-Path -LiteralPath $ZipPath -PathType Leaf)) {
    throw "Archive not found at '$ZipPath'. Re-run 01-download-cmake.ps1."
}

Write-Step "Checking destination directory: $InstallDir"
$CmakeExe = Join-Path $InstallDir 'bin\cmake.exe'

if (Test-Path -LiteralPath $CmakeExe -PathType Leaf) {
    if (-not $Force) {
        Write-Host "CMake is already installed at $CmakeExe." -ForegroundColor Green
        Write-Host "Use -Force to reinstall." -ForegroundColor Yellow
        exit 0
    }
    Write-Host "Force reinstall requested. Cleaning up existing installation..." -ForegroundColor Yellow
    Remove-Item -LiteralPath $InstallDir -Recurse -Force
}

$TempExtractDir = Join-Path $DownloadDir "temp_extract_$PID"
if (Test-Path -LiteralPath $TempExtractDir) {
    Remove-Item -LiteralPath $TempExtractDir -Recurse -Force
}
New-Item -ItemType Directory -Path $TempExtractDir -Force | Out-Null

Write-Step "Extracting CMake archive: $ZipPath"
$SevenZipExe = Join-Path $HOME '.local\7zip\7z.exe'

if (Test-Path -LiteralPath $SevenZipExe -PathType Leaf) {
    Write-Host "Extracting via local 7z: $SevenZipExe"
    & $SevenZipExe x $ZipPath "-o$TempExtractDir" -y | Out-Null
}
else {
    Write-Host "Extracting via Expand-Archive (this may take a minute)..."
    Expand-Archive -LiteralPath $ZipPath -DestinationPath $TempExtractDir -Force
}

$RootFolder = Get-ChildItem -LiteralPath $TempExtractDir -Directory | Select-Object -First 1
if (-not $RootFolder) {
    throw "Failed to find extracted root folder inside $TempExtractDir"
}

Write-Step "Moving CMake files to $InstallDir"
if (-not (Test-Path -LiteralPath $InstallDir -PathType Container)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

Copy-Item -Path (Join-Path $RootFolder.FullName '*') -Destination $InstallDir -Recurse -Force

Remove-Item -LiteralPath $TempExtractDir -Recurse -Force

if (-not (Test-Path -LiteralPath $CmakeExe -PathType Leaf)) {
    throw "CMake executable not found after extraction: $CmakeExe"
}

Write-Host "✓ CMake installed successfully into: $InstallDir" -ForegroundColor Green
