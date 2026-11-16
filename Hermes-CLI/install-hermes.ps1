#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# =============================================================================
# Primary Hermes CLI Installation Orchestrator
#
# Runs all 3 installation steps in sequence:
#   1. Verify Python and pip prerequisites.
#   2. Install hermes-agent package into $HOME\.local\hermes.
#   3. Configure persistent user PATH and verify execution.
#
# Parameters:
#   -Force: Force reinstall of the hermes toolchain.
# =============================================================================

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$Steps = @(
    @{ Number = 1; Name = 'Verify Python Prerequisites'; Script = Join-Path $ScriptRoot '01-verify-prerequisites.ps1' }
    @{ Number = 2; Name = 'Install Hermes Agent';        Script = Join-Path $ScriptRoot '02-install-hermes.ps1' }
    @{ Number = 3; Name = 'Configure PATH & Verify';     Script = Join-Path $ScriptRoot '03-configure-hermes-environment.ps1' }
)

Write-Host
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "HERMES CLI NON-ADMIN INSTALLATION" -ForegroundColor Cyan
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
Write-Host "✓ HERMES CLI INSTALLATION COMPLETE" -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Green
Write-Host "Location: $HOME\.local\hermes"
Write-Host "Run 'hermes' in a new terminal window to begin."
exit 0
