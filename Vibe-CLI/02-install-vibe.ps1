#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 2: Install Mistral Vibe into an isolated user virtualenv ($HOME\.local\vibe)
#
# Parameters:
#   -Force: Remove existing installation and reinstall cleanly.
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$InstallRoot = Join-Path $HOME '.local\vibe'
$VenvDir = Join-Path $InstallRoot 'venv'
$BinDir  = Join-Path $InstallRoot 'bin'

if (Test-Path -LiteralPath $InstallRoot) {
    if ($Force) {
        Write-Warning "Removing existing Vibe installation at: $InstallRoot"
        Remove-Item -LiteralPath $InstallRoot -Recurse -Force
    }
}

if (-not (Test-Path -LiteralPath $BinDir)) {
    New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
}

$LocalPythonExe = Join-Path $HOME '.local\python\python.exe'
$PythonExe = if (Test-Path -LiteralPath $LocalPythonExe) {
    $LocalPythonExe
} else {
    $cmd = Get-Command python.exe -ErrorAction SilentlyContinue
    if (-not $cmd) { $cmd = Get-Command python -ErrorAction SilentlyContinue }
    if ($cmd) { $cmd.Source } else { throw 'Python not found.' }
}

Write-Step "Creating isolated virtual environment under $VenvDir"

if (-not (Test-Path -LiteralPath $VenvDir)) {
    & $PythonExe -m venv $VenvDir
}

$VenvPip = Join-Path $VenvDir 'Scripts\pip.exe'
$VenvPython = Join-Path $VenvDir 'Scripts\python.exe'

if (-not (Test-Path -LiteralPath $VenvPip)) {
    # Fallback to base python pip
    $BasePip = Join-Path (Split-Path -Parent $PythonExe) 'Scripts\pip.exe'
    if (-not (Test-Path -LiteralPath $BasePip)) { $BasePip = 'pip' }
    
    Write-Step 'Installing mistral-vibe via pip'
    $InstallArgs = @('install', 'mistral-vibe')
    if ($Force) { $InstallArgs += @('--force-reinstall', '--upgrade') }
    & $BasePip @InstallArgs
    
    $VibeShim = Join-Path $BinDir 'vibe.cmd'
    $ShimContent = @"
@echo off
"$PythonExe" -m vibe %*
"@
    Set-Content -LiteralPath $VibeShim -Value $ShimContent -Encoding ascii
}
else {
    Write-Step 'Installing mistral-vibe into virtual environment'
    $InstallArgs = @('install', 'mistral-vibe')
    if ($Force) { $InstallArgs += @('--force-reinstall', '--upgrade') }
    & $VenvPip @InstallArgs

    if ($LASTEXITCODE -ne 0) {
        throw "pip install mistral-vibe failed with exit code $LASTEXITCODE"
    }

    $VibeExe = Join-Path $VenvDir 'Scripts\vibe.exe'
    $VibeShim = Join-Path $BinDir 'vibe.cmd'

    if (Test-Path -LiteralPath $VibeExe) {
        $ShimContent = @"
@echo off
"$VibeExe" %*
"@
    }
    else {
        $ShimContent = @"
@echo off
"$VenvPython" -m vibe %*
"@
    }
    Set-Content -LiteralPath $VibeShim -Value $ShimContent -Encoding ascii
}

Write-Host "Created launcher shim: $VibeShim" -ForegroundColor Green
Write-Host "Mistral Vibe installed successfully into: $InstallRoot" -ForegroundColor Green
