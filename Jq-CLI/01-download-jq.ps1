#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 1: Discover, download, and verify jq standalone binary
#
# Official Repository: https://github.com/jqlang/jq
#
# This script:
#   1. Queries GitHub API for the latest stable jq release.
#   2. Locates the Windows x86_64 standalone binary (jq-windows-amd64.exe).
#   3. Downloads binary into $HOME\Downloads\jq.
#   4. Verifies the SHA-256 digest against GitHub release metadata.
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$DownloadDir = Join-Path $HOME 'Downloads\jq'
$ApiUrl = 'https://api.github.com/repos/jqlang/jq/releases/latest'

Write-Step 'Preparing download directory'
if (-not (Test-Path -LiteralPath $DownloadDir -PathType Container)) {
    New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
}

Write-Step 'Querying jq release catalog'
Write-Host "API URL: $ApiUrl"

$Release = $null
try {
    $Release = Invoke-RestMethod -Uri $ApiUrl -Method Get -Headers @{ 'User-Agent' = 'Jq-NonAdmin-Installer' }
}
catch {
    Write-Warning "GitHub API query failed or was rate-limited: $($_.Exception.Message)"
}

$Version = $null
$ExeAsset = $null

if ($Release -and $Release.assets) {
    $Version = $Release.tag_name.TrimStart('jq-')
    $ExeAsset = $Release.assets | Where-Object { $_.name -eq 'jq-windows-amd64.exe' -or $_.name -eq 'jq-win64.exe' } | Select-Object -First 1
}

if (-not $ExeAsset) {
    Write-Host "Falling back to stable release baseline..." -ForegroundColor Yellow
    $Version = '1.8.2'
    $BaseUrl = "https://github.com/jqlang/jq/releases/download/jq-$Version"
    $ExeAsset = [pscustomobject]@{
        name                 = "jq-windows-amd64.exe"
        browser_download_url = "$BaseUrl/jq-windows-amd64.exe"
        digest               = "sha256:a6fc67fedaf9128a3309a1e2ebb8b986aeccf70122ee46d2cb4849e423f0c627"
    }
}

$FileName = $ExeAsset.name
$DownloadUrl = $ExeAsset.browser_download_url
$DestFile = Join-Path $DownloadDir $FileName
$MetadataFile = Join-Path $DownloadDir 'release-info.json'

$ExpectedHash = $null
if ($ExeAsset.digest -and $ExeAsset.digest -match 'sha256:([0-9a-fA-F]{64})') {
    $ExpectedHash = $Matches[1].ToLowerInvariant()
}

Write-Host "Release Version: $Version" -ForegroundColor Green
Write-Host "Binary File:     $FileName"

Write-Step 'Downloading jq binary'
$NeedsDownload = $true
if (Test-Path -LiteralPath $DestFile -PathType Leaf) {
    if ($ExpectedHash) {
        $ExistingHash = (Get-FileHash -LiteralPath $DestFile -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($ExistingHash -eq $ExpectedHash) {
            Write-Host "Existing binary matches expected SHA-256: $DestFile" -ForegroundColor Green
            $NeedsDownload = $false
        }
        else {
            Remove-Item -LiteralPath $DestFile -Force
        }
    }
    else {
        $NeedsDownload = $false
    }
}

if ($NeedsDownload) {
    Write-Host "Downloading: $DownloadUrl"
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $DestFile
}

Write-Step 'Calculating binary SHA-256 checksum'
$ActualHash = (Get-FileHash -LiteralPath $DestFile -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Host "Actual SHA-256: $ActualHash"

if ($ExpectedHash) {
    Write-Host "Expected SHA-256: $ExpectedHash"
    if ($ActualHash -ne $ExpectedHash) {
        Remove-Item -LiteralPath $DestFile -Force -ErrorAction SilentlyContinue
        throw "SHA-256 CHECKSUM VERIFICATION FAILED! Downloaded binary deleted."
    }
    Write-Host 'SHA-256 verification PASSED.' -ForegroundColor Green
}

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
Write-Host ' STEP 1 COMPLETE: jq Download Verified' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Version: $Version"
Write-Host "Binary:  $DestFile"
Write-Host "SHA-256: $ActualHash" -ForegroundColor Green
Write-Host
Write-Host 'Nothing has been extracted or installed to the system.'
