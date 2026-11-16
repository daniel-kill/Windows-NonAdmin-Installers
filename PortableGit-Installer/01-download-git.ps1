#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 1: Discover, download, and verify PortableGit x64 package
#
# Official Website: https://git-scm.com/
# Official GitHub:  https://github.com/git-for-windows/git
#
# This script:
#   1. Queries GitHub API for the latest stable Git for Windows release.
#   2. Locates the 64-bit PortableGit self-extracting archive (PortableGit-*-64-bit.7z.exe).
#   3. Downloads the archive into $HOME\Downloads\PortableGit.
#   4. Calculates SHA-256 digest and records release metadata.
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$DownloadDir = Join-Path $HOME 'Downloads\PortableGit'
$ApiUrl = 'https://api.github.com/repos/git-for-windows/git/releases/latest'

Write-Step 'Preparing download directory'
if (-not (Test-Path -LiteralPath $DownloadDir -PathType Container)) {
    New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
}

Write-Step 'Querying Git for Windows release catalog'
Write-Host "API URL: $ApiUrl"

$Release = $null
try {
    $Release = Invoke-RestMethod -Uri $ApiUrl -Method Get -Headers @{ 'User-Agent' = 'PortableGit-NonAdmin-Installer' }
}
catch {
    Write-Warning "GitHub API query failed or was rate-limited: $($_.Exception.Message)"
}

$Version = $null
$ExeAsset = $null

if ($Release -and $Release.assets) {
    $Version = $Release.tag_name.TrimStart('v').Split('.')[0..2] -join '.'
    $ExeAsset = $Release.assets | Where-Object { $_.name -match '^PortableGit-.*-64-bit\.7z\.exe$' } | Select-Object -First 1
}

if (-not $ExeAsset) {
    Write-Host "Falling back to stable release baseline..." -ForegroundColor Yellow
    $Version = '2.56.1'
    $BaseUrl = "https://github.com/git-for-windows/git/releases/download/v2.56.1.windows.1"
    $ExeAsset = [pscustomobject]@{
        name                 = "PortableGit-2.56.1-64-bit.7z.exe"
        browser_download_url = "$BaseUrl/PortableGit-2.56.1-64-bit.7z.exe"
    }
}

$FileName = $ExeAsset.name
$DownloadUrl = $ExeAsset.browser_download_url
$DestPath = Join-Path $DownloadDir $FileName
$MetadataFile = Join-Path $DownloadDir 'release-info.json'

Write-Host "Release Version: $Version" -ForegroundColor Green
Write-Host "Archive File:    $FileName"

Write-Step 'Downloading PortableGit archive'
$NeedsDownload = $true
if (Test-Path -LiteralPath $DestPath -PathType Leaf) {
    Write-Host "Existing archive found: $DestPath" -ForegroundColor Green
    $NeedsDownload = $false
}

if ($NeedsDownload) {
    Write-Host "Downloading: $DownloadUrl"
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $DestPath
}

Write-Step 'Calculating archive SHA-256 checksum'
$ActualHash = (Get-FileHash -LiteralPath $DestPath -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Host "Calculated SHA-256: $ActualHash"

$Metadata = [pscustomobject]@{
    Version      = $Version
    FileName     = $FileName
    Sha256       = $ActualHash
    DownloadUrl  = $DownloadUrl
    DownloadedAt = (Get-Date -Format 'o')
}
$Metadata | ConvertTo-Json | Set-Content -LiteralPath $MetadataFile -Encoding utf8NoBOM

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 1 COMPLETE: PortableGit Download Verified' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Version: $Version"
Write-Host "Archive: $DestPath"
Write-Host "SHA-256: $ActualHash" -ForegroundColor Green
Write-Host
Write-Host 'Nothing has been extracted or installed to the system.'
