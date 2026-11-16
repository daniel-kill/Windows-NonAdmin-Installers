#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# =============================================================================
# Primary OpenRouter Ori CLI Installation Orchestrator
#
# Runs all 3 installation steps in sequence:
#   1. Download and verify official native Windows binary and SHA256SUMS.
#   2. Install binary into user space ($HOME\.local\ori\bin\ori.exe).
#   3. Configure persistent user PATH and verify execution.
#
# Parameters:
#   -Force: Overwrite existing binary.
# =============================================================================

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$Steps = @(
    @{ Number = 1; Name = 'Download & Verify Binary'; Script = Join-Path $ScriptRoot '01-download-ori.ps1' }
    @{ Number = 2; Name = 'Install Ori Binary';       Script = Join-Path $ScriptRoot '02-install-ori.ps1' }
    @{ Number = 3; Name = 'Configure PATH & Verify';  Script = Join-Path $ScriptRoot '03-configure-ori-environment.ps1' }
)

Write-Host
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "OPENROUTER ORI CLI NON-ADMIN INSTALLATION" -ForegroundColor Cyan
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
Write-Host "✓ ORI CLI INSTALLATION COMPLETE" -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Green
Write-Host "Location: $HOME\.local\ori\bin\ori.exe"
Write-Host "Run 'ori' in a new terminal window to begin."
exit 0
