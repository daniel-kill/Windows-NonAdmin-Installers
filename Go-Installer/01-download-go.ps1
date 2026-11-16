#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 1: Discover, download, and verify the latest stable Go distribution
#
# This script:
#   1. Queries the official Go release index (https://go.dev/dl/?mode=json).
#   2. Identifies the latest stable Windows x86-64 zip archive.
#   3. Downloads the archive into $HOME\Downloads\Go.
#   4. Verifies the SHA-256 digest against the official manifest hash.
#
# This script DOES NOT:
#   - Require administrator privileges.
#   - Extract or install Go.
#   - Modify PATH or environment variables.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

$DownloadDir = Join-Path $HOME 'Downloads\Go'
$ApiUrl = 'https://go.dev/dl/?mode=json'

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
# Prepare download directory
# -----------------------------------------------------------------------------

Write-Step 'Preparing download directory'

if (-not (Test-Path -LiteralPath $DownloadDir -PathType Container)) {
    New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
}

Write-Host "Download directory: $DownloadDir"

# -----------------------------------------------------------------------------
# Query official Go release index
# -----------------------------------------------------------------------------

Write-Step 'Querying official Go release catalog'

Write-Host "API URL: $ApiUrl"
$Releases = Invoke-RestMethod -Uri $ApiUrl -Method Get

if (-not $Releases -or $Releases.Count -eq 0) {
    throw "Failed to retrieve release metadata from $ApiUrl"
}

# Find the newest stable release
$StableRelease = $Releases | Where-Object { $_.stable -eq $true } | Select-Object -First 1

if (-not $StableRelease) {
    $StableRelease = $Releases | Select-Object -First 1
}

$GoVersion = $StableRelease.version
Write-Host "Selected Go release: $GoVersion"

# Find windows amd64 zip
$ArchiveFile = $StableRelease.files | Where-Object {
    $_.os -eq 'windows' -and $_.arch -eq 'amd64' -and $_.filename -like '*.zip'
} | Select-Object -First 1

if (-not $ArchiveFile) {
    throw "No matching windows/amd64 zip package found in release $GoVersion"
}

$FileName = $ArchiveFile.filename
$ExpectedHash = $ArchiveFile.sha256.ToLowerInvariant()
$DownloadUrl = "https://go.dev/dl/$FileName"
$Destination = Join-Path $DownloadDir $FileName
$ChecksumFile = "$Destination.sha256"
$MetadataFile = Join-Path $DownloadDir 'release-info.json'

Write-Host "Archive filename: $FileName"
Write-Host "Expected SHA-256: $ExpectedHash"
Write-Host "Archive size:     $($ArchiveFile.size) bytes"

# -----------------------------------------------------------------------------
# Download archive
# -----------------------------------------------------------------------------

Write-Step 'Downloading Go archive'

if (Test-Path -LiteralPath $Destination -PathType Leaf) {
    $ExistingHash = (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($ExistingHash -eq $ExpectedHash) {
        Write-Host "Existing archive is already downloaded and verified: $Destination" -ForegroundColor Green
    }
    else {
        Write-Host "Existing archive hash mismatch. Re-downloading..." -ForegroundColor Yellow
        Remove-Item -LiteralPath $Destination -Force
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $Destination
    }
}
else {
    Write-Host "Downloading: $DownloadUrl"
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $Destination
}

if (-not (Test-Path -LiteralPath $Destination -PathType Leaf)) {
    throw "Download failed; file not found: $Destination"
}

# -----------------------------------------------------------------------------
# Verify SHA-256 Checksum
# -----------------------------------------------------------------------------

Write-Step 'Verifying SHA-256 checksum'

$ActualHash = (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash.ToLowerInvariant()

Write-Host "Expected: $ExpectedHash"
Write-Host "Actual:   $ActualHash"

if ($ActualHash -ne $ExpectedHash) {
    Remove-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue
    throw "SHA-256 CHECKSUM VERIFICATION FAILED! Download has been deleted."
}

Write-Host 'SHA-256 verification PASSED.' -ForegroundColor Green

# Save checksum and metadata for subsequent steps
Set-Content -LiteralPath $ChecksumFile -Value "$ExpectedHash  $FileName`n" -Encoding utf8NoBOM

$Metadata = [pscustomobject]@{
    Version      = $GoVersion
    FileName     = $FileName
    Sha256       = $ExpectedHash
    DownloadUrl  = $DownloadUrl
    DownloadedAt = (Get-Date -Format 'o')
}
$Metadata | ConvertTo-Json | Set-Content -LiteralPath $MetadataFile -Encoding utf8NoBOM

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 1 COMPLETE: Go Download Verified' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Version:  $GoVersion"
Write-Host "Archive:  $Destination"
Write-Host "SHA-256:  $ActualHash (VERIFIED)" -ForegroundColor Green
Write-Host
Write-Host 'Nothing has been extracted or installed to the system.'
