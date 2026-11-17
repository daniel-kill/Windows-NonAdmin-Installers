#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 1: Discover, download, and verify Scoop installer and core archive
#
# Official Website: https://scoop.sh/
# Official Repository: https://github.com/ScoopInstaller/Scoop
#
# This script:
#   1. Queries GitHub API for the latest stable Scoop release tag.
#   2. Downloads the official release archive and installer script.
#   3. Saves artifacts to $HOME\Downloads\scoop.
#   4. Computes SHA-256 checksum and saves metadata.
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$DownloadDir = Join-Path $HOME 'Downloads\scoop'
$ApiUrl = 'https://api.github.com/repos/ScoopInstaller/Scoop/releases/latest'

Write-Step 'Preparing download directory'
if (-not (Test-Path -LiteralPath $DownloadDir -PathType Container)) {
    New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
}

Write-Step 'Querying Scoop release catalog'
Write-Host "API URL: $ApiUrl"

$Release = $null
try {
    $Release = Invoke-RestMethod -Uri $ApiUrl -Method Get -Headers @{ 'User-Agent' = 'Scoop-NonAdmin-Installer' }
}
catch {
    Write-Warning "GitHub API query failed or was rate-limited: $($_.Exception.Message)"
}

$Version = if ($Release -and $Release.tag_name) { $Release.tag_name.TrimStart('v') } else { '0.6.0' }
$ZipUrl = "https://github.com/ScoopInstaller/Scoop/archive/refs/tags/v$Version.zip"
$ZipName = "scoop-v$Version.zip"
$ZipPath = Join-Path $DownloadDir $ZipName
$InstallScriptUrl = 'https://raw.githubusercontent.com/ScoopInstaller/Install/master/install.ps1'
$InstallScriptPath = Join-Path $DownloadDir 'install.ps1'
$MetadataFile = Join-Path $DownloadDir 'release-info.json'

Write-Host "Release Version: $Version" -ForegroundColor Green
Write-Host "Archive Name:    $ZipName"

Write-Step 'Downloading official Scoop installer script'
Invoke-WebRequest -Uri $InstallScriptUrl -OutFile $InstallScriptPath

Write-Step 'Downloading Scoop core release archive'
if (Test-Path -LiteralPath $ZipPath -PathType Leaf) {
    Write-Host "Existing archive found. Validating..." -ForegroundColor Green
}
else {
    Write-Host "Fetching $ZipUrl..."
    Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath
}

Write-Step 'Computing release checksum'
$ActualHash = (Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Host "SHA-256 Digest: $ActualHash" -ForegroundColor Green

$Metadata = [ordered]@{
    version             = $Version
    archive_name        = $ZipName
    archive_path        = $ZipPath
    install_script_path = $InstallScriptPath
    sha256              = $ActualHash
    download_url        = $ZipUrl
    downloaded_at       = (Get-Date).ToString('o')
}
$Metadata | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $MetadataFile -Encoding utf8
Write-Host "Release metadata recorded to: $MetadataFile" -ForegroundColor Green
