#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 2: Extract and install uv and uvx into $HOME\.local\uv\bin
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$InstallDir = Join-Path $HOME '.local\uv'
$BinDir = Join-Path $InstallDir 'bin'
$UvExe = Join-Path $BinDir 'uv.exe'
$UvxExe = Join-Path $BinDir 'uvx.exe'
$DownloadDir = Join-Path $HOME 'Downloads\uv'
$MetadataFile = Join-Path $DownloadDir 'release-info.json'

if (-not (Test-Path -LiteralPath $MetadataFile -PathType Leaf)) {
    throw "Metadata file missing at '$MetadataFile'. Run 01-download-uv.ps1 first."
}

$Metadata = Get-Content -LiteralPath $MetadataFile -Raw | ConvertFrom-Json
$ZipPath = $Metadata.archive_path

if (-not (Test-Path -LiteralPath $ZipPath -PathType Leaf)) {
    throw "Archive not found at '$ZipPath'. Re-run 01-download-uv.ps1."
}

Write-Step "Checking destination directory: $InstallDir"
if (Test-Path -LiteralPath $UvExe -PathType Leaf) {
    if (-not $Force) {
        Write-Host "uv is already installed at $UvExe." -ForegroundColor Green
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

Write-Step "Extracting uv archive: $ZipPath"
Expand-Archive -LiteralPath $ZipPath -DestinationPath $TempExtractDir -Force

$ExtractedUv = Get-ChildItem -LiteralPath $TempExtractDir -Filter 'uv.exe' -Recurse | Select-Object -First 1
$ExtractedUvx = Get-ChildItem -LiteralPath $TempExtractDir -Filter 'uvx.exe' -Recurse | Select-Object -First 1

if (-not $ExtractedUv) {
    throw "uv.exe not found in extracted archive: $TempExtractDir"
}

Copy-Item -LiteralPath $ExtractedUv.FullName -Destination $UvExe -Force
if ($ExtractedUvx) {
    Copy-Item -LiteralPath $ExtractedUvx.FullName -Destination $UvxExe -Force
}

Remove-Item -LiteralPath $TempExtractDir -Recurse -Force

if (-not (Test-Path -LiteralPath $UvExe -PathType Leaf)) {
    throw "uv binary missing after installation: $UvExe"
}

Write-Host "✓ uv installed successfully to: $UvExe" -ForegroundColor Green
