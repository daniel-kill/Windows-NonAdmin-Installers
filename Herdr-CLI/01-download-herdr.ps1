#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 1: Discover, download, and verify Herdr AI Agent Runtime (herdr-core / hc)
#
# Official Site: https://herdr.dev/
# Official Manifest: https://releases.herdr.dev/core/latest.json
#
# This script:
#   1. Queries the official Herdr release manifest.
#   2. Locates the Windows x86_64 archive and official SHA-256 digest.
#   3. Downloads the archive into $HOME\Downloads\herdr.
#   4. Verifies SHA-256 integrity hash.
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$DownloadDir = Join-Path $HOME 'Downloads\herdr'
$ManifestUrl = 'https://releases.herdr.dev/core/latest.json'

Write-Step 'Preparing download directory'
if (-not (Test-Path -LiteralPath $DownloadDir -PathType Container)) {
    New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
}

Write-Step 'Querying Herdr release manifest'
Write-Host "Manifest URL: $ManifestUrl"

$Manifest = $null
try {
    $Manifest = Invoke-RestMethod -Uri $ManifestUrl -Method Get -Headers @{ 'User-Agent' = 'Herdr-NonAdmin-Installer' }
}
catch {
    Write-Warning "Herdr release manifest query failed: $($_.Exception.Message)"
}

$Version = $null
$ZipUrl = $null
$ExpectedHash = $null

if ($Manifest -and $Manifest.targets -and $Manifest.targets.'windows-x86_64') {
    $Version = $Manifest.version
    $TargetInfo = $Manifest.targets.'windows-x86_64'
    $ZipUrl = $TargetInfo.url
    $ExpectedHash = $TargetInfo.sha256.ToLowerInvariant()
}

if (-not $ZipUrl) {
    Write-Host "Falling back to stable release baseline..." -ForegroundColor Yellow
    $Version = '0.1.21'
    $ZipUrl = "https://releases.herdr.dev/core/$Version/herdr-core-windows-x86_64.zip"
    $ExpectedHash = 'a8984634c35b58ba82d0aec078d5a5e6004da01d5a25b3daf822ab5e31c7312b'
}

$ZipName = "herdr-core-$Version-windows-x86_64.zip"
$ZipPath = Join-Path $DownloadDir $ZipName
$MetadataFile = Join-Path $DownloadDir 'release-info.json'

Write-Host "Release Version: $Version" -ForegroundColor Green
Write-Host "Package Archive: $ZipName"
Write-Host "Official Expected SHA-256: $ExpectedHash" -ForegroundColor Green

Write-Step 'Downloading Herdr core archive'
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
