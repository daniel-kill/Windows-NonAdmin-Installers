#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# =============================================================================
# Primary Mistral Vibe Installation Orchestrator
#
# Runs all 3 installation steps in sequence:
#   1. Verify Python and pip prerequisites.
#   2. Install mistral-vibe package into $HOME\.local\vibe.
#   3. Configure persistent user PATH and verify execution.
#
# Parameters:
#   -Force: Force reinstall of the vibe toolchain.
# =============================================================================

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$Steps = @(
    @{ Number = 1; Name = 'Verify Python Prerequisites'; Script = Join-Path $ScriptRoot '01-verify-prerequisites.ps1' }
    @{ Number = 2; Name = 'Install Mistral Vibe';        Script = Join-Path $ScriptRoot '02-install-vibe.ps1' }
    @{ Number = 3; Name = 'Configure PATH & Verify';     Script = Join-Path $ScriptRoot '03-configure-vibe-environment.ps1' }
)

Write-Host
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "MISTRAL VIBE CLI NON-ADMIN INSTALLATION" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

foreach ($Step in $Steps) {
    Write-Host
    Write-Host "==> Step $($Step.Number): $($Step.Name)" -ForegroundColor Yellow
    $Params = @{}
    if ($Step.Number -eq 2 -and $Force) { $Params['Force'] = $true }

    try {
        & $Step.Script @Params
        if ($LASTEXITCODE -ne 0) {
            Write-Host "✗ Step $($Step.Number) FAILED: $($Step.Name)" -ForegroundColor Red
            exit 1
        }
    }
    catch {
        Write-Host "✗ Step $($Step.Number) ERROR: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

Write-Host
Write-Host "===================================================" -ForegroundColor Green
Write-Host "✓ MISTRAL VIBE CLI INSTALLATION COMPLETE" -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Green
Write-Host "Location: $HOME\.local\vibe"
Write-Host "Run 'vibe' in a new terminal window to begin."
exit 0
