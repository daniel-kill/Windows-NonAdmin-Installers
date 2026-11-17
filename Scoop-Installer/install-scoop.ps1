#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$Steps = @(
    @{ Number = 1; Name = 'Download & Verify Scoop';       Script = Join-Path $ScriptRoot '01-download-scoop.ps1' }
    @{ Number = 2; Name = 'Extract & Deploy Shims';        Script = Join-Path $ScriptRoot '02-install-scoop.ps1' }
    @{ Number = 3; Name = 'Configure Environment & Verify'; Script = Join-Path $ScriptRoot '03-configure-scoop-environment.ps1' }
)

Write-Host
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "SCOOP NON-ADMIN COMMAND-LINE INSTALLER" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

foreach ($Step in $Steps) {
    Write-Host
    Write-Host "==> Step $($Step.Number): $($Step.Name)" -ForegroundColor Yellow
    $Params = @{}
    if ($Step.Number -eq 2 -and $Force) { $Params['Force'] = $true }

    try {
        $global:LASTEXITCODE = 0
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

$InstallDir = if ($env:SCOOP) { $env:SCOOP } else { Join-Path $HOME 'scoop' }
Write-Host
Write-Host "===================================================" -ForegroundColor Green
Write-Host "✓ SCOOP INSTALLATION COMPLETE" -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Green
Write-Host "Location: $InstallDir\shims\scoop.cmd"
Write-Host "Run 'scoop --help' or 'scoop status' in a new terminal window to begin."
exit 0
