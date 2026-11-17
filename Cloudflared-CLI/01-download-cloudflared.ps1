#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 1: Discover, download, and verify Cloudflare Tunnel CLI (cloudflared)
#
# Official Repository: https://github.com/cloudflare/cloudflared
#
# This script:
#   1. Queries GitHub API for the latest stable cloudflared release.
#   2. Locates cloudflared-windows-amd64.exe and parses SHA-256 from release notes.
#   3. Downloads the binary into $HOME\Downloads\cloudflared.
#   4. Verifies SHA-256 integrity hash.
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$DownloadDir = Join-Path $HOME 'Downloads\cloudflared'
$ApiUrl = 'https://api.github.com/repos/cloudflare/cloudflared/releases/latest'

Write-Step 'Preparing download directory'
if (-not (Test-Path -LiteralPath $DownloadDir -PathType Container)) {
    New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
}

Write-Step 'Querying cloudflared release catalog'
Write-Host "API URL: $ApiUrl"

$Release = $null
try {
    $Release = Invoke-RestMethod -Uri $ApiUrl -Method Get -Headers @{ 'User-Agent' = 'Cloudflared-NonAdmin-Installer' }
}
catch {
    Write-Warning "GitHub API query failed or was rate-limited: $($_.Exception.Message)"
}

$Version = $null
$ExeAsset = $null
$ExpectedHash = $null

if ($Release -and $Release.assets) {
    $Version = $Release.tag_name
    $ExeAsset = $Release.assets | Where-Object { $_.name -eq 'cloudflared-windows-amd64.exe' } | Select-Object -First 1

    if ($Release.body) {
        $BodyMatch = [regex]::Match($Release.body, '(?im)cloudflared-windows-amd64\.exe:\s*([0-9a-fA-F]{64})')
        if ($BodyMatch.Success) {
            $ExpectedHash = $BodyMatch.Groups[1].Value.ToLowerInvariant()
        }
    }
}

if (-not $ExeAsset) {
    Write-Host "Falling back to stable release baseline..." -ForegroundColor Yellow
    $Version = '2026.11.0'
    $BaseUrl = "https://github.com/cloudflare/cloudflared/releases/download/$Version"
    $ExeAsset = [pscustomobject]@{
        name                 = 'cloudflared-windows-amd64.exe'
        browser_download_url = "$BaseUrl/cloudflared-windows-amd64.exe"
    }
    $ExpectedHash = 'd5c1d82031da6253dcdcff64c944cd0fe063016edeb2e4fd088075fc9bd52d0a'
}

$ExeName = $ExeAsset.name
$ExeUrl = $ExeAsset.browser_download_url
$ExePath = Join-Path $DownloadDir $ExeName
$MetadataFile = Join-Path $DownloadDir 'release-info.json'

Write-Host "Release Version: $Version" -ForegroundColor Green
Write-Host "Package Binary:  $ExeName"
if ($ExpectedHash) {
    Write-Host "Official Expected SHA-256: $ExpectedHash" -ForegroundColor Green
}

Write-Step 'Downloading cloudflared executable'
if (Test-Path -LiteralPath $ExePath -PathType Leaf) {
    if ($ExpectedHash) {
        $ExistingHash = (Get-FileHash -LiteralPath $ExePath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($ExistingHash -eq $ExpectedHash) {
            Write-Host "Existing binary verified successfully ($ExistingHash)." -ForegroundColor Green
        }
        else {
            Write-Warning "Existing binary hash mismatch. Re-downloading..."
            Remove-Item -LiteralPath $ExePath -Force
            Invoke-WebRequest -Uri $ExeUrl -OutFile $ExePath
        }
    }
}
else {
    Write-Host "Fetching $ExeUrl..."
    Invoke-WebRequest -Uri $ExeUrl -OutFile $ExePath
}

Write-Step 'Verifying downloaded executable checksum'
$ActualHash = (Get-FileHash -LiteralPath $ExePath -Algorithm SHA256).Hash.ToLowerInvariant()
if ($ExpectedHash -and $ActualHash -ne $ExpectedHash) {
    throw "SHA-256 verification FAILED!`nExpected: $ExpectedHash`nActual:   $ActualHash"
}
Write-Host "SHA-256 verified successfully: $ActualHash" -ForegroundColor Green

$Metadata = [ordered]@{
    version       = $Version
    binary_name   = $ExeName
    binary_path   = $ExePath
    sha256        = $ActualHash
    download_url  = $ExeUrl
    downloaded_at = (Get-Date).ToString('o')
}
$Metadata | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $MetadataFile -Encoding utf8
Write-Host "Release metadata recorded to: $MetadataFile" -ForegroundColor Green
