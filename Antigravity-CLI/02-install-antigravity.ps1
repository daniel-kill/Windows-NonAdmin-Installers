#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 2: Install Antigravity CLI into user space ($HOME\.local\antigravity\bin\agy.exe)
#
# Parameters:
#   -Force: Overwrite existing binary.
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$DownloadDir = Join-Path $HOME 'Downloads\Antigravity'
$InstallRoot = Join-Path $HOME '.local\antigravity'
$BinDir = Join-Path $InstallRoot 'bin'
$TargetExe = Join-Path $BinDir 'agy.exe'

Write-Step 'Checking target installation directory'

if (Test-Path -LiteralPath $TargetExe) {
    if ($Force) {
        Write-Warning "Removing existing binary: $TargetExe"
        Remove-Item -LiteralPath $TargetExe -Force
    }
    else {
        throw "Antigravity CLI is already installed at $TargetExe. Use -Force to reinstall."
    }
}

if (-not (Test-Path -LiteralPath $BinDir)) {
    New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
}

$MetadataFile = Join-Path $DownloadDir 'release-info.json'
if (-not (Test-Path -LiteralPath $MetadataFile)) {
    throw "Metadata file missing. Run 01-download-antigravity.ps1 first."
}

$Metadata = Get-Content -LiteralPath $MetadataFile -Raw | ConvertFrom-Json
$SourceBinary = Join-Path $DownloadDir $Metadata.FileName

if (-not (Test-Path -LiteralPath $SourceBinary)) {
    throw "Source binary missing: $SourceBinary. Run 01-download-antigravity.ps1 first."
}

Write-Step 'Re-verifying binary SHA-512'
$ActualSha512 = (Get-FileHash -LiteralPath $SourceBinary -Algorithm SHA512).Hash.ToLowerInvariant()
if ($ActualSha512 -ne $Metadata.Sha512.ToLowerInvariant()) {
    throw "SHA-512 mismatch before installation!"
}

Write-Step "Installing Antigravity CLI binary to $TargetExe"
Copy-Item -LiteralPath $SourceBinary -Destination $TargetExe -Force

Write-Host "Verifying binary execution..."
$VersionOutput = & $TargetExe --version
Write-Host "Antigravity CLI Version: $VersionOutput" -ForegroundColor Green

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 2 COMPLETE: Antigravity CLI Installed' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
