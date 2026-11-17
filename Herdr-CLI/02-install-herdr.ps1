#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 2: Extract and install Herdr core runtime into $HOME\.local\herdr\bin
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
$DownloadDir = Join-Path $HOME 'Downloads\herdr'
$MetadataFile = Join-Path $DownloadDir 'release-info.json'

if (-not (Test-Path -LiteralPath $MetadataFile -PathType Leaf)) {
    throw "Metadata file missing at '$MetadataFile'. Run 01-download-herdr.ps1 first."
}

$Metadata = Get-Content -LiteralPath $MetadataFile -Raw | ConvertFrom-Json
$ZipPath = $Metadata.archive_path

if (-not (Test-Path -LiteralPath $ZipPath -PathType Leaf)) {
    throw "Archive not found at '$ZipPath'. Re-run 01-download-herdr.ps1."
}

Write-Step "Checking destination directory: $InstallDir"
if (Test-Path -LiteralPath $HerdrExe -PathType Leaf) {
    if (-not $Force) {
        Write-Host "Herdr is already installed at $HerdrExe." -ForegroundColor Green
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

Write-Step "Extracting Herdr archive: $ZipPath"
Expand-Archive -LiteralPath $ZipPath -DestinationPath $TempExtractDir -Force

$ExtractedHerdr = Get-ChildItem -LiteralPath $TempExtractDir -Filter 'herdr-core.exe' -Recurse | Select-Object -First 1
if (-not $ExtractedHerdr) {
    throw "herdr-core.exe not found in extracted archive: $TempExtractDir"
}

$SourceRoot = $ExtractedHerdr.DirectoryName

Copy-Item -LiteralPath (Join-Path $SourceRoot 'herdr-core.exe') -Destination $HerdrExe -Force
Copy-Item -LiteralPath (Join-Path $SourceRoot 'herdr-core.exe') -Destination $HcExe -Force

$ConptyDir = Join-Path $SourceRoot 'conpty'
if (Test-Path -LiteralPath $ConptyDir -PathType Container) {
    Copy-Item -LiteralPath $ConptyDir -Destination $BinDir -Recurse -Force
}

Remove-Item -LiteralPath $TempExtractDir -Recurse -Force

if (-not (Test-Path -LiteralPath $HerdrExe -PathType Leaf)) {
    throw "Herdr binary missing after installation: $HerdrExe"
}

Write-Host "✓ Herdr core & hc installed successfully to: $BinDir" -ForegroundColor Green
