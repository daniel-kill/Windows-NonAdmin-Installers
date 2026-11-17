#Requires -Version 7.0

param(
    [switch]$All,
    [switch]$Gpg4win,
    [switch]$KeePassXC,
    [switch]$MSYS2,
    [switch]$Rust,
    [switch]$Go,
    [switch]$Node,
    [switch]$Python,
    [switch]$Bun,
    [switch]$Deno,
    [switch]$Uv,
    [switch]$Cmake,
    [switch]$Ninja,
    [switch]$Git,
    [switch]$Gh,
    [switch]$SevenZip,
    [switch]$Ripgrep,
    [switch]$Fd,
    [switch]$Jq,
    [switch]$Fzf,
    [switch]$Bat,
    [switch]$Delta,
    [switch]$Eza,
    [switch]$Cloudflared,
    [switch]$VSCode,
    [switch]$Cline,
    [switch]$Hermes,
    [switch]$Vibe,
    [switch]$Ori,
    [switch]$Antigravity,
    [switch]$Copilot,
    [switch]$Claude,
    [switch]$Aider,
    [switch]$Herdr,
    [switch]$Chocolatey,
    [switch]$Scoop,
    [switch]$PackageManagers,
    [switch]$CliTools,
    [switch]$KeepCache,
    [switch]$List,
    [switch]$Help,
    [switch]$NonInteractive
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# =============================================================================
# Unified Non-Admin Developer Toolchain & CLI Uninstaller Orchestrator
# =============================================================================

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$ToolchainRegistry = @(
    # Security & Prerequisites
    [pscustomobject]@{ Id = 'Gpg4win';    Name = 'Gpg4win & GnuPG';            InstallDir = Join-Path $HOME '.local\gpg4win';     ScriptPath = Join-Path $ScriptRoot 'Gpg4win-Installer\uninstall-gpg4win.ps1';       Category = 'Security & Prerequisites' }
    [pscustomobject]@{ Id = 'KeePassXC';  Name = 'KeePassXC & CLI';            InstallDir = Join-Path $HOME '.local\keepassxc';   ScriptPath = Join-Path $ScriptRoot 'KeePassXC-Installer\uninstall-keepassxc.ps1';   Category = 'Security & Prerequisites' }

    # Core Toolchains & Modern Runtimes
    [pscustomobject]@{ Id = 'MSYS2';      Name = 'MSYS2 & UCRT64 GCC';         InstallDir = Join-Path $HOME 'msys64';             ScriptPath = Join-Path $ScriptRoot 'MSYS2-Installer\uninstall-msys2.ps1';           Category = 'Core Toolchains' }
    [pscustomobject]@{ Id = 'Rust';       Name = 'Rust Standalone GNU';        InstallDir = Join-Path $HOME '.local\rust';        ScriptPath = Join-Path $ScriptRoot 'Rust-Installer\uninstall-rust.ps1';             Category = 'Core Toolchains' }
    [pscustomobject]@{ Id = 'Go';         Name = 'Go Programming Language';    InstallDir = Join-Path $HOME '.local\go';          ScriptPath = Join-Path $ScriptRoot 'Go-Installer\uninstall-go.ps1';                 Category = 'Core Toolchains' }
    [pscustomobject]@{ Id = 'Node';       Name = 'Node.js LTS & NPM';          InstallDir = Join-Path $HOME '.local\node';        ScriptPath = Join-Path $ScriptRoot 'Node-Installer\uninstall-node.ps1';             Category = 'Core Toolchains' }
    [pscustomobject]@{ Id = 'Python';     Name = 'Python Portable & Pip';      InstallDir = Join-Path $HOME '.local\python';      ScriptPath = Join-Path $ScriptRoot 'Python-Installer\uninstall-python.ps1';         Category = 'Core Toolchains' }
    [pscustomobject]@{ Id = 'Bun';        Name = 'Bun JS/TS Runtime';          InstallDir = Join-Path $HOME '.local\bun';         ScriptPath = Join-Path $ScriptRoot 'Bun-CLI\uninstall-bun.ps1';                     Category = 'Core Toolchains' }
    [pscustomobject]@{ Id = 'Deno';       Name = 'Deno TS/JS Runtime';         InstallDir = Join-Path $HOME '.local\deno';        ScriptPath = Join-Path $ScriptRoot 'Deno-CLI\uninstall-deno.ps1';                   Category = 'Core Toolchains' }

    # Build Systems
    [pscustomobject]@{ Id = 'Cmake';      Name = 'CMake Portable';             InstallDir = Join-Path $HOME '.local\cmake';       ScriptPath = Join-Path $ScriptRoot 'CMake-Installer\uninstall-cmake.ps1';           Category = 'Build Systems' }
    [pscustomobject]@{ Id = 'Ninja';      Name = 'Ninja Build System';         InstallDir = Join-Path $HOME '.local\ninja';       ScriptPath = Join-Path $ScriptRoot 'Ninja-Installer\uninstall-ninja.ps1';           Category = 'Build Systems' }

    # VCS & Core Terminal Utilities
    [pscustomobject]@{ Id = 'Git';        Name = 'PortableGit';                InstallDir = Join-Path $HOME '.local\git';         ScriptPath = Join-Path $ScriptRoot 'PortableGit-Installer\uninstall-git.ps1';       Category = 'VCS & Utilities' }
    [pscustomobject]@{ Id = 'Gh';         Name = 'GitHub CLI (gh)';            InstallDir = Join-Path $HOME '.local\gh';          ScriptPath = Join-Path $ScriptRoot 'GitHub-CLI\uninstall-gh.ps1';                   Category = 'VCS & Utilities' }
    [pscustomobject]@{ Id = 'SevenZip';   Name = '7-Zip Console & Suite';      InstallDir = Join-Path $HOME '.local\7zip';        ScriptPath = Join-Path $ScriptRoot '7Zip-Installer\uninstall-7zip.ps1';             Category = 'VCS & Utilities' }
    [pscustomobject]@{ Id = 'Ripgrep';    Name = 'ripgrep (rg)';               InstallDir = Join-Path $HOME '.local\ripgrep';     ScriptPath = Join-Path $ScriptRoot 'Ripgrep-CLI\uninstall-ripgrep.ps1';             Category = 'VCS & Utilities' }
    [pscustomobject]@{ Id = 'Fd';         Name = 'fd (find alternative)';      InstallDir = Join-Path $HOME '.local\fd';          ScriptPath = Join-Path $ScriptRoot 'Fd-CLI\uninstall-fd.ps1';                       Category = 'VCS & Utilities' }
    [pscustomobject]@{ Id = 'Jq';         Name = 'jq (JSON processor)';        InstallDir = Join-Path $HOME '.local\jq';          ScriptPath = Join-Path $ScriptRoot 'Jq-CLI\uninstall-jq.ps1';                       Category = 'VCS & Utilities' }
    [pscustomobject]@{ Id = 'Fzf';        Name = 'fzf (fuzzy finder)';         InstallDir = Join-Path $HOME '.local\fzf';         ScriptPath = Join-Path $ScriptRoot 'Fzf-CLI\uninstall-fzf.ps1';                     Category = 'VCS & Utilities' }
    [pscustomobject]@{ Id = 'Bat';        Name = 'bat (cat clone)';            InstallDir = Join-Path $HOME '.local\bat';         ScriptPath = Join-Path $ScriptRoot 'Bat-CLI\uninstall-bat.ps1';                     Category = 'VCS & Utilities' }
    [pscustomobject]@{ Id = 'Delta';      Name = 'git-delta (diff pager)';     InstallDir = Join-Path $HOME '.local\delta';       ScriptPath = Join-Path $ScriptRoot 'Delta-CLI\uninstall-delta.ps1';                 Category = 'VCS & Utilities' }
    [pscustomobject]@{ Id = 'Eza';        Name = 'eza (ls replacement)';       InstallDir = Join-Path $HOME '.local\eza';         ScriptPath = Join-Path $ScriptRoot 'Eza-CLI\uninstall-eza.ps1';                     Category = 'VCS & Utilities' }
    [pscustomobject]@{ Id = 'Cloudflared';Name = 'Cloudflare Tunnel CLI';      InstallDir = Join-Path $HOME '.local\cloudflared'; ScriptPath = Join-Path $ScriptRoot 'Cloudflared-CLI\uninstall-cloudflared.ps1';   Category = 'VCS & Utilities' }

    # Editors & Development Environments
    [pscustomobject]@{ Id = 'VSCode';     Name = 'VS Code Portable';           InstallDir = Join-Path $HOME '.local\vscode';      ScriptPath = Join-Path $ScriptRoot 'VSCode-Installer\uninstall-vscode.ps1';         Category = 'Editors & IDEs' }

    # AI Developer CLIs & Agent Runtimes
    [pscustomobject]@{ Id = 'Cline';      Name = 'Cline CLI';                  InstallDir = Join-Path $HOME '.npm-global';        ScriptPath = Join-Path $ScriptRoot 'Cline-CLI\uninstall-cline.ps1';                 Category = 'AI CLI' }
    [pscustomobject]@{ Id = 'Hermes';     Name = 'Hermes Agent CLI';           InstallDir = Join-Path $HOME '.local\hermes';      ScriptPath = Join-Path $ScriptRoot 'Hermes-CLI\uninstall-hermes.ps1';               Category = 'AI CLI' }
    [pscustomobject]@{ Id = 'Vibe';       Name = 'Mistral Vibe CLI';           InstallDir = Join-Path $HOME '.local\vibe';        ScriptPath = Join-Path $ScriptRoot 'Vibe-CLI\uninstall-vibe.ps1';                   Category = 'AI CLI' }
    [pscustomobject]@{ Id = 'Ori';        Name = 'OpenRouter Ori CLI';         InstallDir = Join-Path $HOME '.local\ori';         ScriptPath = Join-Path $ScriptRoot 'Ori-CLI\uninstall-ori.ps1';                     Category = 'AI CLI' }
    [pscustomobject]@{ Id = 'Antigravity';Name = 'Google Antigravity CLI';     InstallDir = Join-Path $HOME '.local\antigravity'; ScriptPath = Join-Path $ScriptRoot 'Antigravity-CLI\uninstall-antigravity.ps1'; Category = 'AI CLI' }
    [pscustomobject]@{ Id = 'Copilot';    Name = 'GitHub Copilot CLI';         InstallDir = Join-Path $HOME '.npm-global';        ScriptPath = Join-Path $ScriptRoot 'Copilot-CLI\uninstall-copilot.ps1';             Category = 'AI CLI' }
    [pscustomobject]@{ Id = 'Claude';     Name = 'Claude Code CLI';            InstallDir = Join-Path $HOME '.npm-global';        ScriptPath = Join-Path $ScriptRoot 'Claude-CLI\uninstall-claude.ps1';               Category = 'AI CLI' }
    [pscustomobject]@{ Id = 'Aider';      Name = 'Aider CLI';                  InstallDir = Join-Path $HOME '.local\aider';       ScriptPath = Join-Path $ScriptRoot 'Aider-CLI\uninstall-aider.ps1';                 Category = 'AI CLI' }
    [pscustomobject]@{ Id = 'Uv';         Name = 'uv (Python manager)';        InstallDir = Join-Path $HOME '.local\uv';          ScriptPath = Join-Path $ScriptRoot 'Uv-CLI\uninstall-uv.ps1';                       Category = 'AI CLI' }
    [pscustomobject]@{ Id = 'Herdr';      Name = 'Herdr Agent Runtime (hc)';   InstallDir = Join-Path $HOME '.local\herdr';       ScriptPath = Join-Path $ScriptRoot 'Herdr-CLI\uninstall-herdr.ps1';                 Category = 'AI CLI' }
    # Package Managers
    [pscustomobject]@{ Id = 'Chocolatey'; Name = 'Chocolatey Non-Admin';       InstallDir = Join-Path $HOME '.local\chocolatey';  ScriptPath = Join-Path $ScriptRoot 'Chocolatey-Installer\uninstall-chocolatey.ps1'; Category = 'Package Managers' }
    [pscustomobject]@{ Id = 'Scoop';      Name = 'Scoop Package Manager';      InstallDir = if ($env:SCOOP) { $env:SCOOP } else { Join-Path $HOME 'scoop' }; ScriptPath = Join-Path $ScriptRoot 'Scoop-Installer\uninstall-scoop.ps1'; Category = 'Package Managers' }
)

function Show-Help {
    Write-Host
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host " UNIFIED NON-ADMIN TOOLCHAIN UNINSTALLER — HELP & EXAMPLES" -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host @"

SYNOPSIS:
  uninstall-all.ps1 [-All] [-CliTools] [-PackageManagers] [Specific Tool Flags...] [-KeepCache] [-List] [-Help]

DESCRIPTION:
  Removes installed non-administrator toolchains, restores User PATH automatically,
  creates timestamped pre-uninstallation backups in `$HOME\.local\environment-backups,
  and optionally purges download caches.

OPTIONS:
  -All             Uninstall all installed toolchains and utilities.
  -CliTools        Uninstall only the 9 AI Developer CLIs & agent runtimes.
  -PackageManagers Uninstall Chocolatey and Scoop package managers.
  -KeepCache       Do not remove cached zip files from `$HOME\Downloads.
  -List            List current installation status for all 35 tools.
  -Help            Show this detailed help manual.

EXAMPLES:
  1. Show what is currently installed:
     .\uninstall-all.ps1 -List

  2. Uninstall specific tools:
     .\uninstall-all.ps1 -Git -VSCode -Cmake

  3. Uninstall all tools cleanly:
     .\uninstall-all.ps1 -All

"@
}

if ($Help) {
    Show-Help
    exit 0
}

if ($List) {
    Write-Host
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " INSTALLED TOOLCHAIN STATUS" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host

    $CurrentCat = ''
    foreach ($Item in $ToolchainRegistry) {
        if ($Item.Category -ne $CurrentCat) {
            $CurrentCat = $Item.Category
            Write-Host "--- $CurrentCat Tools ---" -ForegroundColor Yellow
        }

        $Installed = Test-Path -LiteralPath $Item.InstallDir
        $StatusBadge = if ($Installed) { "[INSTALLED]" } else { "[NOT INSTALLED]" }
        $Color = if ($Installed) { "Green" } else { "DarkGray" }

        Write-Host "  $($Item.Id.PadRight(12)) " -NoNewline -ForegroundColor Cyan
        Write-Host "$StatusBadge ".PadRight(18) -NoNewline -ForegroundColor $Color
        Write-Host "$($Item.Name)" -ForegroundColor White
    }
    exit 0
}

$SelectedIds = [Collections.Generic.List[string]]::new()

if ($All) {
    $ToolchainRegistry | ForEach-Object { $SelectedIds.Add($_.Id) }
}
elseif ($CliTools) {
    @('Cline', 'Hermes', 'Vibe', 'Ori', 'Antigravity', 'Copilot', 'Claude', 'Aider', 'Herdr') | ForEach-Object { $SelectedIds.Add($_) }
}
else {
    if ($Gpg4win)     { $SelectedIds.Add('Gpg4win') }
    if ($KeePassXC)   { $SelectedIds.Add('KeePassXC') }
    if ($MSYS2)       { $SelectedIds.Add('MSYS2') }
    if ($Rust)        { $SelectedIds.Add('Rust') }
    if ($Go)          { $SelectedIds.Add('Go') }
    if ($Node)        { $SelectedIds.Add('Node') }
    if ($Python)      { $SelectedIds.Add('Python') }
    if ($Bun)         { $SelectedIds.Add('Bun') }
    if ($Deno)        { $SelectedIds.Add('Deno') }
    if ($Uv)          { $SelectedIds.Add('Uv') }
    if ($Cmake)       { $SelectedIds.Add('Cmake') }
    if ($Ninja)       { $SelectedIds.Add('Ninja') }
    if ($Git)         { $SelectedIds.Add('Git') }
    if ($Gh)          { $SelectedIds.Add('Gh') }
    if ($SevenZip)    { $SelectedIds.Add('SevenZip') }
    if ($Ripgrep)     { $SelectedIds.Add('Ripgrep') }
    if ($Fd)          { $SelectedIds.Add('Fd') }
    if ($Jq)          { $SelectedIds.Add('Jq') }
    if ($Fzf)         { $SelectedIds.Add('Fzf') }
    if ($Bat)         { $SelectedIds.Add('Bat') }
    if ($Delta)       { $SelectedIds.Add('Delta') }
    if ($Eza)         { $SelectedIds.Add('Eza') }
    if ($Cloudflared) { $SelectedIds.Add('Cloudflared') }
    if ($VSCode)      { $SelectedIds.Add('VSCode') }
    if ($Cline)       { $SelectedIds.Add('Cline') }
    if ($Hermes)      { $SelectedIds.Add('Hermes') }
    if ($Vibe)        { $SelectedIds.Add('Vibe') }
    if ($Ori)         { $SelectedIds.Add('Ori') }
    if ($Antigravity) { $SelectedIds.Add('Antigravity') }
    if ($Copilot)     { $SelectedIds.Add('Copilot') }
    if ($Claude)      { $SelectedIds.Add('Claude') }
    if ($Aider)       { $SelectedIds.Add('Aider') }
    if ($Herdr)       { $SelectedIds.Add('Herdr') }
    if ($Chocolatey)  { $SelectedIds.Add('Chocolatey') }
    if ($Scoop)       { $SelectedIds.Add('Scoop') }
    if ($PackageManagers) {
        $SelectedIds.Add('Chocolatey')
        $SelectedIds.Add('Scoop')
    }
}

if ($SelectedIds.Count -eq 0) {
    if ($NonInteractive -or [Console]::IsInputRedirected) {
        Write-Host "No tools specified for uninstallation. Use -Help or -List." -ForegroundColor Yellow
        exit 0
    }

    while ($true) {
        Clear-Host
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "     WINDOWS NON-ADMIN TOOLCHAIN UNINSTALLER" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host

        for ($i = 0; $i -lt $ToolchainRegistry.Count; $i++) {
            $Item = $ToolchainRegistry[$i]
            $Installed = Test-Path -LiteralPath $Item.InstallDir
            $Badge = if ($Installed) { "[INSTALLED]" } else { "[NOT INSTALLED]" }
            $BadgeColor = if ($Installed) { "Green" } else { "DarkGray" }
            $Num = ($i + 1).ToString().PadLeft(2)
            Write-Host "  [$Num] " -NoNewline -ForegroundColor White
            Write-Host "$($Item.Name.PadRight(28)) " -NoNewline -ForegroundColor White
            Write-Host $Badge -ForegroundColor $BadgeColor
        }

        Write-Host
        Write-Host "  [A]  Uninstall All Tools" -ForegroundColor Red
        Write-Host "  [C]  Uninstall All 9 AI Developer CLIs & Runtimes" -ForegroundColor Yellow
        Write-Host "  [L]  List Full Inventory" -ForegroundColor Cyan
        Write-Host "  [H]  View Help Manual" -ForegroundColor Cyan
        Write-Host "  [Q]  Quit" -ForegroundColor White
        Write-Host
        $Choice = Read-Host "Select a tool to uninstall (1-$($ToolchainRegistry.Count), A, C, L, H, Q)"

        if ($Choice -match '^\d+$' -and [int]$Choice -ge 1 -and [int]$Choice -le $ToolchainRegistry.Count) {
            $Index = [int]$Choice - 1
            $SelectedIds.Add($ToolchainRegistry[$Index].Id)
            break
        }
        elseif ($Choice -ieq 'A') {
            $ToolchainRegistry | ForEach-Object { $SelectedIds.Add($_.Id) }
            break
        }
        elseif ($Choice -ieq 'C') {
            @('Cline', 'Hermes', 'Vibe', 'Ori', 'Antigravity', 'Copilot', 'Claude', 'Aider', 'Herdr') | ForEach-Object { $SelectedIds.Add($_) }
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

Write-Host
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " TOOLCHAIN UNINSTALLATION STARTED" -ForegroundColor Cyan
Write-Host " Target Tools: $($SelectedIds -join ', ')" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

foreach ($Item in $ToolchainRegistry) {
    if (-not $SelectedIds.Contains($Item.Id)) { continue }

    if (-not (Test-Path -LiteralPath $Item.InstallDir)) {
        Write-Host "Skipping $($Item.Name) (not installed)." -ForegroundColor DarkGray
        continue
    }

    Write-Host
    Write-Host "==> Uninstalling $($Item.Name)..." -ForegroundColor Yellow
    $Params = @{}
    if ($KeepCache) { $Params['KeepCache'] = $true }

    try {
        $global:LASTEXITCODE = 0
        & $Item.ScriptPath @Params
        Write-Host "✓ $($Item.Name) uninstallation complete." -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Error uninstalling $($Item.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host
Write-Host "============================================================" -ForegroundColor Green
Write-Host "✓ UNINSTALLATION PROCESS COMPLETE" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "User PATH backups preserved in: $HOME\.local\environment-backups"
exit 0
