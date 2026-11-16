#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# =============================================================================
# Primary Cline CLI Installation Orchestrator
#
# Runs all 3 installation steps in sequence:
#   1. Verify Node.js and NPM prerequisites.
#   2. Install cline globally in user space ($HOME\.npm-global).
#   3. Configure persistent user PATH and verify execution.
#
# Parameters:
#   -Force: Force reinstall of the cline npm package.
# =============================================================================

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$Steps = @(
    @{ Number = 1; Name = 'Verify Node.js Prerequisites'; Script = Join-Path $ScriptRoot '01-verify-prerequisites.ps1' }
    @{ Number = 2; Name = 'Install Cline Package';       Script = Join-Path $ScriptRoot '02-install-cline.ps1' }
    @{ Number = 3; Name = 'Configure PATH & Verify';     Script = Join-Path $ScriptRoot '03-configure-cline-environment.ps1' }
)

Write-Host
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "CLINE CLI NON-ADMIN INSTALLATION" -ForegroundColor Cyan
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
Write-Host "✓ CLINE CLI INSTALLATION COMPLETE" -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Green
Write-Host "Location: $HOME\.npm-global"
Write-Host "Run 'cline' in a new terminal window to begin."
exit 0
