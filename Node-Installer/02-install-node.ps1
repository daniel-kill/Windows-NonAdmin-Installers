#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 2: Extract and install Node.js standalone toolchain under $HOME\.local\node
#
# Parameters:
#   -Force: Remove any existing Node.js installation at $HOME\.local\node and reinstall.
#
# This script:
#   1. Locates the downloaded Node.js archive and re-verifies its SHA-256 hash.
#   2. Validates safety constraints.
#   3. Extracts the archive into $HOME\.local\node without administrator privileges.
#   4. Verifies node.exe, npm.cmd, and npx.cmd binaries.
#
# This script DOES NOT:
#   - Require administrator privileges.
#   - Modify persistent PATH or environment variables.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

$DownloadDir = Join-Path $HOME 'Downloads\Node'
$InstallParent = Join-Path $HOME '.local'
$InstallRoot = Join-Path $InstallParent 'node'

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

function Write-Step {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

# -----------------------------------------------------------------------------
# Locate and verify downloaded archive
# -----------------------------------------------------------------------------

Write-Step 'Locating downloaded Node.js archive'

if (-not (Test-Path -LiteralPath $DownloadDir -PathType Container)) {
    throw "Node download directory does not exist: $DownloadDir. Run 01-download-node.ps1 first."
}

$MetadataFile = Join-Path $DownloadDir 'release-info.json'
if (-not (Test-Path -LiteralPath $MetadataFile -PathType Leaf)) {
    throw "Release metadata missing: $MetadataFile. Run 01-download-node.ps1 first."
}

$Metadata = Get-Content -LiteralPath $MetadataFile -Raw | ConvertFrom-Json
$ArchivePath = Join-Path $DownloadDir $Metadata.FileName

if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf)) {
    throw "Archive file missing: $ArchivePath. Run 01-download-node.ps1 first."
}

Write-Host "Archive found: $ArchivePath"
Write-Host "Version:       $($Metadata.Version)"

# Re-verify SHA-256
Write-Step 'Re-verifying archive SHA-256 hash'

$ActualHash = (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash.ToLowerInvariant()
$ExpectedHash = $Metadata.Sha256.ToLowerInvariant()

if ($ActualHash -ne $ExpectedHash) {
    throw "Archive SHA-256 verification failed! Expected $ExpectedHash, got $ActualHash"
}

Write-Host "SHA-256 verification passed: $ActualHash" -ForegroundColor Green

# -----------------------------------------------------------------------------
# Validate destination directory
# -----------------------------------------------------------------------------

Write-Step 'Checking target installation directory'

if (Test-Path -LiteralPath $InstallRoot) {
    if ($Force) {
        Write-Warning "Removing existing Node.js installation at: $InstallRoot"
        Remove-Item -LiteralPath $InstallRoot -Recurse -Force
    }
    else {
        throw "Node.js is already installed at $InstallRoot. Use -Force to remove and reinstall."
    }
}

if (-not (Test-Path -LiteralPath $InstallParent -PathType Container)) {
    New-Item -ItemType Directory -Path $InstallParent -Force | Out-Null
}

# -----------------------------------------------------------------------------
# Extract archive
# -----------------------------------------------------------------------------

Write-Step 'Extracting Node.js distribution archive'

$TempExtract = Join-Path $env:TEMP ("node-extract-" + [guid]::NewGuid().ToString('N'))

try {
    Write-Host "Extracting to staging: $TempExtract"
    Expand-Archive -LiteralPath $ArchivePath -DestinationPath $TempExtract -Force

    # Node archive contains top-level folder like 'node-v20.x.x-win-x64'
    $NodeFolders = Get-ChildItem -LiteralPath $TempExtract -Directory -Filter 'node-*-win-x64'
    if (-not $NodeFolders or $NodeFolders.Count -eq 0) {
        throw "Extraction did not produce expected 'node-*-win-x64' folder in: $TempExtract"
    }

    $ExtractedNodeDir = $NodeFolders[0].FullName
    Write-Host "Moving extracted Node.js folder to: $InstallRoot"
    Move-Item -LiteralPath $ExtractedNodeDir -Destination $InstallRoot -Force
}
finally {
    if (Test-Path -LiteralPath $TempExtract) {
        Remove-Item -LiteralPath $TempExtract -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# -----------------------------------------------------------------------------
# Verify installed binaries
# -----------------------------------------------------------------------------

Write-Step 'Verifying installed binaries'

$NodeExe = Join-Path $InstallRoot 'node.exe'
$NpmCmd = Join-Path $InstallRoot 'npm.cmd'
$NpxCmd = Join-Path $InstallRoot 'npx.cmd'

if (-not (Test-Path -LiteralPath $NodeExe -PathType Leaf)) {
    throw "Missing binary: $NodeExe"
}

if (-not (Test-Path -LiteralPath $NpmCmd -PathType Leaf)) {
    throw "Missing script: $NpmCmd"
}

if (-not (Test-Path -LiteralPath $NpxCmd -PathType Leaf)) {
    throw "Missing script: $NpxCmd"
}

Write-Host "Found node.exe: $NodeExe"
Write-Host "Found npm.cmd:  $NpmCmd"
Write-Host "Found npx.cmd:  $NpxCmd"

$NodeVersionOutput = & $NodeExe --version
Write-Host "Node version: $NodeVersionOutput" -ForegroundColor Green

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 2 COMPLETE: Node.js Toolchain Installed' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Installation path: $InstallRoot"
Write-Host "Version:           $NodeVersionOutput"
Write-Host
Write-Host 'The Windows PATH has not been modified yet. Run Step 3 to configure environment.'
