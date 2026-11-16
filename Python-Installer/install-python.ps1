#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# =============================================================================
# Primary Python Installation Orchestrator
#
# Runs all 3 installation steps in sequence:
#   1. Discover, download, and verify latest Python 64-bit embed archive & get-pip.py.
#   2. Extract to $HOME\.local\python, enable site-packages, and bootstrap pip.
#   3. Configure persistent user PATH and verify runtime execution.
#
# Parameters:
#   -Force: Remove existing Python installation at $HOME\.local\python and reinstall.
#
# This script DOES NOT:
#   - Require administrator privileges.
#   - Modify the machine-wide system PATH.
# =============================================================================

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$InstallRoot = Join-Path $HOME '.local\python'

$Steps = @(
    @{
        Number = 1
        Name   = 'Download & Verify Python'
        Script = Join-Path $ScriptRoot '01-download-python.ps1'
    }
    @{
        Number = 2
        Name   = 'Install Python Standalone & Pip'
        Script = Join-Path $ScriptRoot '02-install-python.ps1'
    }
    @{
        Number = 3
        Name   = 'Configure Environment & Test'
        Script = Join-Path $ScriptRoot '03-configure-python-environment.ps1'
    }
)

function Write-StepStart {
    param([int]$StepNumber, [string]$StepName)
    Write-Host
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host "STEP $StepNumber`: $StepName" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Yellow
}

function Write-StepComplete {
    param([int]$StepNumber, [string]$StepName)
    Write-Host
    Write-Host "✓ STEP $StepNumber COMPLETE: $StepName" -ForegroundColor Green
}

function Write-StepFailed {
    param([int]$StepNumber, [string]$StepName)
    Write-Host
    Write-Host "✗ STEP $StepNumber FAILED: $StepName" -ForegroundColor Red
}

Write-Host
Write-Host "==> Checking Python Installation Status" -ForegroundColor Cyan

if (Test-Path -LiteralPath $InstallRoot) {
    Write-Host "Python is currently installed at: $InstallRoot" -ForegroundColor Yellow
    if ($Force) {
        Write-Host "-Force specified. Existing installation will be replaced." -ForegroundColor Yellow
    }
    else {
        Write-Host "To reinstall cleanly, run:" -ForegroundColor Cyan
        Write-Host "  .\install-python.ps1 -Force" -ForegroundColor Cyan
        exit 0
    }
}
else {
    Write-Host "Python is not currently installed. Proceeding with installation." -ForegroundColor Green
}

# Verify scripts exist
foreach ($Step in $Steps) {
    if (-not (Test-Path -LiteralPath $Step.Script -PathType Leaf)) {
        throw "Missing step script: $($Step.Script)"
    }
}

$CompletedSteps = @()
$FailedStep = $null

foreach ($Step in $Steps) {
    try {
        Write-StepStart -StepNumber $Step.Number -StepName $Step.Name
        $Params = @{}
        if ($Step.Number -eq 2 -and $Force) {
            $Params['Force'] = $true
        }

        & $Step.Script @Params

        if ($LASTEXITCODE -ne 0) {
            Write-StepFailed -StepNumber $Step.Number -StepName $Step.Name
            $FailedStep = $Step
            break
        }

        Write-StepComplete -StepNumber $Step.Number -StepName $Step.Name
        $CompletedSteps += $Step
    }
    catch {
        Write-StepFailed -StepNumber $Step.Number -StepName $Step.Name
        Write-Host "Error Details: $($_.Exception.Message)" -ForegroundColor Red
        $FailedStep = $Step
        break
    }
}

Write-Host
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "PYTHON INSTALLATION SUMMARY" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

if ($FailedStep) {
    Write-Host "✗ Installation failed at Step $($FailedStep.Number): $($FailedStep.Name)" -ForegroundColor Red
    exit 1
}
else {
    Write-Host "✓ PYTHON INSTALLATION COMPLETE" -ForegroundColor Green
    Write-Host "  • Location:     $InstallRoot" -ForegroundColor Green
    Write-Host "  • User PATH:    Updated with Python and Scripts binaries" -ForegroundColor Green
    Write-Host "  • Pip:          Bootstrapped and operational" -ForegroundColor Green
    Write-Host "  • Test Runtime: PASSED" -ForegroundColor Green
    Write-Host
    Write-Host "You can now use Python and Pip! Restart open terminal windows to refresh PATH." -ForegroundColor Green
    exit 0
}
