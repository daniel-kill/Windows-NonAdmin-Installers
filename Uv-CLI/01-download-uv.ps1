#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 1: Discover, download, and verify Astral uv Python package manager
#
# Official Repository: https://github.com/astral-sh/uv
#
# This script:
#   1. Queries GitHub API for the latest stable uv release.
#   2. Locates uv-x86_64-pc-windows-msvc.zip and sha256 file.
#   3. Downloads the archive into $HOME\Downloads\uv.
#   4. Verifies SHA-256 integrity hash.
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$DownloadDir = Join-Path $HOME 'Downloads\uv'
$ApiUrl = 'https://api.github.com/repos/astral-sh/uv/releases/latest'

Write-Step 'Preparing download directory'
if (-not (Test-Path -LiteralPath $DownloadDir -PathType Container)) {
    New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
}

Write-Step 'Querying uv release catalog'
Write-Host "API URL: $ApiUrl"

$Release = $null
try {
    $Release = Invoke-RestMethod -Uri $ApiUrl -Method Get -Headers @{ 'User-Agent' = 'Uv-NonAdmin-Installer' }
}
catch {
    Write-Warning "GitHub API query failed or was rate-limited: $($_.Exception.Message)"
}

$Version = $null
$ZipAsset = $null
$ShaAsset = $null

if ($Release -and $Release.assets) {
    $Version = $Release.tag_name.TrimStart('v')
    $ZipAsset = $Release.assets | Where-Object { $_.name -match '^uv-x86_64-pc-windows-msvc\.zip$' } | Select-Object -First 1
    $ShaAsset = $Release.assets | Where-Object { $_.name -match '^uv-x86_64-pc-windows-msvc\.zip\.sha256$' } | Select-Object -First 1
}

if (-not $ZipAsset) {
    Write-Host "Falling back to stable release baseline..." -ForegroundColor Yellow
    $Version = '0.13.8'
    $BaseUrl = "https://github.com/astral-sh/uv/releases/download/$Version"
    $ZipAsset = [pscustomobject]@{
        name                 = 'uv-x86_64-pc-windows-msvc.zip'
        browser_download_url = "$BaseUrl/uv-x86_64-pc-windows-msvc.zip"
    }
    $ShaAsset = [pscustomobject]@{
        name                 = 'uv-x86_64-pc-windows-msvc.zip.sha256'
        browser_download_url = "$BaseUrl/uv-x86_64-pc-windows-msvc.zip.sha256"
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

Write-Step 'Downloading checksum file'
Invoke-WebRequest -Uri $ShaUrl -OutFile $ShaPath
if (-not (Test-Path -LiteralPath $ShaPath -PathType Leaf)) {
    throw "Failed to download checksum file: $ShaPath"
}

$ShaContent = Get-Content -LiteralPath $ShaPath -Raw
$ShaMatch = [regex]::Match($ShaContent, '(?im)^([0-9a-fA-F]{64})')
if (-not $ShaMatch.Success) {
    throw "Failed to parse 64-character SHA-256 hash from $ShaPath"
}
$ExpectedHash = $ShaMatch.Groups[1].Value.ToLowerInvariant()
Write-Host "Official Expected SHA-256: $ExpectedHash" -ForegroundColor Green

Write-Step 'Downloading uv zip archive'
if (Test-Path -LiteralPath $ZipPath -PathType Leaf) {
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
    version       = $Version
    archive_name  = $ZipName
    archive_path  = $ZipPath
    sha256        = $ActualHash
    download_url  = $ZipUrl
    downloaded_at = (Get-Date).ToString('o')
}
$Metadata | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $MetadataFile -Encoding utf8
Write-Host "Release metadata recorded to: $MetadataFile" -ForegroundColor Green
