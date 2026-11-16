#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# =============================================================================
# Primary Gpg4win & GnuPG Installation Orchestrator
#
# Runs all 3 installation steps in sequence:
#   1. Discover, download, and verify official Gpg4win release installer.
#   2. Install Gpg4win & GnuPG into user space ($HOME\.local\gpg4win) without UAC.
#   3. Configure persistent user PATH and verify GnuPG execution.
#
# Parameters:
#   -Force: Overwrite and reinstall cleanly.
# =============================================================================

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$Steps = @(
    @{ Number = 1; Name = 'Download & Verify Gpg4win';    Script = Join-Path $ScriptRoot '01-download-gpg4win.ps1' }
    @{ Number = 2; Name = 'Install Gpg4win & GnuPG';      Script = Join-Path $ScriptRoot '02-install-gpg4win.ps1' }
    @{ Number = 3; Name = 'Configure PATH & Verify GPG';  Script = Join-Path $ScriptRoot '03-configure-gpg4win-environment.ps1' }
)

Write-Host
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "GPG4WIN & GNUPG NON-ADMIN INSTALLATION" -ForegroundColor Cyan
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
Write-Host "✓ GPG4WIN & GNUPG INSTALLATION COMPLETE" -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Green
Write-Host "Location: $HOME\.local\gpg4win"
Write-Host "GnuPG is now ready! Run 'gpg --version' in a new terminal window to begin."
exit 0
