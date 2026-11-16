#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 1: Download and verify Google Antigravity CLI native Windows binary
#
# Downloads:
#   1. Release manifest from https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/windows_amd64.json
#   2. Binary cli_windows_x64.exe
#   3. Verifies SHA-512 checksum against manifest
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$DownloadDir = Join-Path $HOME 'Downloads\Antigravity'
$ManifestUrl = 'https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/windows_amd64.json'

Write-Step 'Preparing download directory'
if (-not (Test-Path -LiteralPath $DownloadDir)) {
    New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
}

Write-Step 'Fetching Antigravity CLI release manifest'
Write-Host "URL: $ManifestUrl"
$Manifest = Invoke-RestMethod -Uri $ManifestUrl -Method Get

if (-not $Manifest -or -not $Manifest.url -or -not $Manifest.sha512) {
    throw "Invalid or missing manifest response from: $ManifestUrl"
}

$Version = $Manifest.version
$BinaryUrl = $Manifest.url
$ExpectedSha512 = $Manifest.sha512.ToLowerInvariant()
$BinaryFileName = 'agy_download.exe'
$BinaryDest = Join-Path $DownloadDir $BinaryFileName

Write-Host "Latest Version: $Version" -ForegroundColor Green
Write-Host "Binary URL:     $BinaryUrl"
Write-Host "Expected SHA-512: $ExpectedSha512"

Write-Step 'Downloading Antigravity CLI binary'
Invoke-WebRequest -Uri $BinaryUrl -OutFile $BinaryDest

if (-not (Test-Path -LiteralPath $BinaryDest -PathType Leaf)) {
    throw "Failed to download Antigravity CLI binary: $BinaryDest"
}

Write-Step 'Verifying SHA-512 checksum'
$ActualSha512 = (Get-FileHash -LiteralPath $BinaryDest -Algorithm SHA512).Hash.ToLowerInvariant()

Write-Host "Expected: $ExpectedSha512"
Write-Host "Actual:   $ActualSha512"

if ($ActualSha512 -ne $ExpectedSha512) {
    Remove-Item -LiteralPath $BinaryDest -Force -ErrorAction SilentlyContinue
    throw "SHA-512 CHECKSUM VERIFICATION FAILED! Corrupt binary deleted."
}

Write-Host "SHA-512 checksum verification PASSED." -ForegroundColor Green

$Metadata = [pscustomobject]@{
    Version      = $Version
    FileName     = $BinaryFileName
    Sha512       = $ActualSha512
    DownloadUrl  = $BinaryUrl
    DownloadedAt = (Get-Date -Format 'o')
}
$Metadata | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $DownloadDir 'release-info.json') -Encoding utf8NoBOM

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 1 COMPLETE: Antigravity CLI Download Verified' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
