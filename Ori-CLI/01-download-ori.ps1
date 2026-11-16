#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 1: Download and verify OpenRouter Ori CLI native Windows binary
#
# Downloads:
#   1. SHA256SUMS from https://github.com/OpenRouterLabs/ori-releases/releases/latest/download/SHA256SUMS
#   2. ori-windows-x64.exe
#   3. Verifies SHA-256 against SHA256SUMS
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$DownloadDir = Join-Path $HOME 'Downloads\Ori'
$ReleaseBase = 'https://github.com/OpenRouterLabs/ori-releases/releases/latest/download'
$ChecksumUrl = "$ReleaseBase/SHA256SUMS"
$BinaryFileName = 'ori-windows-x64.exe'
$BinaryUrl = "$ReleaseBase/$BinaryFileName"

Write-Step 'Preparing download directory'
if (-not (Test-Path -LiteralPath $DownloadDir)) {
    New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
}

$ChecksumDest = Join-Path $DownloadDir 'SHA256SUMS'
$BinaryDest = Join-Path $DownloadDir $BinaryFileName

Write-Step 'Downloading SHA256SUMS'
Write-Host "URL: $ChecksumUrl"
Invoke-WebRequest -Uri $ChecksumUrl -OutFile $ChecksumDest

if (-not (Test-Path -LiteralPath $ChecksumDest -PathType Leaf)) {
    throw "Failed to download SHA256SUMS"
}

$ChecksumsText = Get-Content -LiteralPath $ChecksumDest -Raw
$Regex = "(?im)^([0-9a-f]{64})\s+(" + [regex]::Escape($BinaryFileName) + ")$"
$Match = [regex]::Match($ChecksumsText, $Regex)

if (-not $Match.Success) {
    throw "Could not find checksum for $BinaryFileName in $ChecksumDest"
}

$ExpectedHash = $Match.Groups[1].Value.ToLowerInvariant()
Write-Host "Expected SHA-256 for $BinaryFileName`: $ExpectedHash"

Write-Step 'Downloading ori-windows-x64.exe'
Write-Host "URL: $BinaryUrl"
Invoke-WebRequest -Uri $BinaryUrl -OutFile $BinaryDest

if (-not (Test-Path -LiteralPath $BinaryDest -PathType Leaf)) {
    throw "Failed to download binary: $BinaryDest"
}

Write-Step 'Verifying SHA-256 checksum'
$ActualHash = (Get-FileHash -LiteralPath $BinaryDest -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Host "Expected: $ExpectedHash"
Write-Host "Actual:   $ActualHash"

if ($ActualHash -ne $ExpectedHash) {
    Remove-Item -LiteralPath $BinaryDest -Force -ErrorAction SilentlyContinue
    throw "SHA-256 CHECKSUM VERIFICATION FAILED! Corrupt binary deleted."
}

Write-Host "SHA-256 checksum verification PASSED." -ForegroundColor Green

$Metadata = [pscustomobject]@{
    FileName     = $BinaryFileName
    Sha256       = $ActualHash
    DownloadUrl  = $BinaryUrl
    DownloadedAt = (Get-Date -Format 'o')
}
$Metadata | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $DownloadDir 'release-info.json') -Encoding utf8NoBOM

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 1 COMPLETE: Ori Binary Download Verified' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
