#Requires -Version 7.0

param(
    [switch]$All,
    [switch]$MSYS2,
    [switch]$Rust,
    [switch]$Go,
    [switch]$Node,
    [switch]$Python,
    [switch]$Force,
    [switch]$List,
    [switch]$Help,
    [switch]$NonInteractive
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# =============================================================================
# Unified Non-Admin Developer Toolchain Provisioner
# =============================================================================

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$ToolchainRegistry = @(
    [pscustomobject]@{
        Id          = 'MSYS2'
        Name        = 'MSYS2 & UCRT64 GCC'
        InstallDir  = Join-Path $HOME 'msys64'
        ScriptPath  = Join-Path $ScriptRoot 'MSYS2-Installer\install-msys2.ps1'
        Description = 'Unix environment, UCRT64 GCC/G++, GNU binutils, Make, pkg-config'
    }
    [pscustomobject]@{
        Id          = 'Rust'
        Name        = 'Rust Standalone GNU'
        InstallDir  = Join-Path $HOME '.local\rust'
        ScriptPath  = Join-Path $ScriptRoot 'Rust-Installer\install-rust.ps1'
        Description = 'Official Rust GNU toolchain (rustc, cargo, rustdoc) linked to UCRT64'
    }
    [pscustomobject]@{
        Id          = 'Go'
        Name        = 'Go Programming Language'
        InstallDir  = Join-Path $HOME '.local\go'
        ScriptPath  = Join-Path $ScriptRoot 'Go-Installer\install-go.ps1'
        Description = 'Official Go compiler, tools, GOPATH setup, and standard libraries'
    }
    [pscustomobject]@{
        Id          = 'Node'
        Name        = 'Node.js LTS & NPM'
        InstallDir  = Join-Path $HOME '.local\node'
        ScriptPath  = Join-Path $ScriptRoot 'Node-Installer\install-node.ps1'
        Description = 'Node.js LTS runtime, npm package manager, and .npm-global setup'
    }
    [pscustomobject]@{
        Id          = 'Python'
        Name        = 'Python Portable & Pip'
        InstallDir  = Join-Path $HOME '.local\python'
        ScriptPath  = Join-Path $ScriptRoot 'Python-Installer\install-python.ps1'
        Description = 'Python 3 runtime, pip package manager, and site-packages setup'
    }
)

function Show-Help {
    Write-Host
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host " UNIFIED NON-ADMIN TOOLCHAIN PROVISIONER — HELP & EXAMPLES" -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host @"

SYNOPSIS:
  install-all.ps1 [-All] [-MSYS2] [-Rust] [-Go] [-Node] [-Python] [-Force] [-List] [-Help]

DESCRIPTION:
  Automates user-local, zero-administrator installation of developer toolchains
  under Windows 10/11 x86-64 using PowerShell 7. All downloads are verified against
  cryptographic checksums and PGP signatures before extraction.

OPTIONS:
  -All             Install all available toolchains (MSYS2, Rust, Go, Node, Python).
  -MSYS2           Install MSYS2 with UCRT64 GCC, Make, and binutils into `$HOME\msys64.
  -Rust            Install Rust standalone GNU toolchain into `$HOME\.local\rust.
  -Go              Install official Go compiler & tools into `$HOME\.local\go.
  -Node            Install Node.js LTS and NPM into `$HOME\.local\node.
  -Python          Install portable Python 3 with pip into `$HOME\.local\python.
  -Force           Force re-installation (removes existing directory before reinstalling).
  -List            Display the current installation status of all toolchains.
  -Help            Show this detailed help manual and usage examples.
  -NonInteractive  Do not prompt interactively if no flags are passed.

EXAMPLES:
  1. Display current toolchain inventory and status:
     .\install-all.ps1 -List

  2. Install all toolchains in sequence:
     .\install-all.ps1 -All

  3. Install only Go and Node.js:
     .\install-all.ps1 -Go -Node

  4. Reinstall Python cleanly:
     .\install-all.ps1 -Python -Force

  5. Run with ExecutionPolicy bypass (recommended on restricted environments):
     pwsh -ExecutionPolicy Bypass -File .\install-all.ps1 -All

"@
}

if ($Help) {
    Show-Help
    exit 0
}

# -----------------------------------------------------------------------------
# Handle -List
# -----------------------------------------------------------------------------

if ($List) {
    Write-Host
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " AVAILABLE NON-ADMIN TOOLCHAINS" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host

    foreach ($Item in $ToolchainRegistry) {
        $Installed = Test-Path -LiteralPath $Item.InstallDir
        $StatusBadge = if ($Installed) { "[INSTALLED]" } else { "[NOT INSTALLED]" }
        $Color = if ($Installed) { "Green" } else { "DarkYellow" }

        Write-Host "$($Item.Id.PadRight(8)) " -NoNewline -ForegroundColor Cyan
        Write-Host "$StatusBadge ".PadRight(18) -NoNewline -ForegroundColor $Color
        Write-Host "$($Item.Name)" -ForegroundColor White
        Write-Host "         Path: $($Item.InstallDir)" -ForegroundColor Gray
        Write-Host "         Desc: $($Item.Description)" -ForegroundColor Gray
        Write-Host
    }
    exit 0
}

# -----------------------------------------------------------------------------
# Determine which toolchains to execute
# -----------------------------------------------------------------------------

$SelectedIds = [Collections.Generic.List[string]]::new()

if ($All) {
    $ToolchainRegistry | ForEach-Object { $SelectedIds.Add($_.Id) }
}
else {
    if ($MSYS2)  { $SelectedIds.Add('MSYS2') }
    if ($Rust)   { $SelectedIds.Add('Rust') }
    if ($Go)     { $SelectedIds.Add('Go') }
    if ($Node)   { $SelectedIds.Add('Node') }
    if ($Python) { $SelectedIds.Add('Python') }
}

# Interactive Menu when run bare and not in headless non-interactive mode
if ($SelectedIds.Count -eq 0) {
    if ($NonInteractive -or [Console]::IsInputRedirected) {
        Write-Host "No toolchains specified in non-interactive mode. Use -Help or -List." -ForegroundColor Yellow
        exit 0
    }

    while ($true) {
        Clear-Host
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "   WINDOWS NON-ADMIN DEVELOPER TOOLCHAIN PROVISIONER" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host

        for ($i = 0; $i -lt $ToolchainRegistry.Count; $i++) {
            $Item = $ToolchainRegistry[$i]
            $Installed = Test-Path -LiteralPath $Item.InstallDir
            $Badge = if ($Installed) { "[INSTALLED]" } else { "[NOT INSTALLED]" }
            $BadgeColor = if ($Installed) { "Green" } else { "DarkYellow" }
            Write-Host "  [$($i + 1)] " -NoNewline -ForegroundColor White
            Write-Host "$($Item.Name.PadRight(26)) " -NoNewline -ForegroundColor White
            Write-Host $Badge -ForegroundColor $BadgeColor
        }

        Write-Host
        Write-Host "  [A] Install All Toolchains" -ForegroundColor Cyan
        Write-Host "  [L] List Toolchain Details" -ForegroundColor Cyan
        Write-Host "  [H] View Detailed Help & Flags" -ForegroundColor Cyan
        Write-Host "  [Q] Quit" -ForegroundColor Red
        Write-Host
        $Choice = Read-Host "Select an option (1-5, A, L, H, Q)"

        if ($Choice -match '^[1-5]$') {
            $Index = [int]$Choice - 1
            $SelectedIds.Add($ToolchainRegistry[$Index].Id)
            break
        }
        elseif ($Choice -ieq 'A') {
            $ToolchainRegistry | ForEach-Object { $SelectedIds.Add($_.Id) }
            break
        }
        elseif ($Choice -ieq 'L') {
            & $PSCommandPath -List
            Read-Host "Press Enter to return to menu..."
        }
        elseif ($Choice -ieq 'H') {
            Show-Help
            Read-Host "Press Enter to return to menu..."
        }
        elseif ($Choice -ieq 'Q') {
            Write-Host "Exiting." -ForegroundColor Yellow
            exit 0
        }
    }
}

# Dependency check: Rust requires MSYS2 UCRT64
if ($SelectedIds.Contains('Rust')) {
    $MSYS2Dir = Join-Path $HOME 'msys64'
    if (-not (Test-Path -LiteralPath $MSYS2Dir) -and -not $SelectedIds.Contains('MSYS2')) {
        Write-Warning "Rust toolchain requires MSYS2 UCRT64. Automatically prepending MSYS2 to installation queue."
        $SelectedIds.Insert(0, 'MSYS2')
    }
}

# -----------------------------------------------------------------------------
# Execution Loop
# -----------------------------------------------------------------------------

Write-Host
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " UNIFIED TOOLCHAIN PROVISIONING STARTED" -ForegroundColor Cyan
Write-Host " Selected: $($SelectedIds -join ', ')" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$Results = @()

foreach ($Item in $ToolchainRegistry) {
    if (-not $SelectedIds.Contains($Item.Id)) {
        continue
    }

    Write-Host
    Write-Host "------------------------------------------------------------" -ForegroundColor Yellow
    Write-Host " PROVISIONING: $($Item.Name) ($($Item.Id))" -ForegroundColor Yellow
    Write-Host " Script: $($Item.ScriptPath)" -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------" -ForegroundColor Yellow

    $StartTime = Get-Date
    $Status = 'FAILED'
    $ErrorMsg = ''

    try {
        $Params = @{}
        if ($Force) {
            $Params['Force'] = $true
        }

        & $Item.ScriptPath @Params

        if ($LASTEXITCODE -eq 0) {
            $Status = 'SUCCESS'
        }
        else {
            $ErrorMsg = "Exit code $LASTEXITCODE"
        }
    }
    catch {
        $ErrorMsg = $_.Exception.Message
    }

    $Duration = ((Get-Date) - $StartTime).ToString('mm\:ss')

    $Results += [pscustomobject]@{
        Id       = $Item.Id
        Name     = $Item.Name
        Status   = $Status
        Duration = $Duration
        Path     = $Item.InstallDir
        Error    = $ErrorMsg
    }
}

# -----------------------------------------------------------------------------
# Executive Summary Report
# -----------------------------------------------------------------------------

Write-Host
Write-Host "============================================================" -ForegroundColor Green
Write-Host " PROVISIONING COMPLETE — EXECUTIVE SUMMARY" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host

$HasFailures = $false

foreach ($R in $Results) {
    $BadgeColor = if ($R.Status -eq 'SUCCESS') { 'Green' } else { 'Red'; $HasFailures = $true }
    Write-Host "• $($R.Name.PadRight(26)) " -NoNewline -ForegroundColor White
    Write-Host "[$($R.Status)]".PadRight(12) -NoNewline -ForegroundColor $BadgeColor
    Write-Host "($($R.Duration))" -ForegroundColor Gray
    Write-Host "  Path: $($R.Path)" -ForegroundColor DarkGray
    if ($R.Status -ne 'SUCCESS') {
        Write-Host "  Error: $($R.Error)" -ForegroundColor Red
    }
}

Write-Host
Write-Host "Environment Refresh Notice:" -ForegroundColor Yellow
Write-Host "Persistent User PATH updates have been registered. Close and restart"
Write-Host "any active PowerShell, CMD, Windows Terminal, or VS Code sessions to"
Write-Host "access newly installed tools."
Write-Host

if ($HasFailures) {
    Write-Host "Some toolchains failed to install cleanly. Check the logs above." -ForegroundColor Red
    exit 1
}
else {
    Write-Host "All selected toolchains provisioned successfully!" -ForegroundColor Green
    exit 0
}
