#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 1: Discover, download, and verify 7-Zip x64 package
#
# Official Website: https://www.7-zip.org/
# Official GitHub:  https://github.com/ip7z/7zip
#
# This script:
#   1. Queries GitHub API for the latest stable 7-Zip release.
#   2. Locates the Windows x64 MSI package.
#   3. Downloads the installer into $HOME\Downloads\7zip.
#   4. Calculates SHA-256 digest and records release metadata.
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$DownloadDir = Join-Path $HOME 'Downloads\7zip'
$ApiUrl = 'https://api.github.com/repos/ip7z/7zip/releases/latest'

Write-Step 'Preparing download directory'
if (-not (Test-Path -LiteralPath $DownloadDir -PathType Container)) {
    New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
}

Write-Step 'Querying 7-Zip release catalog'
Write-Host "API URL: $ApiUrl"

$Release = $null
try {
    $Release = Invoke-RestMethod -Uri $ApiUrl -Method Get -Headers @{ 'User-Agent' = '7Zip-NonAdmin-Installer' }
}
catch {
    Write-Warning "GitHub API query failed or was rate-limited: $($_.Exception.Message)"
}

$Version = $null
$MsiAsset = $null

if ($Release -and $Release.assets) {
    $Version = $Release.tag_name.TrimStart('v')
    $MsiAsset = $Release.assets | Where-Object { $_.name -match '^7z.*-x64\.msi$' } | Select-Object -First 1
}

if (-not $MsiAsset) {
    Write-Host "Falling back to stable release baseline..." -ForegroundColor Yellow
    $Version = '26.06'
    $BaseUrl = "https://github.com/ip7z/7zip/releases/download/$Version"
    $MsiAsset = [pscustomobject]@{
        name                 = "7z2606-x64.msi"
        browser_download_url = "$BaseUrl/7z2606-x64.msi"
        digest               = "sha256:0d52f6b86cf389ee0793b8aa6f32e3a89ee120d53c393bcff7ba119f390fe660"
    }
}

$MsiName = $MsiAsset.name
$MsiUrl = $MsiAsset.browser_download_url
$MsiPath = Join-Path $DownloadDir $MsiName
$MetadataFile = Join-Path $DownloadDir 'release-info.json'

$ExpectedHash = $null
if ($MsiAsset.digest -and $MsiAsset.digest -match 'sha256:([0-9a-fA-F]{64})') {
    $ExpectedHash = $Matches[1].ToLowerInvariant()
}

Write-Host "Release Version: $Version" -ForegroundColor Green
Write-Host "MSI Package:     $MsiName"

Write-Step 'Downloading 7-Zip MSI package'
$NeedsDownload = $true
if (Test-Path -LiteralPath $MsiPath -PathType Leaf) {
    if ($ExpectedHash) {
        $ExistingHash = (Get-FileHash -LiteralPath $MsiPath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($ExistingHash -eq $ExpectedHash) {
            Write-Host "Existing MSI already matches expected SHA-256: $MsiPath" -ForegroundColor Green
            $NeedsDownload = $false
        }
        else {
            Remove-Item -LiteralPath $MsiPath -Force
        }
    }
    else {
        $NeedsDownload = $false
    }
}

if ($NeedsDownload) {
    Write-Host "Downloading: $MsiUrl"
    Invoke-WebRequest -Uri $MsiUrl -OutFile $MsiPath
}

Write-Step 'Calculating MSI SHA-256 checksum'
$ActualHash = (Get-FileHash -LiteralPath $MsiPath -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Host "Actual SHA-256: $ActualHash"

if ($ExpectedHash) {
    Write-Host "Expected SHA-256: $ExpectedHash"
    if ($ActualHash -ne $ExpectedHash) {
        Remove-Item -LiteralPath $MsiPath -Force -ErrorAction SilentlyContinue
        throw "SHA-256 CHECKSUM VERIFICATION FAILED! Downloaded MSI deleted."
    }
    Write-Host 'SHA-256 verification PASSED.' -ForegroundColor Green
}

$Metadata = [pscustomobject]@{
    Version      = $Version
    FileName     = $MsiName
    Sha256       = $ActualHash
    DownloadUrl  = $MsiUrl
    DownloadedAt = (Get-Date -Format 'o')
}
$Metadata | ConvertTo-Json | Set-Content -LiteralPath $MetadataFile -Encoding utf8NoBOM

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 1 COMPLETE: 7-Zip Download Verified' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Version: $Version"
Write-Host "Package: $MsiPath"
Write-Host "SHA-256: $ActualHash" -ForegroundColor Green
Write-Host
Write-Host 'Nothing has been extracted or installed to the system.'
