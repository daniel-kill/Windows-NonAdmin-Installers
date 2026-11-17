#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 2: Extract and install Scoop into user directory
#
# Target: $HOME\scoop
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$InstallDir = if ($env:SCOOP) { $env:SCOOP } else { Join-Path $HOME 'scoop' }
$AppsDir = Join-Path $InstallDir 'apps\scoop\current'
$ShimDir = Join-Path $InstallDir 'shims'
$ScoopShimPs1 = Join-Path $ShimDir 'scoop.ps1'
$ScoopShimCmd = Join-Path $ShimDir 'scoop.cmd'
$DownloadDir = Join-Path $HOME 'Downloads\scoop'
$MetadataFile = Join-Path $DownloadDir 'release-info.json'

if (-not (Test-Path -LiteralPath $MetadataFile -PathType Leaf)) {
    throw "Metadata file missing at '$MetadataFile'. Run 01-download-scoop.ps1 first."
}

$Metadata = Get-Content -LiteralPath $MetadataFile -Raw | ConvertFrom-Json
$ZipPath = $Metadata.archive_path

if (-not (Test-Path -LiteralPath $ZipPath -PathType Leaf)) {
    throw "Archive not found at '$ZipPath'. Re-run 01-download-scoop.ps1."
}

Write-Step "Checking destination directory: $InstallDir"
if (Test-Path -LiteralPath $ScoopShimPs1 -PathType Leaf) {
    if (-not $Force) {
        Write-Host "Scoop is already installed at $ScoopShimPs1." -ForegroundColor Green
        Write-Host "Use -Force to reinstall." -ForegroundColor Yellow
        exit 0
    }
    Write-Host "Force reinstall requested. Cleaning up existing installation..." -ForegroundColor Yellow
    Remove-Item -LiteralPath $InstallDir -Recurse -Force
}

New-Item -ItemType Directory -Path $AppsDir -Force | Out-Null
New-Item -ItemType Directory -Path $ShimDir -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $InstallDir 'buckets') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $InstallDir 'cache') -Force | Out-Null

$TempExtractDir = Join-Path $DownloadDir "temp_extract_$PID"
if (Test-Path -LiteralPath $TempExtractDir) {
    Remove-Item -LiteralPath $TempExtractDir -Recurse -Force
}
New-Item -ItemType Directory -Path $TempExtractDir -Force | Out-Null

Write-Step "Extracting Scoop release archive: $ZipPath"
$SevenZipExe = Join-Path $HOME '.local\7zip\7z.exe'

if (Test-Path -LiteralPath $SevenZipExe -PathType Leaf) {
    Write-Host "Extracting via local 7z: $SevenZipExe"
    & $SevenZipExe x $ZipPath "-o$TempExtractDir" -y | Out-Null
}
elseif (Get-Command 'tar' -ErrorAction SilentlyContinue) {
    Write-Host "Extracting via native tar..."
    tar -xf $ZipPath -C $TempExtractDir
}
else {
    Write-Host "Extracting via .NET ZipFile..."
    [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $TempExtractDir)
}

$ExtractedRoot = Get-ChildItem -LiteralPath $TempExtractDir -Directory | Select-Object -First 1
if (-not $ExtractedRoot) {
    throw "Failed to locate extracted Scoop root folder inside $TempExtractDir"
}

Write-Step "Deploying Scoop core application to $AppsDir"
Copy-Item -Path (Join-Path $ExtractedRoot.FullName '*') -Destination $AppsDir -Recurse -Force
Remove-Item -LiteralPath $TempExtractDir -Recurse -Force

Write-Step "Generating command shims in $ShimDir"
# PowerShell shim
$Ps1Content = @'
& "$PSScriptRoot\..\apps\scoop\current\bin\scoop.ps1" @args
'@
$Ps1Content | Set-Content -LiteralPath $ScoopShimPs1 -Encoding utf8

# Batch/CMD shim
$CmdContent = @'
@echo off
pwsh -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0..\apps\scoop\current\bin\scoop.ps1' %*"
'@
$CmdContent | Set-Content -LiteralPath $ScoopShimCmd -Encoding utf8

# Posix/Git Bash shim
$ShContent = @'
#!/usr/bin/env sh
exec pwsh -NoProfile -ExecutionPolicy Bypass -Command "& '$HOME/scoop/apps/scoop/current/bin/scoop.ps1' \"\$@\""
'@
$ShContent | Set-Content -LiteralPath (Join-Path $ShimDir 'scoop') -Encoding utf8

if (-not (Test-Path -LiteralPath $ScoopShimPs1 -PathType Leaf)) {
    throw "Scoop shim not found after installation: $ScoopShimPs1"
}

Write-Host "✓ Scoop core engine and shims deployed successfully to: $ShimDir" -ForegroundColor Green
