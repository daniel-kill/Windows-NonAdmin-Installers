#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 1: Discover, download, and verify Deno runtime for Windows
#
# Official Repository: https://github.com/denoland/deno
#
# This script:
#   1. Queries GitHub API for the latest stable Deno release.
#   2. Locates deno-x86_64-pc-windows-msvc.zip and sha256sum file.
#   3. Downloads the archive into $HOME\Downloads\deno.
#   4. Verifies SHA-256 integrity hash.
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$DownloadDir = Join-Path $HOME 'Downloads\deno'
$ApiUrl = 'https://api.github.com/repos/denoland/deno/releases/latest'

Write-Step 'Preparing download directory'
if (-not (Test-Path -LiteralPath $DownloadDir -PathType Container)) {
    New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
}

Write-Step 'Querying Deno release catalog'
Write-Host "API URL: $ApiUrl"

$Release = $null
try {
    $Release = Invoke-RestMethod -Uri $ApiUrl -Method Get -Headers @{ 'User-Agent' = 'Deno-NonAdmin-Installer' }
}
catch {
    Write-Warning "GitHub API query failed or was rate-limited: $($_.Exception.Message)"
}

$Version = $null
$ZipAsset = $null
$ShaAsset = $null

if ($Release -and $Release.assets) {
    $Version = $Release.tag_name.TrimStart('v')
    $ZipAsset = $Release.assets | Where-Object { $_.name -eq 'deno-x86_64-pc-windows-msvc.zip' } | Select-Object -First 1
    $ShaAsset = $Release.assets | Where-Object { $_.name -eq 'deno-x86_64-pc-windows-msvc.zip.sha256sum' } | Select-Object -First 1
}

if (-not $ZipAsset) {
    Write-Host "Falling back to stable release baseline..." -ForegroundColor Yellow
    $Version = '2.9.8'
    $BaseUrl = "https://github.com/denoland/deno/releases/download/v$Version"
    $ZipAsset = [pscustomobject]@{
        name                 = 'deno-x86_64-pc-windows-msvc.zip'
        browser_download_url = "$BaseUrl/deno-x86_64-pc-windows-msvc.zip"
    }
    $ShaAsset = [pscustomobject]@{
        name                 = 'deno-x86_64-pc-windows-msvc.zip.sha256sum'
        browser_download_url = "$BaseUrl/deno-x86_64-pc-windows-msvc.zip.sha256sum"
    }
}

$ZipName = $ZipAsset.name
$ZipUrl = $ZipAsset.browser_download_url
$ZipPath = Join-Path $DownloadDir $ZipName

$ShaName = if ($ShaAsset) { $ShaAsset.name } else { "$ZipName.sha256sum" }
$ShaUrl = if ($ShaAsset) { $ShaAsset.browser_download_url } else { "https://github.com/denoland/deno/releases/download/v$Version/$ShaName" }
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
$ShaMatch = [regex]::Match($ShaContent, '(?im)\b([0-9a-fA-F]{64})\b')
if (-not $ShaMatch.Success) {
    throw "Failed to parse 64-character SHA-256 hash from $ShaPath"
}
$ExpectedHash = $ShaMatch.Groups[1].Value.ToLowerInvariant()
Write-Host "Official Expected SHA-256: $ExpectedHash" -ForegroundColor Green

Write-Step 'Downloading Deno zip archive'
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
