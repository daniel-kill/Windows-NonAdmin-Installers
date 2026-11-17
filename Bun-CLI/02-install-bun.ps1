#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 2: Extract and install Bun into $HOME\.local\bun\bin
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$InstallDir = Join-Path $HOME '.local\bun'
$BinDir = Join-Path $InstallDir 'bin'
$BunExe = Join-Path $BinDir 'bun.exe'
$DownloadDir = Join-Path $HOME 'Downloads\bun'
$MetadataFile = Join-Path $DownloadDir 'release-info.json'

if (-not (Test-Path -LiteralPath $MetadataFile -PathType Leaf)) {
    throw "Metadata file missing at '$MetadataFile'. Run 01-download-bun.ps1 first."
}

$Metadata = Get-Content -LiteralPath $MetadataFile -Raw | ConvertFrom-Json
$ZipPath = $Metadata.archive_path

if (-not (Test-Path -LiteralPath $ZipPath -PathType Leaf)) {
    throw "Archive not found at '$ZipPath'. Re-run 01-download-bun.ps1."
}

Write-Step "Checking destination directory: $InstallDir"
if (Test-Path -LiteralPath $BunExe -PathType Leaf) {
    if (-not $Force) {
        Write-Host "Bun is already installed at $BunExe." -ForegroundColor Green
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

Write-Step "Extracting Bun archive: $ZipPath"
Expand-Archive -LiteralPath $ZipPath -DestinationPath $TempExtractDir -Force

$ExtractedBun = Get-ChildItem -LiteralPath $TempExtractDir -Filter 'bun.exe' -Recurse | Select-Object -First 1
if (-not $ExtractedBun) {
    throw "bun.exe not found in extracted archive: $TempExtractDir"
}

Copy-Item -LiteralPath $ExtractedBun.FullName -Destination $BunExe -Force
Remove-Item -LiteralPath $TempExtractDir -Recurse -Force

if (-not (Test-Path -LiteralPath $BunExe -PathType Leaf)) {
    throw "Bun binary missing after installation: $BunExe"
}

Write-Host "✓ Bun installed successfully to: $BunExe" -ForegroundColor Green
