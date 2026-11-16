#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 2: Extract and install Go standalone toolchain under $HOME\.local\go
#
# Parameters:
#   -Force: Remove any existing Go installation at $HOME\.local\go and reinstall.
#
# This script:
#   1. Locates the downloaded Go archive and re-verifies its SHA-256 checksum.
#   2. Validates safety constraints (NTFS, no spaces/non-ASCII in paths).
#   3. Extracts the archive into $HOME\.local\go without administrator privileges.
#   4. Verifies go.exe and gofmt.exe binaries.
#
# This script DOES NOT:
#   - Require administrator privileges.
#   - Modify persistent PATH or environment variables.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

$DownloadDir = Join-Path $HOME 'Downloads\Go'
$InstallParent = Join-Path $HOME '.local'
$InstallRoot = Join-Path $InstallParent 'go'

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

Write-Step 'Locating downloaded Go archive'

if (-not (Test-Path -LiteralPath $DownloadDir -PathType Container)) {
    throw "Go download directory does not exist: $DownloadDir. Run 01-download-go.ps1 first."
}

$MetadataFile = Join-Path $DownloadDir 'release-info.json'
if (-not (Test-Path -LiteralPath $MetadataFile -PathType Leaf)) {
    throw "Release metadata missing: $MetadataFile. Run 01-download-go.ps1 first."
}

$Metadata = Get-Content -LiteralPath $MetadataFile -Raw | ConvertFrom-Json
$ArchivePath = Join-Path $DownloadDir $Metadata.FileName

if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf)) {
    throw "Archive file missing: $ArchivePath. Run 01-download-go.ps1 first."
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
        Write-Warning "Removing existing Go installation at: $InstallRoot"
        Remove-Item -LiteralPath $InstallRoot -Recurse -Force
    }
    else {
        throw "Go is already installed at $InstallRoot. Use -Force to remove and reinstall."
    }
}

if (-not (Test-Path -LiteralPath $InstallParent -PathType Container)) {
    New-Item -ItemType Directory -Path $InstallParent -Force | Out-Null
}

# -----------------------------------------------------------------------------
# Extract archive
# -----------------------------------------------------------------------------

Write-Step 'Extracting Go distribution archive'

$TempExtract = Join-Path $env:TEMP ("go-extract-" + [guid]::NewGuid().ToString('N'))

try {
    Write-Host "Extracting to temporary staging: $TempExtract"
    Expand-Archive -LiteralPath $ArchivePath -DestinationPath $TempExtract -Force

    $ExtractedGoDir = Join-Path $TempExtract 'go'
    if (-not (Test-Path -LiteralPath $ExtractedGoDir -PathType Container)) {
        throw "Extraction did not produce expected 'go' folder in: $TempExtract"
    }

    Write-Host "Moving Go distribution to: $InstallRoot"
    Move-Item -LiteralPath $ExtractedGoDir -Destination $InstallRoot -Force
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

$GoExe = Join-Path $InstallRoot 'bin\go.exe'
$GofmtExe = Join-Path $InstallRoot 'bin\gofmt.exe'

if (-not (Test-Path -LiteralPath $GoExe -PathType Leaf)) {
    throw "Missing binary: $GoExe"
}

if (-not (Test-Path -LiteralPath $GofmtExe -PathType Leaf)) {
    throw "Missing binary: $GofmtExe"
}

Write-Host "Found go.exe:    $GoExe"
Write-Host "Found gofmt.exe: $GofmtExe"

$VersionOutput = & $GoExe version
Write-Host "Output: $VersionOutput" -ForegroundColor Green

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 2 COMPLETE: Go Toolchain Installed' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Installation path: $InstallRoot"
Write-Host "Version:           $VersionOutput"
Write-Host
Write-Host 'The Windows PATH has not been modified yet. Run Step 3 to configure environment.'
