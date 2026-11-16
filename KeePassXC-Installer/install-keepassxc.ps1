#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# =============================================================================
# Primary KeePassXC Non-Admin Installation Orchestrator
#
# Runs all 3 installation steps in sequence:
#   1. Discover, download, and verify official KeePassXC portable release.
#   2. Install KeePassXC into user space ($HOME\.local\keepassxc) in portable mode.
#   3. Configure persistent user PATH and verify CLI functionality.
#
# Parameters:
#   -Force: Overwrite and reinstall cleanly.
# =============================================================================

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$Steps = @(
    @{ Number = 1; Name = 'Download & Verify KeePassXC';   Script = Join-Path $ScriptRoot '01-download-keepassxc.ps1' }
    @{ Number = 2; Name = 'Install KeePassXC Portable';     Script = Join-Path $ScriptRoot '02-install-keepassxc.ps1' }
    @{ Number = 3; Name = 'Configure PATH & Verify CLI';    Script = Join-Path $ScriptRoot '03-configure-keepassxc-environment.ps1' }
)

Write-Host
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "KEEPASSXC NON-ADMIN INSTALLATION" -ForegroundColor Cyan
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
Write-Host "✓ KEEPASSXC INSTALLATION COMPLETE" -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Green
Write-Host "Location: $HOME\.local\keepassxc"
Write-Host "Run 'keepassxc-cli --help' or 'keepassxc' in a new terminal window to begin."
exit 0
