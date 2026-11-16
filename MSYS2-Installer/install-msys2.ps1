#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# =============================================================================
# Primary MSYS2 Installation Orchestrator
#
# This script orchestrates the complete MSYS2 installation process by running
# all 5 installation steps in sequence. It will:
#   1. Check if MSYS2 is already installed
#   2. Run each installation step (01-05) in order
#   3. Stop immediately if any step fails
#   4. Report overall progress and status
#
# Parameters:
#   -Force: Remove existing MSYS2 installation and proceed with reinstall
#
# This script DOES NOT:
#   - Require administrator privileges
#   - Modify the system PATH
#   - Install Rust
# =============================================================================

# =============================================================================
# Configuration
# =============================================================================

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$MSYS2Root = Join-Path $HOME 'msys64'

$Steps = @(
    @{
        Number = 1
        Name   = 'Download MSYS2 Archive'
        Script = Join-Path $ScriptRoot '01-install-msys2.ps1'
    }
    @{
        Number = 2
        Name   = 'Import MSYS2 Signing Key'
        Script = Join-Path $ScriptRoot '02-import-msys2-signing-key.ps1'
    }
    @{
        Number = 3
        Name   = 'Verify MSYS2 Archive'
        Script = Join-Path $ScriptRoot '03-verify-msys2-archive.ps1'
    }
    @{
        Number = 4
        Name   = 'Install MSYS2'
        Script = Join-Path $ScriptRoot '04-install-msys2.ps1'
    }
    @{
        Number = 5
        Name   = 'Install GCC Toolchain'
        Script = Join-Path $ScriptRoot '05-install-gcc.ps1'
    }
)

# =============================================================================
# Helpers
# =============================================================================

function Write-Step {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-StepStart {
    param(
        [Parameter(Mandatory)]
        [int]$StepNumber,

        [Parameter(Mandatory)]
        [string]$StepName
    )

    Write-Host
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host "STEP $StepNumber`: $StepName" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Yellow
}

function Write-StepComplete {
    param(
        [Parameter(Mandatory)]
        [int]$StepNumber,

        [Parameter(Mandatory)]
        [string]$StepName
    )

    Write-Host
    Write-Host "✓ STEP $StepNumber COMPLETE: $StepName" -ForegroundColor Green
}

function Write-StepFailed {
    param(
        [Parameter(Mandatory)]
        [int]$StepNumber,

        [Parameter(Mandatory)]
        [string]$StepName
    )

    Write-Host
    Write-Host "✗ STEP $StepNumber FAILED: $StepName" -ForegroundColor Red
}

# =============================================================================
# Check Installation Status
# =============================================================================

Write-Step 'Checking MSYS2 Installation Status'

if (Test-Path -LiteralPath $MSYS2Root) {
    Write-Host
    Write-Host "MSYS2 is already installed at:" -ForegroundColor Yellow
    Write-Host "  $MSYS2Root"
    Write-Host

    if ($Force) {
        Write-Host "The -Force flag was specified. Removing existing installation..." -ForegroundColor Yellow
        Write-Host "This installation will be removed and replaced." -ForegroundColor Yellow
    }
    else {
        Write-Host "To remove the existing installation and reinstall, use:" -ForegroundColor Cyan
        Write-Host "  .\install-msys2.ps1 -Force" -ForegroundColor Cyan
        Write-Host
        Write-Host "Exiting without making changes." -ForegroundColor Yellow
        Write-Host
        exit 0
    }
}
else {
    Write-Host "MSYS2 is not installed. Proceeding with installation." -ForegroundColor Green
}

# =============================================================================
# Verify All Scripts Exist
# =============================================================================

Write-Step 'Verifying Installation Scripts'

foreach ($Step in $Steps) {
    if (-not (Test-Path -LiteralPath $Step.Script)) {
        throw "Installation script not found: $($Step.Script)"
    }

    Write-Host "Found: Step $($Step.Number) - $($Step.Name)"
}

Write-Host 'All installation scripts verified.' -ForegroundColor Green

# =============================================================================
# Run Installation Steps
# =============================================================================

$CompletedSteps = @()
$FailedStep = $null

foreach ($Step in $Steps) {
    try {
        Write-StepStart -StepNumber $Step.Number -StepName $Step.Name

        $ScriptParams = @{}

        # Pass -Force flag to step 4 (install MSYS2)
        if ($Step.Number -eq 4 -and $Force) {
            $ScriptParams['Force'] = $true
        }

        # Execute the installation step
        & $Step.Script @ScriptParams

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
        Write-Host
        Write-Host "Error Details:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        $FailedStep = $Step
        break
    }
}

# =============================================================================
# Installation Summary
# =============================================================================

Write-Host
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "INSTALLATION SUMMARY" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

Write-Host
Write-Host "MSYS2 Installation Location:" -ForegroundColor Cyan
Write-Host "  $MSYS2Root"
Write-Host

Write-Host "Completed Steps:" -ForegroundColor Cyan
if ($CompletedSteps.Count -eq 0) {
    Write-Host "  (none)" -ForegroundColor DarkYellow
}
else {
    $CompletedSteps | ForEach-Object {
        Write-Host "  ✓ Step $($_.Number): $($_.Name)" -ForegroundColor Green
    }
}

Write-Host

if ($FailedStep) {
    Write-Host "Failed Step:" -ForegroundColor Red
    Write-Host "  ✗ Step $($FailedStep.Number): $($FailedStep.Name)" -ForegroundColor Red
    Write-Host
    Write-Host "Remaining Steps (not executed):" -ForegroundColor Yellow

    $RemainingSteps = $Steps | Where-Object { $_.Number -gt $FailedStep.Number }
    if ($RemainingSteps.Count -eq 0) {
        Write-Host "  (none)" -ForegroundColor DarkYellow
    }
    else {
        $RemainingSteps | ForEach-Object {
            Write-Host "  ○ Step $($_.Number): $($_.Name)" -ForegroundColor Yellow
        }
    }

    Write-Host
    Write-Host "INSTALLATION FAILED" -ForegroundColor Red
    Write-Host
    Write-Host "To resume from the beginning, use:" -ForegroundColor Cyan
    Write-Host "  .\install-msys2.ps1" -ForegroundColor Cyan

    if ($MSYS2Root -ne '' -and (Test-Path -LiteralPath $MSYS2Root)) {
        Write-Host
        Write-Host "Or to remove the partial installation and start over:" -ForegroundColor Cyan
        Write-Host "  .\install-msys2.ps1 -Force" -ForegroundColor Cyan
    }

    Write-Host
    exit 1
}
else {
    Write-Host "Remaining Steps (not executed):" -ForegroundColor Cyan
    Write-Host "  (all steps completed)" -ForegroundColor DarkGreen
    Write-Host

    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "✓ MSYS2 INSTALLATION COMPLETE" -ForegroundColor Green
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host

    Write-Host "Installation Summary:" -ForegroundColor Green
    Write-Host "  • MSYS2 installation: COMPLETE" -ForegroundColor Green
    Write-Host "  • GPG signing key: IMPORTED" -ForegroundColor Green
    Write-Host "  • Archive verification: COMPLETE" -ForegroundColor Green
    Write-Host "  • MSYS2 extraction: COMPLETE" -ForegroundColor Green
    Write-Host "  • GCC toolchain: INSTALLED" -ForegroundColor Green
    Write-Host
    Write-Host "You can now use MSYS2 for Rust development!" -ForegroundColor Green
    Write-Host
    exit 0
}
