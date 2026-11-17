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
    [switch]$Playwright,
    [switch]$Chocolatey,
    [switch]$Scoop,
    [switch]$PackageManagers,
    [switch]$CliTools,
    [switch]$Force,
    [switch]$List,
    [switch]$Help,
    [switch]$NonInteractive
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# =============================================================================
# Unified Non-Admin Developer Toolchain & AI CLI Provisioner
# =============================================================================

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$ToolchainRegistry = @(
    # Prerequisite Dependencies & Security Toolchains
    [pscustomobject]@{
        Id          = 'Gpg4win'
        Name        = 'Gpg4win & GnuPG'
        InstallDir  = Join-Path $HOME '.local\gpg4win'
        ScriptPath  = Join-Path $ScriptRoot 'Gpg4win-Installer\install-gpg4win.ps1'
        Description = 'Official GnuPG cryptographic engine (gpg.exe) & Gpg4win tools'
        Category    = 'Security & Prerequisites'
    }
    [pscustomobject]@{
        Id          = 'KeePassXC'
        Name        = 'KeePassXC & CLI'
        InstallDir  = Join-Path $HOME '.local\keepassxc'
        ScriptPath  = Join-Path $ScriptRoot 'KeePassXC-Installer\install-keepassxc.ps1'
        Description = 'KeePassXC password manager, keepassxc-cli, and portable vault'
        Category    = 'Security & Prerequisites'
    }
    # Core Language Toolchains
    [pscustomobject]@{
        Id          = 'MSYS2'
        Name        = 'MSYS2 & UCRT64 GCC'
        InstallDir  = Join-Path $HOME 'msys64'
        ScriptPath  = Join-Path $ScriptRoot 'MSYS2-Installer\install-msys2.ps1'
        Description = 'Unix environment, UCRT64 GCC/G++, GNU binutils, Make, pkg-config'
        Category    = 'Core Toolchains'
    }
    [pscustomobject]@{
        Id          = 'Rust'
        Name        = 'Rust Standalone GNU'
        InstallDir  = Join-Path $HOME '.local\rust'
        ScriptPath  = Join-Path $ScriptRoot 'Rust-Installer\install-rust.ps1'
        Description = 'Official Rust GNU toolchain (rustc, cargo, rustdoc) linked to UCRT64'
        Category    = 'Core Toolchains'
    }
    [pscustomobject]@{
        Id          = 'Go'
        Name        = 'Go Programming Language'
        InstallDir  = Join-Path $HOME '.local\go'
        ScriptPath  = Join-Path $ScriptRoot 'Go-Installer\install-go.ps1'
        Description = 'Official Go compiler, tools, GOPATH setup, and standard libraries'
        Category    = 'Core Toolchains'
    }
    [pscustomobject]@{
        Id          = 'Node'
        Name        = 'Node.js LTS & NPM'
        InstallDir  = Join-Path $HOME '.local\node'
        ScriptPath  = Join-Path $ScriptRoot 'Node-Installer\install-node.ps1'
        Description = 'Node.js LTS runtime, npm package manager, and .npm-global setup'
        Category    = 'Core Toolchains'
    }
    [pscustomobject]@{
        Id          = 'Python'
        Name        = 'Python Portable & Pip'
        InstallDir  = Join-Path $HOME '.local\python'
        ScriptPath  = Join-Path $ScriptRoot 'Python-Installer\install-python.ps1'
        Description = 'Python 3 runtime, pip package manager, and site-packages setup'
        Category    = 'Core Toolchains'
    }
    [pscustomobject]@{
        Id          = 'Bun'
        Name        = 'Bun JS/TS Runtime'
        InstallDir  = Join-Path $HOME '.local\bun'
        ScriptPath  = Join-Path $ScriptRoot 'Bun-CLI\install-bun.ps1'
        Description = 'All-in-one JavaScript & TypeScript runtime, bundler, and package manager'
        Category    = 'Core Toolchains'
    }
    [pscustomobject]@{
        Id          = 'Deno'
        Name        = 'Deno TS/JS Runtime'
        InstallDir  = Join-Path $HOME '.local\deno'
        ScriptPath  = Join-Path $ScriptRoot 'Deno-CLI\install-deno.ps1'
        Description = 'Modern, secure TypeScript & JavaScript runtime with built-in tooling'
        Category    = 'Core Toolchains'
    }
    # Build Systems
    [pscustomobject]@{
        Id          = 'Cmake'
        Name        = 'CMake Portable'
        InstallDir  = Join-Path $HOME '.local\cmake'
        ScriptPath  = Join-Path $ScriptRoot 'CMake-Installer\install-cmake.ps1'
        Description = 'Official cross-platform build automation generator (cmake, ctest, cpack)'
        Category    = 'Build Systems'
    }
    [pscustomobject]@{
        Id          = 'Ninja'
        Name        = 'Ninja Build System'
        InstallDir  = Join-Path $HOME '.local\ninja'
        ScriptPath  = Join-Path $ScriptRoot 'Ninja-Installer\install-ninja.ps1'
        Description = 'Small build system with a focus on speed'
        Category    = 'Build Systems'
    }
    # VCS & Core Utilities
    [pscustomobject]@{
        Id          = 'Git'
        Name        = 'PortableGit'
        InstallDir  = Join-Path $HOME '.local\git'
        ScriptPath  = Join-Path $ScriptRoot 'PortableGit-Installer\install-git.ps1'
        Description = 'Official Git for Windows portable distribution with Git Bash'
        Category    = 'VCS & Utilities'
    }
    [pscustomobject]@{
        Id          = 'Gh'
        Name        = 'GitHub CLI (gh)'
        InstallDir  = Join-Path $HOME '.local\gh'
        ScriptPath  = Join-Path $ScriptRoot 'GitHub-CLI\install-gh.ps1'
        Description = 'Official GitHub CLI binary for issues, PRs, releases, and auth'
        Category    = 'VCS & Utilities'
    }
    [pscustomobject]@{
        Id          = 'SevenZip'
        Name        = '7-Zip Console & Suite'
        InstallDir  = Join-Path $HOME '.local\7zip'
        ScriptPath  = Join-Path $ScriptRoot '7Zip-Installer\install-7zip.ps1'
        Description = '7-Zip archiver CLI (7z.exe) and GUI via non-admin MSI extraction'
        Category    = 'VCS & Utilities'
    }
    [pscustomobject]@{
        Id          = 'Ripgrep'
        Name        = 'ripgrep (rg)'
        InstallDir  = Join-Path $HOME '.local\ripgrep'
        ScriptPath  = Join-Path $ScriptRoot 'Ripgrep-CLI\install-ripgrep.ps1'
        Description = 'Ultra-fast recursive regex search utility respecting .gitignore'
        Category    = 'VCS & Utilities'
    }
    [pscustomobject]@{
        Id          = 'Fd'
        Name        = 'fd (find alternative)'
        InstallDir  = Join-Path $HOME '.local\fd'
        ScriptPath  = Join-Path $ScriptRoot 'Fd-CLI\install-fd.ps1'
        Description = 'Fast, user-friendly alternative to find / dir /s'
        Category    = 'VCS & Utilities'
    }
    [pscustomobject]@{
        Id          = 'Jq'
        Name        = 'jq (JSON processor)'
        InstallDir  = Join-Path $HOME '.local\jq'
        ScriptPath  = Join-Path $ScriptRoot 'Jq-CLI\install-jq.ps1'
        Description = 'Command-line JSON processor and filter'
        Category    = 'VCS & Utilities'
    }
    [pscustomobject]@{
        Id          = 'Fzf'
        Name        = 'fzf (fuzzy finder)'
        InstallDir  = Join-Path $HOME '.local\fzf'
        ScriptPath  = Join-Path $ScriptRoot 'Fzf-CLI\install-fzf.ps1'
        Description = 'Interactive command-line fuzzy finder'
        Category    = 'VCS & Utilities'
    }
    [pscustomobject]@{
        Id          = 'Bat'
        Name        = 'bat (cat clone)'
        InstallDir  = Join-Path $HOME '.local\bat'
        ScriptPath  = Join-Path $ScriptRoot 'Bat-CLI\install-bat.ps1'
        Description = 'A cat clone with syntax highlighting and Git integration'
        Category    = 'VCS & Utilities'
    }
    [pscustomobject]@{
        Id          = 'Delta'
        Name        = 'git-delta (diff pager)'
        InstallDir  = Join-Path $HOME '.local\delta'
        ScriptPath  = Join-Path $ScriptRoot 'Delta-CLI\install-delta.ps1'
        Description = 'A syntax-highlighting pager for git, diff, and grep output'
        Category    = 'VCS & Utilities'
    }
    [pscustomobject]@{
        Id          = 'Eza'
        Name        = 'eza (ls replacement)'
        InstallDir  = Join-Path $HOME '.local\eza'
        ScriptPath  = Join-Path $ScriptRoot 'Eza-CLI\install-eza.ps1'
        Description = 'Modern, feature-rich replacement for ls and dir'
        Category    = 'VCS & Utilities'
    }
    [pscustomobject]@{
        Id          = 'Cloudflared'
        Name        = 'Cloudflare Tunnel CLI'
        InstallDir  = Join-Path $HOME '.local\cloudflared'
        ScriptPath  = Join-Path $ScriptRoot 'Cloudflared-CLI\install-cloudflared.ps1'
        Description = 'Cloudflare Tunnel daemon & CLI for non-admin localhost exposure'
        Category    = 'VCS & Utilities'
    }
    # Editors & IDEs
    [pscustomobject]@{
        Id          = 'VSCode'
        Name        = 'VS Code Portable'
        InstallDir  = Join-Path $HOME '.local\vscode'
        ScriptPath  = Join-Path $ScriptRoot 'VSCode-Installer\install-vscode.ps1'
        Description = 'Official Visual Studio Code in self-contained portable mode (data/)'
        Category    = 'Editors & IDEs'
    }
    # AI Developer CLIs
    [pscustomobject]@{
        Id          = 'Cline'
        Name        = 'Cline CLI'
        InstallDir  = Join-Path $HOME '.npm-global'
        ScriptPath  = Join-Path $ScriptRoot 'Cline-CLI\install-cline.ps1'
        Description = 'Cline autonomous coding agent CLI via user npm prefix'
        Category    = 'AI CLI'
    }
    [pscustomobject]@{
        Id          = 'Hermes'
        Name        = 'Hermes Agent CLI'
        InstallDir  = Join-Path $HOME '.local\hermes'
        ScriptPath  = Join-Path $ScriptRoot 'Hermes-CLI\install-hermes.ps1'
        Description = 'Nous Research Hermes Agent terminal client'
        Category    = 'AI CLI'
    }
    [pscustomobject]@{
        Id          = 'Vibe'
        Name        = 'Mistral Vibe CLI'
        InstallDir  = Join-Path $HOME '.local\vibe'
        ScriptPath  = Join-Path $ScriptRoot 'Vibe-CLI\install-vibe.ps1'
        Description = 'Mistral AI Vibe coding assistant CLI'
        Category    = 'AI CLI'
    }
    [pscustomobject]@{
        Id          = 'Ori'
        Name        = 'OpenRouter Ori CLI'
        InstallDir  = Join-Path $HOME '.local\ori\bin\ori.exe'
        ScriptPath  = Join-Path $ScriptRoot 'Ori-CLI\install-ori.ps1'
        Description = 'OpenRouter Ori CLI native binary harness'
        Category    = 'AI CLI'
    }
    [pscustomobject]@{
        Id          = 'Antigravity'
        Name        = 'Google Antigravity CLI'
        InstallDir  = Join-Path $HOME '.local\antigravity\bin\agy.exe'
        ScriptPath  = Join-Path $ScriptRoot 'Antigravity-CLI\install-antigravity.ps1'
        Description = 'Google Antigravity CLI (agy) native agent binary'
        Category    = 'AI CLI'
    }
    [pscustomobject]@{
        Id          = 'Copilot'
        Name        = 'GitHub Copilot CLI'
        InstallDir  = Join-Path $HOME '.npm-global'
        ScriptPath  = Join-Path $ScriptRoot 'Copilot-CLI\install-copilot.ps1'
        Description = 'GitHub Copilot CLI (@github/copilot) via user npm prefix'
        Category    = 'AI CLI'
    }
    [pscustomobject]@{
        Id          = 'Claude'
        Name        = 'Claude Code CLI'
        InstallDir  = Join-Path $HOME '.npm-global'
        ScriptPath  = Join-Path $ScriptRoot 'Claude-CLI\install-claude.ps1'
        Description = 'Anthropic Claude Code CLI (@anthropic-ai/claude-code)'
        Category    = 'AI CLI'
    }
    [pscustomobject]@{
        Id          = 'Aider'
        Name        = 'Aider CLI'
        InstallDir  = Join-Path $HOME '.local\aider'
        ScriptPath  = Join-Path $ScriptRoot 'Aider-CLI\install-aider.ps1'
        Description = 'Aider AI terminal pair programmer in isolated virtualenv'
        Category    = 'AI CLI'
    }
    [pscustomobject]@{
        Id          = 'Uv'
        Name        = 'uv (Python manager)'
        InstallDir  = Join-Path $HOME '.local\uv'
        ScriptPath  = Join-Path $ScriptRoot 'Uv-CLI\install-uv.ps1'
        Description = 'Extremely fast Python package and virtualenv manager (uv & uvx)'
        Category    = 'AI CLI'
    }
    [pscustomobject]@{
        Id          = 'Herdr'
        Name        = 'Herdr Agent Runtime (hc)'
        InstallDir  = Join-Path $HOME '.local\herdr'
        ScriptPath  = Join-Path $ScriptRoot 'Herdr-CLI\install-herdr.ps1'
        Description = 'Persistent terminal runtime and agent workspace manager (hc.exe / herdr-core)'
        Category    = 'AI CLI'
    }
    [pscustomobject]@{
        Id          = 'Playwright'
        Name        = 'Playwright CLI'
        InstallDir  = Join-Path $HOME '.npm-global'
        ScriptPath  = Join-Path $ScriptRoot 'Playwright-CLI\install-playwright.ps1'
        Description = 'Microsoft Playwright CLI for AI coding agents (@playwright/cli)'
        Category    = 'AI CLI'
    }
    # Package Managers
    [pscustomobject]@{
        Id          = 'Chocolatey'
        Name        = 'Chocolatey Non-Admin'
        InstallDir  = Join-Path $HOME '.local\chocolatey'
        ScriptPath  = Join-Path $ScriptRoot 'Chocolatey-Installer\install-chocolatey.ps1'
        Description = 'Chocolatey user-local package manager for portable software'
        Category    = 'Package Managers'
    }
    [pscustomobject]@{
        Id          = 'Scoop'
        Name        = 'Scoop Package Manager'
        InstallDir  = if ($env:SCOOP) { $env:SCOOP } else { Join-Path $HOME 'scoop' }
        ScriptPath  = Join-Path $ScriptRoot 'Scoop-Installer\install-scoop.ps1'
        Description = 'Scoop user-mode command-line installer and bucket manager'
        Category    = 'Package Managers'
    }
)

