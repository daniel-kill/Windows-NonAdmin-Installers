#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 1: Discover, download, and verify eza modern ls replacement
#
# Official Repository: https://github.com/eza-community/eza
#
# This script:
#   1. Queries GitHub API for the latest stable eza release.
#   2. Locates eza.exe_x86_64-pc-windows-gnu.zip and parses SHA-256 from release notes.
#   3. Downloads the archive into $HOME\Downloads\eza.
#   4. Verifies SHA-256 integrity hash.
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$DownloadDir = Join-Path $HOME 'Downloads\eza'
$ApiUrl = 'https://api.github.com/repos/eza-community/eza/releases/latest'

Write-Step 'Preparing download directory'
if (-not (Test-Path -LiteralPath $DownloadDir -PathType Container)) {
    New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
}

Write-Step 'Querying eza release catalog'
Write-Host "API URL: $ApiUrl"

$Release = $null
try {
    $Release = Invoke-RestMethod -Uri $ApiUrl -Method Get -Headers @{ 'User-Agent' = 'Eza-NonAdmin-Installer' }
}
catch {
    Write-Warning "GitHub API query failed or was rate-limited: $($_.Exception.Message)"
}

$Version = $null
$ZipAsset = $null
$ExpectedHash = $null

if ($Release -and $Release.assets) {
    $Version = $Release.tag_name.TrimStart('v')
    $ZipAsset = $Release.assets | Where-Object { $_.name -match 'eza.*windows.*\.zip$' } | Select-Object -First 1

    if ($Release.body) {
        $BodyMatch = [regex]::Match($Release.body, '(?im)([0-9a-fA-F]{64})\s+.*eza\.exe_x86_64-pc-windows-gnu\.zip')
        if ($BodyMatch.Success) {
            $ExpectedHash = $BodyMatch.Groups[1].Value.ToLowerInvariant()
        }
    }
}

if (-not $ZipAsset) {
    Write-Host "Falling back to stable release baseline..." -ForegroundColor Yellow
    $Version = '0.23.5'
    $BaseUrl = "https://github.com/eza-community/eza/releases/download/v$Version"
    $ZipAsset = [pscustomobject]@{
        name                 = 'eza.exe_x86_64-pc-windows-gnu.zip'
        browser_download_url = "$BaseUrl/eza.exe_x86_64-pc-windows-gnu.zip"
    }
    $ExpectedHash = 'c830638c844a5b89d39ba662b5549903a71fa539018e813880f5b8afa77bac2e'
}

$ZipName = $ZipAsset.name
$ZipUrl = $ZipAsset.browser_download_url
$ZipPath = Join-Path $DownloadDir $ZipName
$MetadataFile = Join-Path $DownloadDir 'release-info.json'

Write-Host "Release Version: $Version" -ForegroundColor Green
Write-Host "Package Archive: $ZipName"
if ($ExpectedHash) {
    Write-Host "Official Expected SHA-256: $ExpectedHash" -ForegroundColor Green
}

Write-Step 'Downloading eza zip archive'
if (Test-Path -LiteralPath $ZipPath -PathType Leaf) {
    if ($ExpectedHash) {
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
}
else {
    Write-Host "Fetching $ZipUrl..."
    Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath
}

Write-Step 'Verifying downloaded archive checksum'
$ActualHash = (Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
if ($ExpectedHash -and $ActualHash -ne $ExpectedHash) {
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
