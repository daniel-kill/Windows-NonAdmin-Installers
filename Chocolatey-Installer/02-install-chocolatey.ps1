#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 2: Extract and install Chocolatey into user-local directory
#
# Target: $HOME\.local\chocolatey
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$InstallDir = if ($env:ChocolateyInstall) { $env:ChocolateyInstall } else { Join-Path $HOME '.local\chocolatey' }
$BinDir = Join-Path $InstallDir 'bin'
$ChocoExe = Join-Path $BinDir 'choco.exe'
$DownloadDir = Join-Path $HOME 'Downloads\chocolatey'
$MetadataFile = Join-Path $DownloadDir 'release-info.json'

if (-not (Test-Path -LiteralPath $MetadataFile -PathType Leaf)) {
    throw "Metadata file missing at '$MetadataFile'. Run 01-download-chocolatey.ps1 first."
}

$Metadata = Get-Content -LiteralPath $MetadataFile -Raw | ConvertFrom-Json
$NupkgPath = $Metadata.archive_path

if (-not (Test-Path -LiteralPath $NupkgPath -PathType Leaf)) {
    throw "Archive not found at '$NupkgPath'. Re-run 01-download-chocolatey.ps1."
}

Write-Step "Checking destination directory: $InstallDir"
if (Test-Path -LiteralPath $ChocoExe -PathType Leaf) {
    if (-not $Force) {
        Write-Host "Chocolatey is already installed at $ChocoExe." -ForegroundColor Green
        Write-Host "Use -Force to reinstall." -ForegroundColor Yellow
        exit 0
    }
    Write-Host "Force reinstall requested. Cleaning up existing installation..." -ForegroundColor Yellow
    Remove-Item -LiteralPath $InstallDir -Recurse -Force
}

New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $InstallDir 'helpers') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $InstallDir 'lib') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $InstallDir 'tools') -Force | Out-Null

$TempExtractDir = Join-Path $DownloadDir "temp_extract_$PID"
if (Test-Path -LiteralPath $TempExtractDir) {
    Remove-Item -LiteralPath $TempExtractDir -Recurse -Force
}
New-Item -ItemType Directory -Path $TempExtractDir -Force | Out-Null

Write-Step "Extracting Chocolatey package: $NupkgPath"
$SevenZipExe = Join-Path $HOME '.local\7zip\7z.exe'

if (Test-Path -LiteralPath $SevenZipExe -PathType Leaf) {
    Write-Host "Extracting via local 7z: $SevenZipExe"
    & $SevenZipExe x $NupkgPath "-o$TempExtractDir" -y | Out-Null
}
elseif (Get-Command 'tar' -ErrorAction SilentlyContinue) {
    Write-Host "Extracting via native tar..."
    tar -xf $NupkgPath -C $TempExtractDir
}
else {
    Write-Host "Extracting via .NET ZipFile..."
    [System.IO.Compression.ZipFile]::ExtractToDirectory($NupkgPath, $TempExtractDir)
}

$ToolsFolder = Join-Path $TempExtractDir 'tools'
$ChocoInstallFolder = Join-Path $ToolsFolder 'chocolateyInstall'

if (-not (Test-Path -LiteralPath $ChocoInstallFolder)) {
    throw "chocolateyInstall directory missing in extracted package: $ChocoInstallFolder"
}

Write-Step "Deploying Chocolatey engine and core binaries to $InstallDir"
# Copy core tools and binaries
Copy-Item -Path (Join-Path $ChocoInstallFolder '*') -Destination $BinDir -Recurse -Force

# Setup helpers
if (Test-Path -LiteralPath (Join-Path $ChocoInstallFolder 'helpers')) {
    Copy-Item -Path (Join-Path $ChocoInstallFolder 'helpers\*') -Destination (Join-Path $InstallDir 'helpers') -Recurse -Force
}

# Preserve nupkg in lib folder
$LibChoco = Join-Path $InstallDir 'lib\chocolatey'
New-Item -ItemType Directory -Path $LibChoco -Force | Out-Null
Copy-Item -LiteralPath $NupkgPath -Destination (Join-Path $LibChoco 'chocolatey.nupkg') -Force

Remove-Item -LiteralPath $TempExtractDir -Recurse -Force

if (-not (Test-Path -LiteralPath $ChocoExe -PathType Leaf)) {
    throw "Chocolatey executable not found after extraction: $ChocoExe"
}

Write-Host "✓ Chocolatey engine deployed successfully to: $ChocoExe" -ForegroundColor Green
