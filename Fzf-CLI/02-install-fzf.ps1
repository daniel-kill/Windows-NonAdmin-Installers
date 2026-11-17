#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 2: Extract and install fzf into $HOME\.local\fzf\bin
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$InstallDir = Join-Path $HOME '.local\fzf'
$BinDir = Join-Path $InstallDir 'bin'
$FzfExe = Join-Path $BinDir 'fzf.exe'
$DownloadDir = Join-Path $HOME 'Downloads\fzf'
$MetadataFile = Join-Path $DownloadDir 'release-info.json'

if (-not (Test-Path -LiteralPath $MetadataFile -PathType Leaf)) {
    throw "Metadata file missing at '$MetadataFile'. Run 01-download-fzf.ps1 first."
}

$Metadata = Get-Content -LiteralPath $MetadataFile -Raw | ConvertFrom-Json
$ZipPath = $Metadata.archive_path

if (-not (Test-Path -LiteralPath $ZipPath -PathType Leaf)) {
    throw "Archive not found at '$ZipPath'. Re-run 01-download-fzf.ps1."
}

Write-Step "Checking destination directory: $InstallDir"
if (Test-Path -LiteralPath $FzfExe -PathType Leaf) {
    if (-not $Force) {
        Write-Host "fzf is already installed at $FzfExe." -ForegroundColor Green
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

Write-Step "Extracting fzf archive: $ZipPath"
Expand-Archive -LiteralPath $ZipPath -DestinationPath $TempExtractDir -Force

$ExtractedFzf = Get-ChildItem -LiteralPath $TempExtractDir -Filter 'fzf.exe' -Recurse | Select-Object -First 1
if (-not $ExtractedFzf) {
    throw "fzf.exe not found in extracted archive: $TempExtractDir"
}

Copy-Item -LiteralPath $ExtractedFzf.FullName -Destination $FzfExe -Force
Remove-Item -LiteralPath $TempExtractDir -Recurse -Force

if (-not (Test-Path -LiteralPath $FzfExe -PathType Leaf)) {
    throw "fzf binary missing after installation: $FzfExe"
}

Write-Host "✓ fzf installed successfully to: $FzfExe" -ForegroundColor Green
