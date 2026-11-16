#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# =============================================================================
# Primary Go Installation Orchestrator
#
# Runs all 3 installation steps in sequence:
#   1. Discover, download, and verify latest stable Go distribution.
#   2. Extract and install Go under $HOME\.local\go.
#   3. Configure persistent user PATH and GOPATH, and verify compilation.
#
# Parameters:
#   -Force: Remove existing Go installation at $HOME\.local\go and reinstall.
#
# This script DOES NOT:
#   - Require administrator privileges.
#   - Modify the machine-wide system PATH.
# =============================================================================

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$InstallRoot = Join-Path $HOME '.local\go'

$Steps = @(
    @{
        Number = 1
        Name   = 'Download & Verify Go'
        Script = Join-Path $ScriptRoot '01-download-go.ps1'
    }
    @{
        Number = 2
        Name   = 'Install Go Standalone'
        Script = Join-Path $ScriptRoot '02-install-go.ps1'
    }
    @{
        Number = 3
        Name   = 'Configure Environment & Test'
        Script = Join-Path $ScriptRoot '03-configure-go-environment.ps1'
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
Write-Host "==> Checking Go Installation Status" -ForegroundColor Cyan

if (Test-Path -LiteralPath $InstallRoot) {
    Write-Host "Go is currently installed at: $InstallRoot" -ForegroundColor Yellow
    if ($Force) {
        Write-Host "-Force specified. Existing installation will be replaced." -ForegroundColor Yellow
    }
    else {
        Write-Host "To reinstall cleanly, run:" -ForegroundColor Cyan
        Write-Host "  .\install-go.ps1 -Force" -ForegroundColor Cyan
        exit 0
    }
}
else {
    Write-Host "Go is not currently installed. Proceeding with installation." -ForegroundColor Green
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
Write-Host "GO INSTALLATION SUMMARY" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

if ($FailedStep) {
    Write-Host "✗ Installation failed at Step $($FailedStep.Number): $($FailedStep.Name)" -ForegroundColor Red
    exit 1
}
else {
    Write-Host "✓ GO INSTALLATION COMPLETE" -ForegroundColor Green
    Write-Host "  • Location:   $InstallRoot" -ForegroundColor Green
    Write-Host "  • User PATH:  Updated with Go binaries" -ForegroundColor Green
    Write-Host "  • GOPATH:     $HOME\go" -ForegroundColor Green
    Write-Host "  • Test Build: PASSED" -ForegroundColor Green
    Write-Host
    Write-Host "You can now use Go! Restart open terminal windows to refresh PATH." -ForegroundColor Green
    exit 0
}
