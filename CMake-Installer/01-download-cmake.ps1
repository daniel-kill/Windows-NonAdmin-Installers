#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 1: Discover, download, and verify CMake Portable zip
#
# Official Repository: https://github.com/Kitware/CMake
#
# This script:
#   1. Queries GitHub API for the latest stable CMake release.
#   2. Locates cmake-*-windows-x86_64.zip and cmake-*-SHA-256.txt.
#   3. Downloads artifacts into $HOME\Downloads\cmake.
#   4. Verifies the SHA-256 digest against official hash list.
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$DownloadDir = Join-Path $HOME 'Downloads\cmake'
$ApiUrl = 'https://api.github.com/repos/Kitware/CMake/releases/latest'

Write-Step 'Preparing download directory'
if (-not (Test-Path -LiteralPath $DownloadDir -PathType Container)) {
    New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
}

Write-Step 'Querying CMake release catalog'
Write-Host "API URL: $ApiUrl"

$Release = $null
try {
    $Release = Invoke-RestMethod -Uri $ApiUrl -Method Get -Headers @{ 'User-Agent' = 'CMake-NonAdmin-Installer' }
}
catch {
    Write-Warning "GitHub API query failed or was rate-limited: $($_.Exception.Message)"
}

$Version = $null
$ZipAsset = $null
$ShaAsset = $null

if ($Release -and $Release.assets) {
    $Version = $Release.tag_name.TrimStart('v')
    $ZipAsset = $Release.assets | Where-Object { $_.name -match '^cmake-.*-windows-x86_64\.zip$' } | Select-Object -First 1
    $ShaAsset = $Release.assets | Where-Object { $_.name -match '^cmake-.*-SHA-256\.txt$' } | Select-Object -First 1
}

if (-not $ZipAsset) {
    Write-Host "Falling back to stable release baseline..." -ForegroundColor Yellow
    $Version = '4.5.0'
    $BaseUrl = "https://github.com/Kitware/CMake/releases/download/v$Version"
    $ZipAsset = [pscustomobject]@{
        name                 = "cmake-$Version-windows-x86_64.zip"
        browser_download_url = "$BaseUrl/cmake-$Version-windows-x86_64.zip"
    }
    $ShaAsset = [pscustomobject]@{
        name                 = "cmake-$Version-SHA-256.txt"
        browser_download_url = "$BaseUrl/cmake-$Version-SHA-256.txt"
    }
}

$ZipName = $ZipAsset.name
$ZipUrl = $ZipAsset.browser_download_url
$ZipPath = Join-Path $DownloadDir $ZipName

$ShaName = if ($ShaAsset) { $ShaAsset.name } else { "cmake-$Version-SHA-256.txt" }
$ShaUrl = if ($ShaAsset) { $ShaAsset.browser_download_url } else { "https://github.com/Kitware/CMake/releases/download/v$Version/$ShaName" }
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
$EscapedZipName = [regex]::Escape($ZipName)
$ShaMatch = [regex]::Match($ShaContent, "(?im)^([0-9a-fA-F]{64})\s+$EscapedZipName")
if (-not $ShaMatch.Success) {
    throw "Failed to locate expected SHA-256 hash for $ZipName in $ShaPath"
}
$ExpectedHash = $ShaMatch.Groups[1].Value.ToLowerInvariant()
Write-Host "Official Expected SHA-256: $ExpectedHash" -ForegroundColor Green

Write-Step 'Downloading CMake portable zip archive'
if (Test-Path -LiteralPath $ZipPath -PathType Leaf) {
    Write-Host "Existing archive detected. Verifying checksum..." -ForegroundColor Yellow
    $ExistingHash = (Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($ExistingHash -eq $ExpectedHash) {
        Write-Host "Existing archive verified successfully ($ExistingHash)." -ForegroundColor Green
    }
    else {
        Write-Warning "Existing archive hash mismatch. Re-downloading..."
        Remove-Item -LiteralPath $ZipPath -Force
        Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath
    }
}
else {
    Write-Host "Fetching $ZipUrl..."
    Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath
}

Write-Step 'Verifying downloaded archive checksum'
$ActualHash = (Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
if ($ActualHash -ne $ExpectedHash) {
    throw "SHA-256 verification FAILED!`nExpected: $ExpectedHash`nActual:   $ActualHash"
}
Write-Host "SHA-256 verified successfully: $ActualHash" -ForegroundColor Green

$Metadata = [ordered]@{
    version      = $Version
    archive_name = $ZipName
    archive_path = $ZipPath
    sha256       = $ActualHash
    download_url = $ZipUrl
    downloaded_at = (Get-Date).ToString('o')
}
$Metadata | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $MetadataFile -Encoding utf8
Write-Host "Release metadata recorded to: $MetadataFile" -ForegroundColor Green
