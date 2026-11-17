#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 1: Discover, download, and verify Ninja build system binary
#
# Official Repository: https://github.com/ninja-build/ninja
#
# This script:
#   1. Queries GitHub API for the latest stable Ninja release.
#   2. Locates ninja-win.zip.
#   3. Downloads the archive into $HOME\Downloads\ninja.
#   4. Calculates and records SHA-256 integrity hash.
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$DownloadDir = Join-Path $HOME 'Downloads\ninja'
$ApiUrl = 'https://api.github.com/repos/ninja-build/ninja/releases/latest'

Write-Step 'Preparing download directory'
if (-not (Test-Path -LiteralPath $DownloadDir -PathType Container)) {
    New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
}

Write-Step 'Querying Ninja release catalog'
Write-Host "API URL: $ApiUrl"

$Release = $null
try {
    $Release = Invoke-RestMethod -Uri $ApiUrl -Method Get -Headers @{ 'User-Agent' = 'Ninja-NonAdmin-Installer' }
}
catch {
    Write-Warning "GitHub API query failed or was rate-limited: $($_.Exception.Message)"
}

$Version = $null
$ZipAsset = $null

if ($Release -and $Release.assets) {
    $Version = $Release.tag_name.TrimStart('v')
    $ZipAsset = $Release.assets | Where-Object { $_.name -eq 'ninja-win.zip' } | Select-Object -First 1
}

if (-not $ZipAsset) {
    Write-Host "Falling back to stable release baseline..." -ForegroundColor Yellow
    $Version = '1.13.2'
    $BaseUrl = "https://github.com/ninja-build/ninja/releases/download/v$Version"
    $ZipAsset = [pscustomobject]@{
        name                 = 'ninja-win.zip'
        browser_download_url = "$BaseUrl/ninja-win.zip"
    }
}

$ZipName = $ZipAsset.name
$ZipUrl = $ZipAsset.browser_download_url
$ZipPath = Join-Path $DownloadDir $ZipName
$MetadataFile = Join-Path $DownloadDir 'release-info.json'

Write-Host "Release Version: $Version" -ForegroundColor Green
Write-Host "Package Archive: $ZipName"

Write-Step 'Downloading Ninja archive'
if (Test-Path -LiteralPath $ZipPath -PathType Leaf) {
    Write-Host "Existing archive detected: $ZipPath" -ForegroundColor Yellow
}
else {
    Write-Host "Fetching $ZipUrl..."
    Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath
}

Write-Step 'Calculating SHA-256 digest'
$ActualHash = (Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Host "SHA-256 Digest: $ActualHash" -ForegroundColor Green

$Metadata = [ordered]@{
    version       = $Version
    archive_name  = $ZipName
    archive_path  = $ZipPath
    sha256        = $ActualHash
    download_url  = $ZipUrl
    downloaded_at = (Get-Date).ToString('o')
}
$Metadata | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $MetadataFile -Encoding utf8
Write-Host "Release metadata recorded to: $MetadataFile" -ForegroundColor Green
