#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# =============================================================================
# Primary Node.js Installation Orchestrator
#
# Runs all 3 installation steps in sequence:
#   1. Discover, download, and verify latest Node.js LTS distribution.
#   2. Extract and install Node.js under $HOME\.local\node.
#   3. Configure persistent user PATH and .npm-global prefix, and verify runtime.
#
# Parameters:
#   -Force: Remove existing Node.js installation at $HOME\.local\node and reinstall.
#
# This script DOES NOT:
#   - Require administrator privileges.
#   - Modify the machine-wide system PATH.
# =============================================================================

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$InstallRoot = Join-Path $HOME '.local\node'

$Steps = @(
    @{
        Number = 1
        Name   = 'Download & Verify Node.js LTS'
        Script = Join-Path $ScriptRoot '01-download-node.ps1'
    }
    @{
        Number = 2
        Name   = 'Install Node.js Standalone'
        Script = Join-Path $ScriptRoot '02-install-node.ps1'
    }
    @{
        Number = 3
        Name   = 'Configure Environment & Test'
        Script = Join-Path $ScriptRoot '03-configure-node-environment.ps1'
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
Write-Host "==> Checking Node.js Installation Status" -ForegroundColor Cyan

if (Test-Path -LiteralPath $InstallRoot) {
    Write-Host "Node.js is currently installed at: $InstallRoot" -ForegroundColor Yellow
    if ($Force) {
        Write-Host "-Force specified. Existing installation will be replaced." -ForegroundColor Yellow
    }
    else {
        Write-Host "To reinstall cleanly, run:" -ForegroundColor Cyan
        Write-Host "  .\install-node.ps1 -Force" -ForegroundColor Cyan
        exit 0
    }
}
else {
    Write-Host "Node.js is not currently installed. Proceeding with installation." -ForegroundColor Green
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
Write-Host "NODE.JS INSTALLATION SUMMARY" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

if ($FailedStep) {
    Write-Host "✗ Installation failed at Step $($FailedStep.Number): $($FailedStep.Name)" -ForegroundColor Red
    exit 1
}
else {
    Write-Host "✓ NODE.JS INSTALLATION COMPLETE" -ForegroundColor Green
    Write-Host "  • Location:    $InstallRoot" -ForegroundColor Green
    Write-Host "  • User PATH:   Updated with Node.js and .npm-global binaries" -ForegroundColor Green
    Write-Host "  • NPM Prefix:  $HOME\.npm-global" -ForegroundColor Green
    Write-Host "  • Test Eval:   PASSED" -ForegroundColor Green
    Write-Host
    Write-Host "You can now use Node and NPM! Restart open terminal windows to refresh PATH." -ForegroundColor Green
    exit 0
}