function Show-Help {
    Write-Host
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host " UNIFIED NON-ADMIN TOOLCHAIN & AI CLI PROVISIONER — HELP & EXAMPLES" -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host @"

SYNOPSIS:
  install-all.ps1 [-All] [-CliTools] [-PackageManagers] [-Gpg4win] [-KeePassXC] [-MSYS2] [-Rust] [-Go] [-Node] [-Python]
                  [-Bun] [-Deno] [-Uv] [-Cmake] [-Ninja]
                  [-Git] [-Gh] [-SevenZip] [-Ripgrep] [-Fd] [-Jq] [-Fzf] [-Bat] [-Delta] [-Eza] [-Cloudflared]
                  [-VSCode] [-Cline] [-Hermes] [-Vibe] [-Ori] [-Antigravity] [-Copilot] [-Claude] [-Aider] [-Herdr] [-Playwright]
                  [-Chocolatey] [-Scoop]
                  [-Force] [-List] [-Help]

DESCRIPTION:
  Automates user-local, zero-administrator installation of developer toolchains,
  utilities, editors, and AI developer CLIs under Windows 10/11 x86-64 using PowerShell 7.
  All downloads are verified against cryptographic checksums and PGP signatures.

OPTIONS:
  -All             Install all available prerequisites, toolchains, utilities, and AI CLIs.
  -CliTools        Install only the 10 AI Developer CLIs & agent runtimes (Cline, Hermes, Vibe, Ori, Antigravity, Copilot, Claude, Aider, Herdr, Playwright).
  -PackageManagers Install both Chocolatey and Scoop package managers.
  -Gpg4win         Install Gpg4win and GnuPG (gpg.exe) into `$HOME\.local\gpg4win.
  -KeePassXC       Install KeePassXC GUI and keepassxc-cli into `$HOME\.local\keepassxc.
  -MSYS2           Install MSYS2 with UCRT64 GCC, Make, and binutils into `$HOME\msys64.
  -Rust            Install Rust standalone GNU toolchain into `$HOME\.local\rust.
  -Go              Install official Go compiler & tools into `$HOME\.local\go.
  -Node            Install Node.js LTS and NPM into `$HOME\.local\node.
  -Python          Install portable Python 3 with pip into `$HOME\.local\python.
  -Bun             Install Bun JS/TS runtime and package manager into `$HOME\.local\bun.
  -Deno            Install Deno secure TypeScript & JavaScript runtime into `$HOME\.local\deno.
  -Uv              Install Astral uv Python package manager into `$HOME\.local\uv.
  -Cmake           Install CMake Portable generator into `$HOME\.local\cmake.
  -Ninja           Install Ninja build system into `$HOME\.local\ninja.
  -Git             Install PortableGit with Git Bash into `$HOME\.local\git.
  -Gh              Install GitHub CLI (gh.exe) into `$HOME\.local\gh.
  -SevenZip        Install 7-Zip archiver CLI (7z.exe) into `$HOME\.local\7zip.
  -Ripgrep         Install ripgrep fast search (rg.exe) into `$HOME\.local\ripgrep.
  -Fd              Install fd finder (fd.exe) into `$HOME\.local\fd.
  -Jq              Install jq JSON processor (jq.exe) into `$HOME\.local\jq.
  -Fzf             Install fzf fuzzy finder into `$HOME\.local\fzf.
  -Bat             Install bat cat clone with syntax highlighting into `$HOME\.local\bat.
  -Delta           Install git-delta syntax pager into `$HOME\.local\delta.
  -Eza             Install eza modern ls replacement into `$HOME\.local\eza.
  -Cloudflared     Install Cloudflare Tunnel CLI into `$HOME\.local\cloudflared.
  -VSCode          Install Visual Studio Code portable into `$HOME\.local\vscode.
  -Cline           Install Cline CLI into `$HOME\.npm-global.
  -Hermes          Install Hermes Agent CLI into `$HOME\.local\hermes.
  -Vibe            Install Mistral Vibe CLI into `$HOME\.local\vibe.
  -Ori             Install OpenRouter Ori CLI into `$HOME\.local\ori.
  -Antigravity     Install Google Antigravity CLI (agy) into `$HOME\.local\antigravity.
  -Copilot         Install GitHub Copilot CLI into `$HOME\.npm-global.
  -Claude          Install Anthropic Claude Code CLI into `$HOME\.npm-global.
  -Aider           Install Aider terminal pair programmer into `$HOME\.local\aider.
  -Herdr           Install Herdr agent runtime and terminal manager (hc) into `$HOME\.local\herdr.
  -Playwright      Install Microsoft Playwright CLI for AI coding agents into `$HOME\.npm-global.
  -Chocolatey      Install Chocolatey non-admin package manager into `$HOME\.local\chocolatey.
  -Scoop           Install Scoop package manager into `$HOME\scoop.
  -Force           Force re-installation (removes existing directory before reinstalling).
  -List            Display the current installation status of all toolchains.
  -Help            Show this detailed help manual and usage examples.
  -NonInteractive  Do not prompt interactively if no flags are passed.

EXAMPLES:
  1. Display current toolchain inventory and status:
     .\install-all.ps1 -List

  2. Install Gpg4win prerequisite:
     .\install-all.ps1 -Gpg4win

  3. Install all toolchains and CLIs:
     .\install-all.ps1 -All

  4. Run with ExecutionPolicy bypass (recommended):
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
    Write-Host " AVAILABLE NON-ADMIN TOOLCHAINS & AI CLIS" -ForegroundColor Cyan
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
        $Color = if ($Installed) { "Green" } else { "DarkYellow" }

        Write-Host "  $($Item.Id.PadRight(12)) " -NoNewline -ForegroundColor Cyan
        Write-Host "$StatusBadge ".PadRight(18) -NoNewline -ForegroundColor $Color
        Write-Host "$($Item.Name)" -ForegroundColor White
        Write-Host "               Path: $($Item.InstallDir)" -ForegroundColor Gray
        Write-Host "               Desc: $($Item.Description)" -ForegroundColor Gray
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
elseif ($CliTools) {
    @('Cline', 'Hermes', 'Vibe', 'Ori', 'Antigravity', 'Copilot', 'Claude', 'Aider', 'Herdr', 'Playwright') | ForEach-Object { $SelectedIds.Add($_) }
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
    if ($Playwright)  { $SelectedIds.Add('Playwright') }
    if ($Chocolatey)  { $SelectedIds.Add('Chocolatey') }
    if ($Scoop)       { $SelectedIds.Add('Scoop') }
    if ($PackageManagers) {
        $SelectedIds.Add('Chocolatey')
        $SelectedIds.Add('Scoop')
    }
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
        Write-Host "   WINDOWS NON-ADMIN DEVELOPER TOOLCHAIN & CLI PROVISIONER" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host

        for ($i = 0; $i -lt $ToolchainRegistry.Count; $i++) {
            $Item = $ToolchainRegistry[$i]
            $Installed = Test-Path -LiteralPath $Item.InstallDir
            $Badge = if ($Installed) { "[INSTALLED]" } else { "[NOT INSTALLED]" }
            $BadgeColor = if ($Installed) { "Green" } else { "DarkYellow" }
            $Num = ($i + 1).ToString().PadLeft(2)
            Write-Host "  [$Num] " -NoNewline -ForegroundColor White
            Write-Host "$($Item.Name.PadRight(28)) " -NoNewline -ForegroundColor White
            Write-Host $Badge -ForegroundColor $BadgeColor
        }

        Write-Host
        Write-Host "  [A]  Install All Tools (Prerequisites + Toolchains + Utilities + CLIs)" -ForegroundColor Cyan
        Write-Host "  [C]  Install All 10 AI Developer CLIs & Agent Runtimes" -ForegroundColor Cyan
        Write-Host "  [L]  List Full Inventory" -ForegroundColor Cyan
        Write-Host "  [H]  View Detailed Help & Flags" -ForegroundColor Cyan
        Write-Host "  [Q]  Quit" -ForegroundColor Red
        Write-Host
        $Choice = Read-Host "Select an option (1-$($ToolchainRegistry.Count), A, C, L, H, Q)"

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
            @('Cline', 'Hermes', 'Vibe', 'Ori', 'Antigravity', 'Copilot', 'Claude', 'Aider', 'Herdr', 'Playwright') | ForEach-Object { $SelectedIds.Add($_) }
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

# Prerequisites check: GPG needed for MSYS2 and Rust
$HasGpgInPath = [bool](Get-Command gpg.exe -ErrorAction SilentlyContinue) -or [bool](Get-Command gpg -ErrorAction SilentlyContinue)
if (-not $HasGpgInPath -and ($SelectedIds.Contains('MSYS2') -or $SelectedIds.Contains('Rust'))) {
    if (-not $SelectedIds.Contains('Gpg4win')) {
        Write-Warning "GnuPG is not found in PATH and is required for signature verification. Automatically adding Gpg4win to installation queue."
        $SelectedIds.Insert(0, 'Gpg4win')
    }
}

# Dependency check: Rust requires MSYS2 UCRT64
if ($SelectedIds.Contains('Rust')) {
    $MSYS2Dir = Join-Path $HOME 'msys64'
    if (-not (Test-Path -LiteralPath $MSYS2Dir) -and -not $SelectedIds.Contains('MSYS2')) {
        Write-Warning "Rust toolchain requires MSYS2 UCRT64. Automatically adding MSYS2 to installation queue."
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
    Write-Host "• $($R.Name.PadRight(28)) " -NoNewline -ForegroundColor White
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
