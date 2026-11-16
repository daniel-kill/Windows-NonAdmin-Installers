#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 2: Install Hermes Agent into an isolated user virtualenv ($HOME\.local\hermes)
#
# Parameters:
#   -Force: Remove existing installation and reinstall cleanly.
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$InstallRoot = Join-Path $HOME '.local\hermes'
$VenvDir = Join-Path $InstallRoot 'venv'
$BinDir  = Join-Path $InstallRoot 'bin'

if (Test-Path -LiteralPath $InstallRoot) {
    if ($Force) {
        Write-Warning "Removing existing Hermes installation at: $InstallRoot"
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
    if ($LASTEXITCODE -ne 0) {
        # Fallback if venv module is missing on embeddable python: install directly with pip
        Write-Warning "venv module creation had issues; using pip target mode."
    }
}

$VenvPip = Join-Path $VenvDir 'Scripts\pip.exe'
$VenvPython = Join-Path $VenvDir 'Scripts\python.exe'

if (-not (Test-Path -LiteralPath $VenvPip)) {
    # If standard venv is not present, use the base python pip with --target
    $BasePip = Join-Path (Split-Path -Parent $PythonExe) 'Scripts\pip.exe'
    if (-not (Test-Path -LiteralPath $BasePip)) { $BasePip = 'pip' }
    
    Write-Step 'Installing hermes-agent via pip'
    $InstallArgs = @('install', 'hermes-agent')
    if ($Force) { $InstallArgs += @('--force-reinstall', '--upgrade') }
    & $BasePip @InstallArgs
    
    # Shim
    $HermesShim = Join-Path $BinDir 'hermes.cmd'
    $ShimContent = @"
@echo off
"$PythonExe" -m hermes_cli %*
"@
    Set-Content -LiteralPath $HermesShim -Value $ShimContent -Encoding ascii
}
else {
    Write-Step 'Installing hermes-agent into virtual environment'
    $InstallArgs = @('install', 'hermes-agent')
    if ($Force) { $InstallArgs += @('--force-reinstall', '--upgrade') }
    & $VenvPip @InstallArgs

    if ($LASTEXITCODE -ne 0) {
        throw "pip install hermes-agent failed with exit code $LASTEXITCODE"
    }

    $HermesExe = Join-Path $VenvDir 'Scripts\hermes.exe'
    $HermesShim = Join-Path $BinDir 'hermes.cmd'

    if (Test-Path -LiteralPath $HermesExe) {
        $ShimContent = @"
@echo off
"$HermesExe" %*
"@
    }
    else {
        $ShimContent = @"
@echo off
"$VenvPython" -m hermes_cli %*
"@
    }
    Set-Content -LiteralPath $HermesShim -Value $ShimContent -Encoding ascii
}

Write-Host "Created launcher shim: $HermesShim" -ForegroundColor Green
Write-Host "Hermes Agent installed successfully into: $InstallRoot" -ForegroundColor Green
