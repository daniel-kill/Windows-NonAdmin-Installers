#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 1: Discover, download, and verify ripgrep standalone binary
#
# Official Repository: https://github.com/BurntSushi/ripgrep
#
# This script:
#   1. Queries GitHub API for the latest stable ripgrep release.
#   2. Locates the Windows x86_64 MSVC zip archive and SHA-256 checksum file.
#   3. Downloads artifacts into $HOME\Downloads\ripgrep.
#   4. Verifies the SHA-256 digest against the official checksum file.
#
# This script DOES NOT:
#   - Require administrator privileges.
#   - Extract or install ripgrep.
#   - Modify PATH or environment variables.
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$DownloadDir = Join-Path $HOME 'Downloads\ripgrep'
$ApiUrl = 'https://api.github.com/repos/BurntSushi/ripgrep/releases/latest'

Write-Step 'Preparing download directory'
if (-not (Test-Path -LiteralPath $DownloadDir -PathType Container)) {
    New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
}

Write-Step 'Querying ripgrep release catalog'
Write-Host "API URL: $ApiUrl"

$Release = $null
try {
    $Release = Invoke-RestMethod -Uri $ApiUrl -Method Get -Headers @{ 'User-Agent' = 'Ripgrep-NonAdmin-Installer' }
}
catch {
    Write-Warning "GitHub API query failed or was rate-limited: $($_.Exception.Message)"
}

$Version = $null
$ZipAsset = $null
$ShaAsset = $null

if ($Release -and $Release.assets) {
    $Version = $Release.tag_name.TrimStart('v')
    $ZipAsset = $Release.assets | Where-Object { $_.name -match '^ripgrep-.*-x86_64-pc-windows-msvc\.zip$' } | Select-Object -First 1
    $ShaAsset = $Release.assets | Where-Object { $_.name -match '^ripgrep-.*-x86_64-pc-windows-msvc\.zip\.sha256$' } | Select-Object -First 1
}

if (-not $ZipAsset) {
    Write-Host "Falling back to stable release baseline..." -ForegroundColor Yellow
    $Version = '15.2.0'
    $BaseUrl = "https://github.com/BurntSushi/ripgrep/releases/download/$Version"
    $ZipAsset = [pscustomobject]@{
        name                 = "ripgrep-$Version-x86_64-pc-windows-msvc.zip"
        browser_download_url = "$BaseUrl/ripgrep-$Version-x86_64-pc-windows-msvc.zip"
    }
    $ShaAsset = [pscustomobject]@{
        name                 = "ripgrep-$Version-x86_64-pc-windows-msvc.zip.sha256"
        browser_download_url = "$BaseUrl/ripgrep-$Version-x86_64-pc-windows-msvc.zip.sha256"
    }
}

$ZipName = $ZipAsset.name
$ZipUrl = $ZipAsset.browser_download_url
$ZipPath = Join-Path $DownloadDir $ZipName

$ShaName = if ($ShaAsset) { $ShaAsset.name } else { "$ZipName.sha256" }
$ShaUrl = if ($ShaAsset) { $ShaAsset.browser_download_url } else { "$ZipUrl.sha256" }
$ShaPath = Join-Path $DownloadDir $ShaName

$MetadataFile = Join-Path $DownloadDir 'release-info.json'

Write-Host "Release Version: $Version" -ForegroundColor Green
Write-Host "Package Archive: $ZipName"
Write-Host "Checksum File:   $ShaName"

Write-Step 'Downloading checksum file'
Invoke-WebRequest -Uri $ShaUrl -OutFile $ShaPath
if (-not (Test-Path -LiteralPath $ShaPath -PathType Leaf)) {
    throw "Failed to download checksum file: $ShaPath"
}

$ShaContent = Get-Content -LiteralPath $ShaPath -Raw
$ShaMatch = [regex]::Match($ShaContent, '(?im)^([0-9a-fA-F]{64})\s+')
if (-not $ShaMatch.Success) {
    throw "Failed to parse 64-character SHA-256 hash from $ShaPath"
}
$ExpectedHash = $ShaMatch.Groups[1].Value.ToLowerInvariant()
Write-Host "Official Expected SHA-256: $ExpectedHash" -ForegroundColor Green

Write-Step 'Downloading ripgrep zip archive'
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

Write-Step 'Verifying archive SHA-256 checksum'
$ActualHash = (Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Host "Expected: $ExpectedHash"
Write-Host "Actual:   $ActualHash"

if ($ActualHash -ne $ExpectedHash) {
    Remove-Item -LiteralPath $ZipPath -Force -ErrorAction SilentlyContinue
    throw "SHA-256 CHECKSUM VERIFICATION FAILED! Downloaded archive has been deleted."
}
Write-Host 'SHA-256 verification PASSED.' -ForegroundColor Green

$Metadata = [pscustomobject]@{
    Version      = $Version
    FileName     = $ZipName
    Sha256       = $ActualHash
    DownloadUrl  = $ZipUrl
    DownloadedAt = (Get-Date -Format 'o')
}
$Metadata | ConvertTo-Json | Set-Content -LiteralPath $MetadataFile -Encoding utf8NoBOM

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 1 COMPLETE: ripgrep Download Verified' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Version: $Version"
Write-Host "Archive: $ZipPath"
Write-Host "SHA-256: $ActualHash (VERIFIED)" -ForegroundColor Green
Write-Host
Write-Host 'Nothing has been extracted or installed to the system.'
