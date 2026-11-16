#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 1: Discover, download, and verify the latest Node.js LTS release
#
# This script:
#   1. Queries the official Node.js distribution catalog (https://nodejs.org/dist/index.json).
#   2. Identifies the latest Long Term Support (LTS) release for Windows x64.
#   3. Downloads the official zip archive and its corresponding SHASUMS256.txt file.
#   4. Verifies the SHA-256 checksum of the downloaded archive.
#
# This script DOES NOT:
#   - Require administrator privileges.
#   - Extract or install Node.js.
#   - Modify PATH or environment variables.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

$DownloadDir = Join-Path $HOME 'Downloads\Node'
$IndexUrl = 'https://nodejs.org/dist/index.json'

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
# Query official Node.js release index
# -----------------------------------------------------------------------------

Write-Step 'Querying official Node.js LTS release catalog'

Write-Host "Index URL: $IndexUrl"
$Releases = Invoke-RestMethod -Uri $IndexUrl -Method Get

if (-not $Releases -or $Releases.Count -eq 0) {
    throw "Failed to retrieve Node.js release index from $IndexUrl"
}

# Find latest LTS release supporting win-x64-zip
$LtsRelease = $Releases | Where-Object {
    $_.lts -ne $false -and $_.files -contains 'win-x64-zip'
} | Select-Object -First 1

if (-not $LtsRelease) {
    throw 'No suitable Node.js LTS release with win-x64-zip found.'
}

$NodeVersion = $LtsRelease.version
$ArchiveFileName = "node-$NodeVersion-win-x64.zip"
$DistBase = "https://nodejs.org/dist/$NodeVersion"
$ArchiveUrl = "$DistBase/$ArchiveFileName"
$ChecksumsUrl = "$DistBase/SHASUMS256.txt"

$ArchiveDest = Join-Path $DownloadDir $ArchiveFileName
$ChecksumsDest = Join-Path $DownloadDir 'SHASUMS256.txt'
$MetadataFile = Join-Path $DownloadDir 'release-info.json'

Write-Host "Selected Node.js LTS release: $NodeVersion"
Write-Host "Archive URL: $ArchiveUrl"

# -----------------------------------------------------------------------------
# Download SHASUMS256.txt
# -----------------------------------------------------------------------------

Write-Step 'Downloading official SHASUMS256.txt'

Write-Host "Downloading: $ChecksumsUrl"
Invoke-WebRequest -Uri $ChecksumsUrl -OutFile $ChecksumsDest

if (-not (Test-Path -LiteralPath $ChecksumsDest -PathType Leaf)) {
    throw "Failed to download checksums from: $ChecksumsUrl"
}

$ChecksumsContent = Get-Content -LiteralPath $ChecksumsDest -Raw
$ChecksumRegex = "(?im)^([0-9a-f]{64})\s+(" + [regex]::Escape($ArchiveFileName) + ")$"
$Match = [regex]::Match($ChecksumsContent, $ChecksumRegex)

if (-not $Match.Success) {
    throw "Could not find checksum for $ArchiveFileName in $ChecksumsDest"
}

$ExpectedHash = $Match.Groups[1].Value.ToLowerInvariant()
Write-Host "Official SHA-256 for $ArchiveFileName`: $ExpectedHash"

# -----------------------------------------------------------------------------
# Download archive
# -----------------------------------------------------------------------------

Write-Step 'Downloading Node.js binary archive'

if (Test-Path -LiteralPath $ArchiveDest -PathType Leaf) {
    $ExistingHash = (Get-FileHash -LiteralPath $ArchiveDest -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($ExistingHash -eq $ExpectedHash) {
        Write-Host "Archive is already downloaded and verified: $ArchiveDest" -ForegroundColor Green
    }
    else {
        Write-Host "Hash mismatch on existing archive. Re-downloading..." -ForegroundColor Yellow
        Remove-Item -LiteralPath $ArchiveDest -Force
        Invoke-WebRequest -Uri $ArchiveUrl -OutFile $ArchiveDest
    }
}
else {
    Write-Host "Downloading: $ArchiveUrl"
    Invoke-WebRequest -Uri $ArchiveUrl -OutFile $ArchiveDest
}

# -----------------------------------------------------------------------------
# Verify SHA-256 Checksum
# -----------------------------------------------------------------------------

Write-Step 'Verifying SHA-256 checksum'

$ActualHash = (Get-FileHash -LiteralPath $ArchiveDest -Algorithm SHA256).Hash.ToLowerInvariant()

Write-Host "Expected: $ExpectedHash"
Write-Host "Actual:   $ActualHash"

if ($ActualHash -ne $ExpectedHash) {
    Remove-Item -LiteralPath $ArchiveDest -Force -ErrorAction SilentlyContinue
    throw "SHA-256 CHECKSUM VERIFICATION FAILED! Corrupt download deleted."
}

Write-Host 'SHA-256 verification PASSED.' -ForegroundColor Green

# Save metadata for subsequent steps
$Metadata = [pscustomobject]@{
    Version      = $NodeVersion
    FileName     = $ArchiveFileName
    Sha256       = $ExpectedHash
    DownloadUrl  = $ArchiveUrl
    DownloadedAt = (Get-Date -Format 'o')
}
$Metadata | ConvertTo-Json | Set-Content -LiteralPath $MetadataFile -Encoding utf8NoBOM

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 1 COMPLETE: Node.js Download Verified' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Version:  $NodeVersion (LTS)"
Write-Host "Archive:  $ArchiveDest"
Write-Host "SHA-256:  $ActualHash (VERIFIED)" -ForegroundColor Green
Write-Host
Write-Host 'Nothing has been extracted or installed to the system.'
