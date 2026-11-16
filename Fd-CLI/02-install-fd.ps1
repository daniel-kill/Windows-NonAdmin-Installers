#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 2: Extract and install fd under $HOME\.local\fd
#
# Parameters:
#   -Force: Remove any existing installation at $HOME\.local\fd and reinstall.
#
# This script:
#   1. Locates downloaded archive and re-verifies its SHA-256 checksum.
#   2. Extracts the archive into temporary staging.
#   3. Installs fd.exe into $HOME\.local\fd\bin\fd.exe.
#   4. Verifies executable execution (fd.exe --version).
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$DownloadDir = Join-Path $HOME 'Downloads\fd'
$InstallRoot = Join-Path $HOME '.local\fd'
$BinDir = Join-Path $InstallRoot 'bin'
$FdExe = Join-Path $BinDir 'fd.exe'

Write-Step 'Locating downloaded fd archive'
$MetadataFile = Join-Path $DownloadDir 'release-info.json'
if (-not (Test-Path -LiteralPath $MetadataFile -PathType Leaf)) {
    throw "Release metadata missing: $MetadataFile. Run 01-download-fd.ps1 first."
}

$Metadata = Get-Content -LiteralPath $MetadataFile -Raw | ConvertFrom-Json
$ArchivePath = Join-Path $DownloadDir $Metadata.FileName
if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf)) {
    throw "Archive missing: $ArchivePath. Run 01-download-fd.ps1 first."
}

Write-Host "Archive found: $ArchivePath"

Write-Step 'Re-verifying archive SHA-256 hash'
$ActualHash = (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash.ToLowerInvariant()
if ($ActualHash -ne $Metadata.Sha256.ToLowerInvariant()) {
    throw "Archive SHA-256 mismatch! Expected $($Metadata.Sha256), got $ActualHash"
}
Write-Host "SHA-256 verification passed: $ActualHash" -ForegroundColor Green

Write-Step 'Checking target installation directory'
if (Test-Path -LiteralPath $InstallRoot) {
    if ($Force) {
        Write-Warning "Removing existing installation at: $InstallRoot"
        Remove-Item -LiteralPath $InstallRoot -Recurse -Force
    }
    else {
        throw "fd is already installed at $InstallRoot. Use -Force to reinstall."
    }
}

New-Item -ItemType Directory -Path $BinDir -Force | Out-Null

Write-Step 'Extracting fd archive'
$TempExtract = Join-Path $env:TEMP ("fd-extract-" + [guid]::NewGuid().ToString('N'))
try {
    Expand-Archive -LiteralPath $ArchivePath -DestinationPath $TempExtract -Force
    $ExtractedFd = Get-ChildItem -LiteralPath $TempExtract -Recurse -Filter 'fd.exe' | Select-Object -First 1
    if (-not $ExtractedFd) {
        throw "Could not find fd.exe in extracted archive."
    }

    Copy-Item -LiteralPath $ExtractedFd.FullName -Destination $FdExe -Force
}
finally {
    if (Test-Path -LiteralPath $TempExtract) {
        Remove-Item -LiteralPath $TempExtract -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if (-not (Test-Path -LiteralPath $FdExe -PathType Leaf)) {
    throw "Failed to install fd.exe to: $FdExe"
}

$VersionOutput = & $FdExe --version | Select-Object -First 1
Write-Host "Execution Test: $VersionOutput" -ForegroundColor Green

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 2 COMPLETE: fd Installed' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Binary:  $FdExe"
Write-Host "Version: $VersionOutput"
Write-Host
Write-Host 'The Windows PATH has not been modified yet. Run Step 3 to configure environment.'
