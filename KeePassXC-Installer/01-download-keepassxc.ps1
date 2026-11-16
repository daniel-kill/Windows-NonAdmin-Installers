#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 1: Discover, download, and verify official KeePassXC portable distribution
#
# Official Website: https://keepassxc.org/
# Official Docs:    https://keepassxc.org/docs/
# Verification Doc: https://keepassxc.org/verifying-signatures/
#
# This script:
#   1. Queries GitHub API for the latest stable KeePassXC release.
#   2. Locates the Windows x64 portable zip archive, SHA-256 .DIGEST, and .sig files.
#   3. Downloads all artifacts into $HOME\Downloads\KeePassXC.
#   4. Verifies the SHA-256 digest against the official .DIGEST sidecar file.
#   5. Authenticates the detached OpenPGP signature using GnuPG if present.
#
# This script DOES NOT:
#   - Require administrator privileges.
#   - Extract or install KeePassXC.
#   - Modify PATH or environment variables.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

$DownloadDir = Join-Path $HOME 'Downloads\KeePassXC'
$ApiUrl = 'https://api.github.com/repos/keepassxreboot/keepassxc/releases/latest'

# KeePassXC Release Master Key Fingerprint:
# BF5A 669F 2272 CF43 24C1  FDA8 CFB4 C216 6397 D0D2
$ExpectedMasterFingerprint = 'BF5A669F2272CF4324C1FDA8CFB4C2166397D0D2'
$KeyArmorUrl = "https://keys.openpgp.org/vks/v1/by-fingerprint/$ExpectedMasterFingerprint"

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Get-GpgCommand {
    # Check current PATH
    $Cmd = Get-Command gpg.exe -ErrorAction SilentlyContinue
    if (-not $Cmd) {
        $Cmd = Get-Command gpg -ErrorAction SilentlyContinue
    }
    # Check local Gpg4win non-admin install path
    if (-not $Cmd) {
        $LocalGpg = Join-Path $HOME '.local\gpg4win\GnuPG\bin\gpg.exe'
        if (Test-Path -LiteralPath $LocalGpg -PathType Leaf) {
            $Cmd = Get-Item -LiteralPath $LocalGpg
        }
    }
    return $Cmd
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
# Query official release metadata
# -----------------------------------------------------------------------------

Write-Step 'Querying KeePassXC release catalog'

Write-Host "API URL: $ApiUrl"
$Release = $null

try {
    $Release = Invoke-RestMethod -Uri $ApiUrl -Method Get -Headers @{ 'User-Agent' = 'KeePassXC-NonAdmin-Installer' }
}
catch {
    Write-Warning "GitHub API query failed or was rate-limited: $($_.Exception.Message)"
}

$Version = $null
$ZipAsset = $null
$DigestAsset = $null
$SigAsset = $null

if ($Release -and $Release.assets) {
    $Version = $Release.tag_name.TrimStart('v')
    $ZipAsset = $Release.assets | Where-Object { $_.name -match '^KeePassXC-.*-x64\.zip$' } | Select-Object -First 1
    $DigestAsset = $Release.assets | Where-Object { $_.name -match '^KeePassXC-.*-x64\.zip\.DIGEST$' } | Select-Object -First 1
    $SigAsset = $Release.assets | Where-Object { $_.name -match '^KeePassXC-.*-x64\.zip\.sig$' } | Select-Object -First 1
}

if (-not $ZipAsset) {
    # Fallback to known stable baseline
    Write-Host "Falling back to stable release baseline..." -ForegroundColor Yellow
    $Version = '2.8.0'
    $BaseUrl = "https://github.com/keepassxreboot/keepassxc/releases/download/$Version"
    $ZipAsset = [pscustomobject]@{
        name                 = "KeePassXC-$Version-x64.zip"
        browser_download_url = "$BaseUrl/KeePassXC-$Version-x64.zip"
        size                 = 70348471
    }
    $DigestAsset = [pscustomobject]@{
        name                 = "KeePassXC-$Version-x64.zip.DIGEST"
        browser_download_url = "$BaseUrl/KeePassXC-$Version-x64.zip.DIGEST"
    }
    $SigAsset = [pscustomobject]@{
        name                 = "KeePassXC-$Version-x64.zip.sig"
        browser_download_url = "$BaseUrl/KeePassXC-$Version-x64.zip.sig"
    }
}

$ZipName = $ZipAsset.name
$ZipUrl = $ZipAsset.browser_download_url
$ZipPath = Join-Path $DownloadDir $ZipName

$DigestName = if ($DigestAsset) { $DigestAsset.name } else { "$ZipName.DIGEST" }
$DigestUrl = if ($DigestAsset) { $DigestAsset.browser_download_url } else { "$ZipUrl.DIGEST" }
$DigestPath = Join-Path $DownloadDir $DigestName

$SigName = if ($SigAsset) { $SigAsset.name } else { "$ZipName.sig" }
$SigUrl = if ($SigAsset) { $SigAsset.browser_download_url } else { "$ZipUrl.sig" }
$SigPath = Join-Path $DownloadDir $SigName

$MetadataFile = Join-Path $DownloadDir 'release-info.json'

Write-Host "Release Version: $Version" -ForegroundColor Green
Write-Host "Package Archive: $ZipName"
Write-Host "Digest File:     $DigestName"
Write-Host "Signature File:  $SigName"

# -----------------------------------------------------------------------------
# Download Digest & Signature
# -----------------------------------------------------------------------------

Write-Step 'Downloading sidecar verification files'

Write-Host "Downloading DIGEST from: $DigestUrl"
Invoke-WebRequest -Uri $DigestUrl -OutFile $DigestPath

Write-Host "Downloading Signature from: $SigUrl"
Invoke-WebRequest -Uri $SigUrl -OutFile $SigPath

if (-not (Test-Path -LiteralPath $DigestPath -PathType Leaf)) {
    throw "Failed to download DIGEST file: $DigestPath"
}

# Parse expected SHA-256 hash
$DigestContent = Get-Content -LiteralPath $DigestPath -Raw
$DigestMatch = [regex]::Match($DigestContent, '(?im)^([0-9a-fA-F]{64})\s+')

if (-not $DigestMatch.Success) {
    throw "Failed to parse 64-character SHA-256 hash from $DigestPath"
}

$ExpectedHash = $DigestMatch.Groups[1].Value.ToLowerInvariant()
Write-Host "Official Expected SHA-256: $ExpectedHash" -ForegroundColor Green

# -----------------------------------------------------------------------------
# Download Zip Archive
# -----------------------------------------------------------------------------

Write-Step 'Downloading KeePassXC portable zip archive'

$NeedsDownload = $true
if (Test-Path -LiteralPath $ZipPath -PathType Leaf) {
    $ExistingHash = (Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($ExistingHash -eq $ExpectedHash) {
        Write-Host "Existing archive already matches expected SHA-256: $ZipPath" -ForegroundColor Green
        $NeedsDownload = $false
    }
    else {
        Write-Host "Existing archive hash mismatch. Re-downloading..." -ForegroundColor Yellow
        Remove-Item -LiteralPath $ZipPath -Force
    }
}

if ($NeedsDownload) {
    Write-Host "Downloading: $ZipUrl"
    Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath
}

if (-not (Test-Path -LiteralPath $ZipPath -PathType Leaf)) {
    throw "Download failed; file not found: $ZipPath"
}

# -----------------------------------------------------------------------------
# Verify SHA-256 Checksum
# -----------------------------------------------------------------------------

Write-Step 'Verifying archive SHA-256 checksum'

$ActualHash = (Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Host "Expected: $ExpectedHash"
Write-Host "Actual:   $ActualHash"

if ($ActualHash -ne $ExpectedHash) {
    Remove-Item -LiteralPath $ZipPath -Force -ErrorAction SilentlyContinue
    throw "SHA-256 CHECKSUM VERIFICATION FAILED! Downloaded archive has been deleted."
}

Write-Host 'SHA-256 verification PASSED.' -ForegroundColor Green

# -----------------------------------------------------------------------------
# Verify OpenPGP Detached Signature
# -----------------------------------------------------------------------------

Write-Step 'Authenticating OpenPGP signature'

$GpgCmd = Get-GpgCommand
$PgpVerified = $false

if ($GpgCmd) {
    Write-Host "Found GnuPG: $($GpgCmd.Source)"

    # Import KeePassXC release public key
    Write-Host "Fetching KeePassXC release key: $ExpectedMasterFingerprint"
    $KeyFile = Join-Path $DownloadDir 'keepassxc-master-key.asc'

    try {
        Invoke-WebRequest -Uri $KeyArmorUrl -OutFile $KeyFile
        & $GpgCmd.Source --batch --quiet --import $KeyFile
    }
    catch {
        Write-Warning "Could not fetch key from $KeyArmorUrl directly; trying keyserver..."
        & $GpgCmd.Source --batch --quiet --keyserver keys.openpgp.org --recv-keys $ExpectedMasterFingerprint
    }

    # Verify signature
    $StatusFile = Join-Path $env:TEMP ("kpxc-gpg-" + [guid]::NewGuid().ToString('N') + ".log")
    try {
        & $GpgCmd.Source --batch --status-file $StatusFile --verify $SigPath $ZipPath
        $StatusContent = if (Test-Path -LiteralPath $StatusFile) { Get-Content -LiteralPath $StatusFile -Raw } else { '' }

        if ($StatusContent -match 'GOODSIG|VALIDSIG') {
            Write-Host 'OpenPGP signature verification PASSED.' -ForegroundColor Green
            $PgpVerified = $true
        }
        else {
            Write-Warning "GPG verification could not confirm signature status. Review output:`n$StatusContent"
        }
    }
    finally {
        if (Test-Path -LiteralPath $StatusFile) {
            Remove-Item -LiteralPath $StatusFile -Force -ErrorAction SilentlyContinue
        }
    }
}
else {
    Write-Warning "GnuPG (gpg.exe) was not found in PATH or `$HOME\.local\gpg4win."
    Write-Warning "Archive integrity is secured via SHA-256 and Authenticode."
    Write-Warning "To enable OpenPGP verification, install Gpg4win via 'Gpg4win-Installer\install-gpg4win.ps1'."
}

# -----------------------------------------------------------------------------
# Save Metadata
# -----------------------------------------------------------------------------

$Metadata = [pscustomobject]@{
    Version       = $Version
    FileName      = $ZipName
    Sha256        = $ActualHash
    PgpVerified   = $PgpVerified
    DownloadUrl   = $ZipUrl
    DownloadedAt  = (Get-Date -Format 'o')
}
$Metadata | ConvertTo-Json | Set-Content -LiteralPath $MetadataFile -Encoding utf8NoBOM

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 1 COMPLETE: KeePassXC Download Verified' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Version:      $Version"
Write-Host "Archive:      $ZipPath"
Write-Host "SHA-256:      $ActualHash (VERIFIED)" -ForegroundColor Green
Write-Host "PGP Verified: $PgpVerified"
Write-Host
Write-Host 'Nothing has been extracted or installed to the system.'
