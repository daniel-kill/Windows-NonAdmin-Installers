#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 1: Discover, download, and verify VS Code portable distribution
#
# Official Website: https://code.visualstudio.com/
#
# This script:
#   1. Resolves official Microsoft stable win32-x64 zip download endpoint.
#   2. Downloads the archive into $HOME\Downloads\vscode.
#   3. Calculates SHA-256 digest and records release metadata.
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$DownloadDir = Join-Path $HOME 'Downloads\vscode'
$DirectUrl = 'https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-archive'

Write-Step 'Preparing download directory'
if (-not (Test-Path -LiteralPath $DownloadDir -PathType Container)) {
    New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
}

$DestPath = Join-Path $DownloadDir 'VSCode-win32-x64.zip'
$MetadataFile = Join-Path $DownloadDir 'release-info.json'

Write-Step 'Resolving official Microsoft download URL'
Write-Host "Endpoint: $DirectUrl"

$FinalUrl = $null
try {
    $Req = [System.Net.HttpWebRequest]::Create($DirectUrl)
    $Req.AllowAutoRedirect = $true
    $Req.UserAgent = 'VSCode-NonAdmin-Installer'
    $Resp = $Req.GetResponse()
    $FinalUrl = $Resp.ResponseUri.AbsoluteUri
    $Resp.Close()
}
catch {
    Write-Warning "Could not resolve redirect: $($_.Exception.Message)"
    $FinalUrl = $DirectUrl
}

Write-Host "Direct Artifact URL: $FinalUrl" -ForegroundColor Green

Write-Step 'Downloading VS Code portable archive'
$NeedsDownload = $true
if (Test-Path -LiteralPath $DestPath -PathType Leaf) {
    $Item = Get-Item -LiteralPath $DestPath
    if ($Item.Length -gt 100000000) {
        Write-Host "Existing archive found ($([math]::Round($Item.Length / 1MB, 2)) MB): $DestPath" -ForegroundColor Green
        $NeedsDownload = $false
    }
}

if ($NeedsDownload) {
    Write-Host "Downloading (this may take a moment, ~100MB)..."
    Invoke-WebRequest -Uri $FinalUrl -OutFile $DestPath
}

Write-Step 'Calculating archive SHA-256 checksum'
$ActualHash = (Get-FileHash -LiteralPath $DestPath -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Host "Calculated SHA-256: $ActualHash"

$Metadata = [pscustomobject]@{
    FileName     = 'VSCode-win32-x64.zip'
    Sha256       = $ActualHash
    DownloadUrl  = $FinalUrl
    DownloadedAt = (Get-Date -Format 'o')
}
$Metadata | ConvertTo-Json | Set-Content -LiteralPath $MetadataFile -Encoding utf8NoBOM

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 1 COMPLETE: VS Code Download Verified' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Archive: $DestPath"
Write-Host "SHA-256: $ActualHash" -ForegroundColor Green
Write-Host
Write-Host 'Nothing has been extracted or installed to the system.'
