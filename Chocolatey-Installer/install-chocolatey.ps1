#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$Steps = @(
    @{ Number = 1; Name = 'Download & Verify Chocolatey';   Script = Join-Path $ScriptRoot '01-download-chocolatey.ps1' }
    @{ Number = 2; Name = 'Extract & Deploy choco.exe';      Script = Join-Path $ScriptRoot '02-install-chocolatey.ps1' }
    @{ Number = 3; Name = 'Configure Environment & Verify'; Script = Join-Path $ScriptRoot '03-configure-chocolatey-environment.ps1' }
)

Write-Host
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "CHOCOLATEY NON-ADMIN USER-LOCAL INSTALLATION" -ForegroundColor Cyan
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

$InstallDir = if ($env:ChocolateyInstall) { $env:ChocolateyInstall } else { Join-Path $HOME '.local\chocolatey' }
Write-Host
Write-Host "===================================================" -ForegroundColor Green
Write-Host "✓ CHOCOLATEY INSTALLATION COMPLETE" -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Green
Write-Host "Location: $InstallDir\bin\choco.exe"
Write-Host "Note: Non-administrative choco installs target portable packages (*.portable)."
Write-Host "Run 'choco --help' in a new terminal window to begin."
exit 0
