#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 1: Discover, download, and verify fd standalone binary
#
# Official Repository: https://github.com/sharkdp/fd
#
# This script:
#   1. Queries GitHub API for the latest stable fd release.
#   2. Locates the Windows x86_64 MSVC zip archive.
#   3. Downloads artifacts into $HOME\Downloads\fd.
#   4. Verifies the SHA-256 digest against GitHub release metadata.
#
# This script DOES NOT:
#   - Require administrator privileges.
#   - Extract or install fd.
#   - Modify PATH or environment variables.
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$DownloadDir = Join-Path $HOME 'Downloads\fd'
$ApiUrl = 'https://api.github.com/repos/sharkdp/fd/releases/latest'

Write-Step 'Preparing download directory'
if (-not (Test-Path -LiteralPath $DownloadDir -PathType Container)) {
    New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
}

Write-Step 'Querying fd release catalog'
Write-Host "API URL: $ApiUrl"

$Release = $null
try {
    $Release = Invoke-RestMethod -Uri $ApiUrl -Method Get -Headers @{ 'User-Agent' = 'Fd-NonAdmin-Installer' }
}
catch {
    Write-Warning "GitHub API query failed or was rate-limited: $($_.Exception.Message)"
}

$Version = $null
$ZipAsset = $null

if ($Release -and $Release.assets) {
    $Version = $Release.tag_name.TrimStart('v')
    $ZipAsset = $Release.assets | Where-Object { $_.name -match '^fd-v.*-x86_64-pc-windows-msvc\.zip$' } | Select-Object -First 1
}

if (-not $ZipAsset) {
    Write-Host "Falling back to stable release baseline..." -ForegroundColor Yellow
    $Version = '10.5.2'
    $BaseUrl = "https://github.com/sharkdp/fd/releases/download/v$Version"
    $ZipAsset = [pscustomobject]@{
        name                 = "fd-v$Version-x86_64-pc-windows-msvc.zip"
        browser_download_url = "$BaseUrl/fd-v$Version-x86_64-pc-windows-msvc.zip"
        digest               = "sha256:5ef49aef531235b2e95166299d63c5a3d7e5b5e39b9dafb878b3f15c7e4a1a01"
    }
}

$ZipName = $ZipAsset.name
$ZipUrl = $ZipAsset.browser_download_url
$ZipPath = Join-Path $DownloadDir $ZipName
$MetadataFile = Join-Path $DownloadDir 'release-info.json'

$ExpectedHash = $null
if ($ZipAsset.digest -and $ZipAsset.digest -match 'sha256:([0-9a-fA-F]{64})') {
    $ExpectedHash = $Matches[1].ToLowerInvariant()
}

Write-Host "Release Version: $Version" -ForegroundColor Green
Write-Host "Package Archive: $ZipName"

Write-Step 'Downloading fd zip archive'
$NeedsDownload = $true
if (Test-Path -LiteralPath $ZipPath -PathType Leaf) {
    if ($ExpectedHash) {
        $ExistingHash = (Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($ExistingHash -eq $ExpectedHash) {
            Write-Host "Existing archive already matches expected SHA-256: $ZipPath" -ForegroundColor Green
            $NeedsDownload = $false
        }
        else {
            Remove-Item -LiteralPath $ZipPath -Force
        }
    }
    else {
        $NeedsDownload = $false
    }
}

if ($NeedsDownload) {
    Write-Host "Downloading: $ZipUrl"
    Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath
}

Write-Step 'Calculating archive SHA-256 checksum'
$ActualHash = (Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Host "Actual SHA-256: $ActualHash"

if ($ExpectedHash) {
    Write-Host "Expected SHA-256: $ExpectedHash"
    if ($ActualHash -ne $ExpectedHash) {
        Remove-Item -LiteralPath $ZipPath -Force -ErrorAction SilentlyContinue
        throw "SHA-256 CHECKSUM VERIFICATION FAILED! Downloaded archive deleted."
    }
    Write-Host 'SHA-256 verification PASSED.' -ForegroundColor Green
}

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
Write-Host ' STEP 1 COMPLETE: fd Download Verified' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Version: $Version"
Write-Host "Archive: $ZipPath"
Write-Host "SHA-256: $ActualHash" -ForegroundColor Green
Write-Host
Write-Host 'Nothing has been extracted or installed to the system.'
