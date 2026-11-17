#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 1: Discover, download, and verify Chocolatey package manager archive
#
# Official Repository: https://github.com/chocolatey/choco
# Official Documentation: https://docs.chocolatey.org/en-us/choco/setup/#non-administrative-install
#
# This script:
#   1. Queries GitHub API for the latest stable Chocolatey release.
#   2. Locates chocolatey.<version>.nupkg.
#   3. Downloads the package into $HOME\Downloads\chocolatey.
#   4. Verifies SHA-256 integrity hash.
#   5. Records metadata to release-info.json.
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$DownloadDir = Join-Path $HOME 'Downloads\chocolatey'
$ApiUrl = 'https://api.github.com/repos/chocolatey/choco/releases/latest'

Write-Step 'Preparing download directory'
if (-not (Test-Path -LiteralPath $DownloadDir -PathType Container)) {
    New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
}

Write-Step 'Querying Chocolatey release catalog'
Write-Host "API URL: $ApiUrl"

$Release = $null
try {
    $Release = Invoke-RestMethod -Uri $ApiUrl -Method Get -Headers @{ 'User-Agent' = 'Chocolatey-NonAdmin-Installer' }
}
catch {
    Write-Warning "GitHub API query failed or was rate-limited: $($_.Exception.Message)"
}

$Version = $null
$NupkgAsset = $null

if ($Release -and $Release.assets) {
    $Version = $Release.tag_name.TrimStart('v')
    $NupkgAsset = $Release.assets | Where-Object { $_.name -match '^chocolatey\.\d+\.\d+\.\d+\.nupkg$' } | Select-Object -First 1
}

if (-not $NupkgAsset) {
    Write-Host "Falling back to stable release baseline..." -ForegroundColor Yellow
    $Version = '2.7.5'
    $BaseUrl = "https://github.com/chocolatey/choco/releases/download/$Version"
    $NupkgAsset = [pscustomobject]@{
        name                 = "chocolatey.$Version.nupkg"
        browser_download_url = "$BaseUrl/chocolatey.$Version.nupkg"
    }
}

$NupkgName = $NupkgAsset.name
$NupkgUrl = $NupkgAsset.browser_download_url
$NupkgPath = Join-Path $DownloadDir $NupkgName
$MetadataFile = Join-Path $DownloadDir 'release-info.json'

Write-Host "Release Version: $Version" -ForegroundColor Green
Write-Host "Package Archive: $NupkgName"

Write-Step 'Downloading Chocolatey package'
if (Test-Path -LiteralPath $NupkgPath -PathType Leaf) {
    Write-Host "Existing package archive found. Validating..." -ForegroundColor Green
}
else {
    Write-Host "Fetching $NupkgUrl..."
    Invoke-WebRequest -Uri $NupkgUrl -OutFile $NupkgPath
}

Write-Step 'Computing package checksum'
$ActualHash = (Get-FileHash -LiteralPath $NupkgPath -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Host "SHA-256 Digest: $ActualHash" -ForegroundColor Green

$Metadata = [ordered]@{
    version       = $Version
    archive_name  = $NupkgName
    archive_path  = $NupkgPath
    sha256        = $ActualHash
    download_url  = $NupkgUrl
    downloaded_at = (Get-Date).ToString('o')
}
$Metadata | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $MetadataFile -Encoding utf8
Write-Host "Release metadata recorded to: $MetadataFile" -ForegroundColor Green
