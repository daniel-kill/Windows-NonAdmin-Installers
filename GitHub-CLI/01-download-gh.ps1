#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 1: Discover, download, and verify GitHub CLI (gh)
#
# Official Repository: https://github.com/cli/cli
#
# This script:
#   1. Queries GitHub API for the latest stable GitHub CLI release.
#   2. Locates the Windows amd64 zip package and checksums file.
#   3. Downloads artifacts into $HOME\Downloads\gh.
#   4. Verifies the SHA-256 digest against official checksums.txt.
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$DownloadDir = Join-Path $HOME 'Downloads\gh'
$ApiUrl = 'https://api.github.com/repos/cli/cli/releases/latest'

Write-Step 'Preparing download directory'
if (-not (Test-Path -LiteralPath $DownloadDir -PathType Container)) {
    New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
}

Write-Step 'Querying GitHub CLI release catalog'
Write-Host "API URL: $ApiUrl"

$Release = $null
try {
    $Release = Invoke-RestMethod -Uri $ApiUrl -Method Get -Headers @{ 'User-Agent' = 'Gh-NonAdmin-Installer' }
}
catch {
    Write-Warning "GitHub API query failed or was rate-limited: $($_.Exception.Message)"
}

$Version = $null
$ZipAsset = $null
$ChecksumAsset = $null

if ($Release -and $Release.assets) {
    $Version = $Release.tag_name.TrimStart('v')
    $ZipAsset = $Release.assets | Where-Object { $_.name -match '^gh_.*_windows_amd64\.zip$' } | Select-Object -First 1
    $ChecksumAsset = $Release.assets | Where-Object { $_.name -match '^gh_.*_checksums\.txt$' } | Select-Object -First 1
}

if (-not $ZipAsset) {
    Write-Host "Falling back to stable release baseline..." -ForegroundColor Yellow
    $Version = '2.104.0'
    $BaseUrl = "https://github.com/cli/cli/releases/download/v$Version"
    $ZipAsset = [pscustomobject]@{
        name                 = "gh_${Version}_windows_amd64.zip"
        browser_download_url = "$BaseUrl/gh_${Version}_windows_amd64.zip"
    }
    $ChecksumAsset = [pscustomobject]@{
        name                 = "gh_${Version}_checksums.txt"
        browser_download_url = "$BaseUrl/gh_${Version}_checksums.txt"
    }
}

$ZipName = $ZipAsset.name
$ZipUrl = $ZipAsset.browser_download_url
$ZipPath = Join-Path $DownloadDir $ZipName

$ChecksumName = if ($ChecksumAsset) { $ChecksumAsset.name } else { "gh_${Version}_checksums.txt" }
$ChecksumUrl = if ($ChecksumAsset) { $ChecksumAsset.browser_download_url } else { "$ZipUrl.txt" }
$ChecksumPath = Join-Path $DownloadDir $ChecksumName
$MetadataFile = Join-Path $DownloadDir 'release-info.json'

Write-Host "Release Version: $Version" -ForegroundColor Green
Write-Host "Package Archive: $ZipName"
Write-Host "Checksums File:  $ChecksumName"

Write-Step 'Downloading checksums file'
Invoke-WebRequest -Uri $ChecksumUrl -OutFile $ChecksumPath

# Parse expected hash for the zip file
$ChecksumLines = Get-Content -LiteralPath $ChecksumPath
$ExpectedHash = $null
foreach ($Line in $ChecksumLines) {
    if ($Line -match "([0-9a-fA-F]{64})\s+.*$([regex]::Escape($ZipName))") {
        $ExpectedHash = $Matches[1].ToLowerInvariant()
        break
    }
}

if (-not $ExpectedHash) {
    throw "Could not parse expected SHA-256 for $ZipName from $ChecksumPath"
}
Write-Host "Official Expected SHA-256: $ExpectedHash" -ForegroundColor Green

Write-Step 'Downloading GitHub CLI zip archive'
$NeedsDownload = $true
if (Test-Path -LiteralPath $ZipPath -PathType Leaf) {
    $ExistingHash = (Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($ExistingHash -eq $ExpectedHash) {
        Write-Host "Existing archive already matches expected SHA-256: $ZipPath" -ForegroundColor Green
        $NeedsDownload = $false
    }
    else {
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
    throw "SHA-256 CHECKSUM VERIFICATION FAILED! Downloaded archive deleted."
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
Write-Host ' STEP 1 COMPLETE: GitHub CLI Download Verified' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Version: $Version"
Write-Host "Archive: $ZipPath"
Write-Host "SHA-256: $ActualHash (VERIFIED)" -ForegroundColor Green
Write-Host
Write-Host 'Nothing has been extracted or installed to the system.'
