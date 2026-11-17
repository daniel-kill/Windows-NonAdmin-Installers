#Requires -Version 7.0

param(
    [switch]$All,
    [switch]$CheckOnly,
    [switch]$CliTools,
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
    [switch]$Force,
    [switch]$Json,
    [switch]$List,
    [switch]$Help,
    [switch]$NonInteractive
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# =============================================================================
# Unified Non-Admin Developer Toolchain & CLI Upgrader & Upstream Auditor
# =============================================================================

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# -----------------------------------------------------------------------------
# GitHub & Network API Configuration
# -----------------------------------------------------------------------------
$GitHubToken = if ($env:GITHUB_TOKEN) { $env:GITHUB_TOKEN } else { (gh auth token 2>$null) }
$GitHubHeaders = @{ 'User-Agent' = 'NonAdmin-Toolchain-Upgrader/1.0' }
if ($GitHubToken) {
    $GitHubHeaders['Authorization'] = "Bearer $GitHubToken"
}

$DefaultWebHeaders = @{ 'User-Agent' = 'NonAdmin-Toolchain-Upgrader/1.0' }

# -----------------------------------------------------------------------------
# Toolchain Registry (33 tools across 6 categories)
# -----------------------------------------------------------------------------
$ToolchainRegistry = @(
    # Security & Prerequisites
    [pscustomobject]@{
        Id             = 'Gpg4win'
        Name           = 'Gpg4win & GnuPG'
        Category       = 'Security & Prerequisites'
        InstallDir     = Join-Path $HOME '.local\gpg4win'
        ScriptPath     = Join-Path $ScriptRoot 'Gpg4win-Installer\install-gpg4win.ps1'
        ExePath        = Join-Path $HOME '.local\gpg4win\GnuPG\bin\gpg.exe'
        VersionArgs    = '--version'
        VersionRegex   = '(?im)(?:gpg\s*\(GnuPG(?:/MacGPG2)?\)|GnuPG)\s*([0-9\.]+)'
        UpstreamType   = 'Gpg4win'
        UpstreamTarget = 'https://www.gpg4win.org/download.html'
    }
    [pscustomobject]@{
        Id             = 'KeePassXC'
        Name           = 'KeePassXC & CLI'
        Category       = 'Security & Prerequisites'
        InstallDir     = Join-Path $HOME '.local\keepassxc'
        ScriptPath     = Join-Path $ScriptRoot 'KeePassXC-Installer\install-keepassxc.ps1'
        ExePath        = Join-Path $HOME '.local\keepassxc\keepassxc-cli.exe'
        VersionArgs    = '--version'
        VersionRegex   = '(?im)keepassxc-cli\s*([0-9\.]+)'
        UpstreamType   = 'GitHub'
        UpstreamTarget = 'keepassxreboot/keepassxc'
    }

    # Core Toolchains
    [pscustomobject]@{
        Id             = 'MSYS2'
        Name           = 'MSYS2 & UCRT64 GCC'
        Category       = 'Core Toolchains'
        InstallDir     = Join-Path $HOME 'msys64'
        ScriptPath     = Join-Path $ScriptRoot 'MSYS2-Installer\install-msys2.ps1'
        ExePath        = Join-Path $HOME 'msys64\usr\bin\bash.exe'
        VersionArgs    = '--version'
        VersionRegex   = '(?im)version\s*([0-9]+(?:\.[0-9]+)+)'
        UpstreamType   = 'MSYS2'
        UpstreamTarget = 'https://repo.msys2.org/distrib/x86_64/'
    }
    [pscustomobject]@{
        Id             = 'Rust'
        Name           = 'Rust Standalone GNU'
        Category       = 'Core Toolchains'
        InstallDir     = Join-Path $HOME '.local\rust'
        ScriptPath     = Join-Path $ScriptRoot 'Rust-Installer\install-rust.ps1'
        ExePath        = Join-Path $HOME '.local\rust\bin\rustc.exe'
        VersionArgs    = '--version'
        VersionRegex   = '(?im)rustc\s*([0-9\.]+)'
        UpstreamType   = 'GitHub'
        UpstreamTarget = 'rust-lang/rust'
    }
    [pscustomobject]@{
        Id             = 'Go'
        Name           = 'Go Programming Language'
        Category       = 'Core Toolchains'
        InstallDir     = Join-Path $HOME '.local\go'
        ScriptPath     = Join-Path $ScriptRoot 'Go-Installer\install-go.ps1'
        ExePath        = Join-Path $HOME '.local\go\bin\go.exe'
        VersionArgs    = 'version'
        VersionRegex   = '(?im)go([0-9\.]+)'
        UpstreamType   = 'Go'
        UpstreamTarget = 'https://go.dev/dl/?mode=json'
    }
    [pscustomobject]@{
        Id             = 'Node'
        Name           = 'Node.js LTS & NPM'
        Category       = 'Core Toolchains'
        InstallDir     = Join-Path $HOME '.local\node'
        ScriptPath     = Join-Path $ScriptRoot 'Node-Installer\install-node.ps1'
        ExePath        = Join-Path $HOME '.local\node\node.exe'
        VersionArgs    = '--version'
        VersionRegex   = '(?im)v?([0-9\.]+)'
        UpstreamType   = 'Node'
        UpstreamTarget = 'https://nodejs.org/dist/index.json'
    }
    [pscustomobject]@{
        Id             = 'Python'
        Name           = 'Python Portable & Pip'
        Category       = 'Core Toolchains'
        InstallDir     = Join-Path $HOME '.local\python'
        ScriptPath     = Join-Path $ScriptRoot 'Python-Installer\install-python.ps1'
        ExePath        = Join-Path $HOME '.local\python\python.exe'
        VersionArgs    = '--version'
        VersionRegex   = '(?im)Python\s*([0-9\.]+)'
        UpstreamType   = 'Python'
        UpstreamTarget = 'https://www.python.org/downloads/windows/'
    }
    [pscustomobject]@{
        Id             = 'Bun'
        Name           = 'Bun JS/TS Runtime'
        Category       = 'Core Toolchains'
        InstallDir     = Join-Path $HOME '.local\bun'
        ScriptPath     = Join-Path $ScriptRoot 'Bun-CLI\install-bun.ps1'
        ExePath        = Join-Path $HOME '.local\bun\bin\bun.exe'
        VersionArgs    = '--version'
        VersionRegex   = '(?im)^([0-9\.]+)'
        UpstreamType   = 'GitHub'
        UpstreamTarget = 'oven-sh/bun'
    }
    [pscustomobject]@{
        Id             = 'Deno'
        Name           = 'Deno TS/JS Runtime'
        Category       = 'Core Toolchains'
        InstallDir     = Join-Path $HOME '.local\deno'
        ScriptPath     = Join-Path $ScriptRoot 'Deno-CLI\install-deno.ps1'
        ExePath        = Join-Path $HOME '.local\deno\bin\deno.exe'
        VersionArgs    = '--version'
        VersionRegex   = '(?im)deno\s*([0-9\.]+)'
        UpstreamType   = 'GitHub'
        UpstreamTarget = 'denoland/deno'
    }

    # Build Systems
    [pscustomobject]@{
        Id             = 'Cmake'
        Name           = 'CMake Portable'
        Category       = 'Build Systems'
        InstallDir     = Join-Path $HOME '.local\cmake'
        ScriptPath     = Join-Path $ScriptRoot 'CMake-Installer\install-cmake.ps1'
        ExePath        = Join-Path $HOME '.local\cmake\bin\cmake.exe'
        VersionArgs    = '--version'
        VersionRegex   = '(?im)cmake version\s*([0-9\.]+)'
        UpstreamType   = 'GitHub'
        UpstreamTarget = 'Kitware/CMake'
    }
    [pscustomobject]@{
        Id             = 'Ninja'
        Name           = 'Ninja Build System'
        Category       = 'Build Systems'
        InstallDir     = Join-Path $HOME '.local\ninja'
        ScriptPath     = Join-Path $ScriptRoot 'Ninja-Installer\install-ninja.ps1'
        ExePath        = Join-Path $HOME '.local\ninja\bin\ninja.exe'
        VersionArgs    = '--version'
        VersionRegex   = '(?im)^([0-9\.]+)'
        UpstreamType   = 'GitHub'
        UpstreamTarget = 'ninja-build/ninja'
    }

    # VCS & Core Utilities
    [pscustomobject]@{
        Id             = 'Git'
        Name           = 'PortableGit'
        Category       = 'VCS & Utilities'
        InstallDir     = Join-Path $HOME '.local\git'
        ScriptPath     = Join-Path $ScriptRoot 'PortableGit-Installer\install-git.ps1'
        ExePath        = Join-Path $HOME '.local\git\bin\git.exe'
        VersionArgs    = '--version'
        VersionRegex   = '(?im)git version\s*([0-9]+(?:\.[0-9]+)+)'
        UpstreamType   = 'GitHub'
        UpstreamTarget = 'git-for-windows/git'
    }
    [pscustomobject]@{
        Id             = 'Gh'
        Name           = 'GitHub CLI (gh)'
        Category       = 'VCS & Utilities'
        InstallDir     = Join-Path $HOME '.local\gh'
        ScriptPath     = Join-Path $ScriptRoot 'GitHub-CLI\install-gh.ps1'
        ExePath        = Join-Path $HOME '.local\gh\bin\gh.exe'
        VersionArgs    = '--version'
        VersionRegex   = '(?im)gh version\s*([0-9\.]+)'
        UpstreamType   = 'GitHub'
        UpstreamTarget = 'cli/cli'
    }
    [pscustomobject]@{
        Id             = 'SevenZip'
        Name           = '7-Zip Console & Suite'
        Category       = 'VCS & Utilities'
        InstallDir     = Join-Path $HOME '.local\7zip'
        ScriptPath     = Join-Path $ScriptRoot '7Zip-Installer\install-7zip.ps1'
        ExePath        = Join-Path $HOME '.local\7zip\7z.exe'
        VersionArgs    = '--help'
        VersionRegex   = '(?im)7-Zip\s*([0-9\.]+)'
        UpstreamType   = 'GitHub'
        UpstreamTarget = 'ip7z/7zip'
    }
    [pscustomobject]@{
        Id             = 'Ripgrep'
        Name           = 'ripgrep (rg)'
        Category       = 'VCS & Utilities'
        InstallDir     = Join-Path $HOME '.local\ripgrep'
        ScriptPath     = Join-Path $ScriptRoot 'Ripgrep-CLI\install-ripgrep.ps1'
        ExePath        = Join-Path $HOME '.local\ripgrep\bin\rg.exe'
        VersionArgs    = '--version'
        VersionRegex   = '(?im)ripgrep\s*([0-9\.]+)'
        UpstreamType   = 'GitHub'
        UpstreamTarget = 'BurntSushi/ripgrep'
    }
    [pscustomobject]@{
        Id             = 'Fd'
        Name           = 'fd (find alternative)'
        Category       = 'VCS & Utilities'
        InstallDir     = Join-Path $HOME '.local\fd'
        ScriptPath     = Join-Path $ScriptRoot 'Fd-CLI\install-fd.ps1'
        ExePath        = Join-Path $HOME '.local\fd\bin\fd.exe'
        VersionArgs    = '--version'
        VersionRegex   = '(?im)fd\s*([0-9\.]+)'
        UpstreamType   = 'GitHub'
        UpstreamTarget = 'sharkdp/fd'
    }
    [pscustomobject]@{
        Id             = 'Jq'
        Name           = 'jq (JSON processor)'
        Category       = 'VCS & Utilities'
        InstallDir     = Join-Path $HOME '.local\jq'
        ScriptPath     = Join-Path $ScriptRoot 'Jq-CLI\install-jq.ps1'
        ExePath        = Join-Path $HOME '.local\jq\bin\jq.exe'
        VersionArgs    = '--version'
        VersionRegex   = '(?im)jq-([0-9\.]+)'
        UpstreamType   = 'GitHub'
        UpstreamTarget = 'jqlang/jq'
    }
    [pscustomobject]@{
        Id             = 'Fzf'
        Name           = 'fzf (fuzzy finder)'
        Category       = 'VCS & Utilities'
        InstallDir     = Join-Path $HOME '.local\fzf'
        ScriptPath     = Join-Path $ScriptRoot 'Fzf-CLI\install-fzf.ps1'
        ExePath        = Join-Path $HOME '.local\fzf\bin\fzf.exe'
        VersionArgs    = '--version'
        VersionRegex   = '(?im)^([0-9\.]+)'
        UpstreamType   = 'GitHub'
        UpstreamTarget = 'junegunn/fzf'
    }
    [pscustomobject]@{
        Id             = 'Bat'
        Name           = 'bat (cat clone)'
        Category       = 'VCS & Utilities'
        InstallDir     = Join-Path $HOME '.local\bat'
        ScriptPath     = Join-Path $ScriptRoot 'Bat-CLI\install-bat.ps1'
        ExePath        = Join-Path $HOME '.local\bat\bin\bat.exe'
        VersionArgs    = '--version'
        VersionRegex   = '(?im)bat\s*([0-9\.]+)'
        UpstreamType   = 'GitHub'
        UpstreamTarget = 'sharkdp/bat'
    }
    [pscustomobject]@{
        Id             = 'Delta'
        Name           = 'git-delta (diff pager)'
        Category       = 'VCS & Utilities'
        InstallDir     = Join-Path $HOME '.local\delta'
        ScriptPath     = Join-Path $ScriptRoot 'Delta-CLI\install-delta.ps1'
        ExePath        = Join-Path $HOME '.local\delta\bin\delta.exe'
        VersionArgs    = '--version'
        VersionRegex   = '(?im)delta\s*([0-9\.]+)'
        UpstreamType   = 'GitHub'
        UpstreamTarget = 'dandavison/delta'
    }
    [pscustomobject]@{
        Id             = 'Eza'
        Name           = 'eza (ls replacement)'
        Category       = 'VCS & Utilities'
        InstallDir     = Join-Path $HOME '.local\eza'
        ScriptPath     = Join-Path $ScriptRoot 'Eza-CLI\install-eza.ps1'
        ExePath        = Join-Path $HOME '.local\eza\bin\eza.exe'
        VersionArgs    = '--version'
        VersionRegex   = '(?im)v?([0-9\.]+)'
        UpstreamType   = 'GitHub'
        UpstreamTarget = 'eza-community/eza'
    }
    [pscustomobject]@{
        Id             = 'Cloudflared'
        Name           = 'Cloudflare Tunnel CLI'
        Category       = 'VCS & Utilities'
        InstallDir     = Join-Path $HOME '.local\cloudflared'
        ScriptPath     = Join-Path $ScriptRoot 'Cloudflared-CLI\install-cloudflared.ps1'
        ExePath        = Join-Path $HOME '.local\cloudflared\bin\cloudflared.exe'
        VersionArgs    = '--version'
        VersionRegex   = '(?im)cloudflared version\s*([0-9\.]+)'
        UpstreamType   = 'GitHub'
        UpstreamTarget = 'cloudflare/cloudflared'
    }

    # Editors & IDEs
    [pscustomobject]@{
        Id             = 'VSCode'
        Name           = 'VS Code Portable'
        Category       = 'Editors & IDEs'
        InstallDir     = Join-Path $HOME '.local\vscode'
        ScriptPath     = Join-Path $ScriptRoot 'VSCode-Installer\install-vscode.ps1'
        ExePath        = Join-Path $HOME '.local\vscode\bin\code.cmd'
        VersionArgs    = '-v'
        VersionRegex   = '(?im)^([0-9\.]+)'
        UpstreamType   = 'GitHub'
        UpstreamTarget = 'microsoft/vscode'
    }

    # AI Developer CLIs
    [pscustomobject]@{
        Id             = 'Cline'
        Name           = 'Cline CLI'
        Category       = 'AI CLI'
        InstallDir     = Join-Path $HOME '.npm-global'
        ScriptPath     = Join-Path $ScriptRoot 'Cline-CLI\install-cline.ps1'
        ExePath        = Join-Path $HOME '.npm-global\cline.cmd'
        VersionArgs    = '--version'
        VersionRegex   = '(?im)^([0-9\.]+)'
        UpstreamType   = 'Npm'
        UpstreamTarget = 'cline'
    }
    [pscustomobject]@{
        Id             = 'Hermes'
        Name           = 'Hermes Agent CLI'
        Category       = 'AI CLI'
        InstallDir     = Join-Path $HOME '.local\hermes'
        ScriptPath     = Join-Path $ScriptRoot 'Hermes-CLI\install-hermes.ps1'
        ExePath        = Join-Path $HOME '.local\hermes\bin\hermes.cmd'
        VersionArgs    = '--version'
        VersionRegex   = '(?im)^([0-9\.]+)'
        UpstreamType   = 'PyPI'
        UpstreamTarget = 'hermes-agent'
    }
    [pscustomobject]@{
        Id             = 'Vibe'
        Name           = 'Mistral Vibe CLI'
        Category       = 'AI CLI'
        InstallDir     = Join-Path $HOME '.local\vibe'
        ScriptPath     = Join-Path $ScriptRoot 'Vibe-CLI\install-vibe.ps1'
        ExePath        = Join-Path $HOME '.local\vibe\bin\vibe.cmd'
        VersionArgs    = '--version'
        VersionRegex   = '(?im)^([0-9\.]+)'
        UpstreamType   = 'PyPI'
        UpstreamTarget = 'mistral-vibe'
    }
    [pscustomobject]@{
        Id             = 'Ori'
        Name           = 'OpenRouter Ori CLI'
        Category       = 'AI CLI'
        InstallDir     = Join-Path $HOME '.local\ori'
        ScriptPath     = Join-Path $ScriptRoot 'Ori-CLI\install-ori.ps1'
        ExePath        = Join-Path $HOME '.local\ori\bin\ori.exe'
        VersionArgs    = '--version'
        VersionRegex   = '(?im)^([0-9\.]+)'
        UpstreamType   = 'GitHub'
        UpstreamTarget = 'OpenRouterLabs/ori-releases'
    }
    [pscustomobject]@{
        Id             = 'Antigravity'
        Name           = 'Google Antigravity CLI'
        Category       = 'AI CLI'
        InstallDir     = Join-Path $HOME '.local\antigravity'
        ScriptPath     = Join-Path $ScriptRoot 'Antigravity-CLI\install-antigravity.ps1'
        ExePath        = Join-Path $HOME '.local\antigravity\bin\agy.exe'
        VersionArgs    = '--version'
        VersionRegex   = '(?im)^([0-9\.]+)'
        UpstreamType   = 'Agy'
        UpstreamTarget = 'https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/windows_amd64.json'
    }
    [pscustomobject]@{
        Id             = 'Copilot'
        Name           = 'GitHub Copilot CLI'
        Category       = 'AI CLI'
        InstallDir     = Join-Path $HOME '.npm-global'
        ScriptPath     = Join-Path $ScriptRoot 'Copilot-CLI\install-copilot.ps1'
        ExePath        = Join-Path $HOME '.npm-global\copilot.cmd'
        VersionArgs    = '--version'
        VersionRegex   = '(?im)^([0-9\.]+)'
        UpstreamType   = 'Npm'
        UpstreamTarget = '@github/copilot'
    }
    [pscustomobject]@{
        Id             = 'Claude'
        Name           = 'Claude Code CLI'
        Category       = 'AI CLI'
        InstallDir     = Join-Path $HOME '.npm-global'
        ScriptPath     = Join-Path $ScriptRoot 'Claude-CLI\install-claude.ps1'
        ExePath        = Join-Path $HOME '.npm-global\claude.cmd'
        VersionArgs    = '-v'
        VersionRegex   = '(?im)^([0-9\.]+)'
        UpstreamType   = 'Npm'
        UpstreamTarget = '@anthropic-ai/claude-code'
    }
    [pscustomobject]@{
        Id             = 'Aider'
        Name           = 'Aider CLI'
        Category       = 'AI CLI'
        InstallDir     = Join-Path $HOME '.local\aider'
        ScriptPath     = Join-Path $ScriptRoot 'Aider-CLI\install-aider.ps1'
        ExePath        = Join-Path $HOME '.local\aider\bin\aider.cmd'
        VersionArgs    = '--version'
        VersionRegex   = '(?im)^([0-9\.]+)'
        UpstreamType   = 'PyPI'
        UpstreamTarget = 'aider-chat'
    }
    [pscustomobject]@{
        Id             = 'Uv'
        Name           = 'uv (Python manager)'
        Category       = 'AI CLI'
        InstallDir     = Join-Path $HOME '.local\uv'
        ScriptPath     = Join-Path $ScriptRoot 'Uv-CLI\install-uv.ps1'
        ExePath        = Join-Path $HOME '.local\uv\bin\uv.exe'
        VersionArgs    = '--version'
        VersionRegex   = '(?im)uv\s*([0-9\.]+)'
        UpstreamType   = 'GitHub'
        UpstreamTarget = 'astral-sh/uv'
    }
    [pscustomobject]@{
        Id             = 'Herdr'
        Name           = 'Herdr Agent Runtime (hc)'
        Category       = 'AI CLI'
        InstallDir     = Join-Path $HOME '.local\herdr'
        ScriptPath     = Join-Path $ScriptRoot 'Herdr-CLI\install-herdr.ps1'
        ExePath        = Join-Path $HOME '.local\herdr\bin\hc.exe'
        VersionArgs    = '--version'
        VersionRegex   = '(?im)hc\s*([0-9\.]+)'
        UpstreamType   = 'Herdr'
        UpstreamTarget = 'https://releases.herdr.dev/core/latest.json'
    }
)

# -----------------------------------------------------------------------------
# Help Documentation
# -----------------------------------------------------------------------------
function Show-Help {
    Write-Host @"
==========================================================================================
 NON-ADMIN TOOLCHAIN UPGRADER & UPSTREAM INTEGRITY AUDITOR
==========================================================================================

SYNOPSIS:
  update-all.ps1 [-CheckOnly] [-All] [-CliTools] [-Force] [-Json] [-List] [-Help]
                 [-Gpg4win] [-KeePassXC] [-MSYS2] [-Rust] [-Go] [-Node] [-Python]
                 [-Bun] [-Deno] [-Uv] [-Cmake] [-Ninja]
                 [-Git] [-Gh] [-SevenZip] [-Ripgrep] [-Fd] [-Jq] [-Fzf] [-Bat] [-Delta] [-Eza] [-Cloudflared]
                 [-VSCode] [-Cline] [-Hermes] [-Vibe] [-Ori] [-Antigravity] [-Copilot] [-Claude] [-Aider] [-Herdr]

DESCRIPTION:
  Monitors, audits, and upgrades 33 user-space developer toolchains, utilities,
  editors, and AI developer CLIs without requiring administrative privileges.
  Audits local installations against upstream release feeds (GitHub, Npm, PyPI, Go, Node, Herdr).

OPTIONS:
  -CheckOnly        Audit upstream releases and display a comparative report without upgrading.
  -All              Upgrade all installed tools that are outdated.
  -CliTools         Target only the 9 AI Developer CLIs and agent runtimes.
  -Force            Force in-place reinstall/upgrade even if installed version matches upstream.
  -Json             Output status and version comparisons as structured JSON.
  -List             List all tracked toolchains and their upstream verification sources.
  -NonInteractive   Suppress interactive menus and proceed directly with command parameters.
  -Help             Show this manual.

EXAMPLES:
  # Check for updates across all 33 tools (dry-run audit):
  pwsh update-all.ps1 -CheckOnly

  # Upgrade all outdated tools:
  pwsh update-all.ps1 -All

  # Upgrade only outdated AI Developer CLIs:
  pwsh update-all.ps1 -CliTools

  # Force reinstall/upgrade of a specific tool:
  pwsh update-all.ps1 -Gh -Force
"@
}

if ($Help) {
    Show-Help
    exit 0
}

if ($List) {
    Write-Host
    Write-Host "==========================================================================================" -ForegroundColor Cyan
    Write-Host " REGISTERED TOOLCHAINS & UPSTREAM SOURCES (33 Tools)" -ForegroundColor Cyan
    Write-Host "==========================================================================================" -ForegroundColor Cyan
    $ToolchainRegistry | Format-Table -Property Id, Category, Name, UpstreamType, UpstreamTarget
    exit 0
}

# -----------------------------------------------------------------------------
# Helper Functions: Version Extraction & Upstream Querying
# -----------------------------------------------------------------------------

function Clean-VersionString([string]$val) {
    if ([string]::IsNullOrWhiteSpace($val)) { return 'UNKNOWN' }
    return ($val -replace '^[a-zA-Z_\-]+' -replace '^v', '').Trim()
}

function Get-LocalInstalledVersion($Tool) {
    if (-not (Test-Path -LiteralPath $Tool.ExePath -PathType Leaf)) {
        return 'N/A'
    }

    try {
        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo.FileName = $Tool.ExePath
        $pinfo.Arguments = $Tool.VersionArgs
        $pinfo.RedirectStandardOutput = $true
        $pinfo.RedirectStandardError = $true
        $pinfo.UseShellExecute = $false
        $pinfo.CreateNoWindow = $true

        $proc = [System.Diagnostics.Process]::Start($pinfo)
        $stdout = $proc.StandardOutput.ReadToEnd()
        $stderr = $proc.StandardError.ReadToEnd()
        $proc.WaitForExit(5000) | Out-Null

        $output = if (-not [string]::IsNullOrWhiteSpace($stdout)) { $stdout } else { $stderr }

        if ($output -match $Tool.VersionRegex) {
            return $Matches[1].Trim()
        }

        # Fallback to first line
        $first = ($output -split '\r?\n' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 1)
        if ($first -match '([0-9]+\.[0-9]+(?:\.[0-9]+)?)') {
            return $Matches[1].Trim()
        }

        return 'UNKNOWN'
    }
    catch {
        return 'EXEC_FAIL'
    }
}

function Get-UpstreamVersion($Tool) {
    try {
        switch ($Tool.UpstreamType) {
            'GitHub' {
                $url = "https://api.github.com/repos/$($Tool.UpstreamTarget)/releases/latest"
                $res = Invoke-RestMethod -Uri $url -Headers $GitHubHeaders -TimeoutSec 6
                return Clean-VersionString $res.tag_name
            }
            'Npm' {
                $url = "https://registry.npmjs.org/$($Tool.UpstreamTarget)/latest"
                $res = Invoke-RestMethod -Uri $url -Headers $DefaultWebHeaders -TimeoutSec 6
                return Clean-VersionString $res.version
            }
            'PyPI' {
                $url = "https://pypi.org/pypi/$($Tool.UpstreamTarget)/json"
                $res = Invoke-RestMethod -Uri $url -Headers $DefaultWebHeaders -TimeoutSec 6
                return Clean-VersionString $res.info.version
            }
            'Go' {
                $res = Invoke-RestMethod -Uri $Tool.UpstreamTarget -Headers $DefaultWebHeaders -TimeoutSec 6
                return Clean-VersionString $res[0].version
            }
            'Node' {
                $res = Invoke-RestMethod -Uri $Tool.UpstreamTarget -Headers $DefaultWebHeaders -TimeoutSec 6
                $lts = $res | Where-Object { $_.lts -ne $false } | Select-Object -First 1
                return Clean-VersionString $lts.version
            }
            'Gpg4win' {
                $html = (Invoke-WebRequest -Uri $Tool.UpstreamTarget -UseBasicParsing -TimeoutSec 6).Content
                if ($html -match 'gpg4win-(?<v>[0-9\.]+)\.exe') {
                    return $Matches['v']
                }
                return 'UNKNOWN'
            }
            'Python' {
                $html = (Invoke-WebRequest -Uri $Tool.UpstreamTarget -UseBasicParsing -TimeoutSec 6).Content
                if ($html -match 'python-(?<v>[0-9\.]+)-embed-amd64\.zip') {
                    return $Matches['v']
                }
                return 'UNKNOWN'
            }
            'MSYS2' {
                $html = (Invoke-WebRequest -Uri $Tool.UpstreamTarget -UseBasicParsing -TimeoutSec 6).Content
                if ($html -match 'msys2-base-x86_64-(?<d>\d{8})\.sfx\.exe') {
                    return $Matches['d']
                }
                return 'UNKNOWN'
            }
            'Agy' {
                $res = Invoke-RestMethod -Uri $Tool.UpstreamTarget -Headers $DefaultWebHeaders -TimeoutSec 6
                return Clean-VersionString $res.version
            }
            'Herdr' {
                $res = Invoke-RestMethod -Uri $Tool.UpstreamTarget -Headers $DefaultWebHeaders -TimeoutSec 6
                return Clean-VersionString $res.version
            }
            default {
                return 'UNKNOWN'
            }
        }
    }
    catch {
        return "UNKNOWN (Offline/RateLimit)"
    }
}

function Compare-Versions([string]$toolId, [string]$installed, [string]$upstream) {
    if ($installed -eq 'N/A') { return 'NOT INSTALLED' }
    if ($upstream -like 'UNKNOWN*') { return 'UNKNOWN' }
    if ($toolId -eq 'MSYS2' -and $installed -ne 'N/A') { return 'UP TO DATE' }
    if ($installed -eq $upstream) { return 'UP TO DATE' }

    # Normalize Git windows build suffix (e.g. 2.56.1.windows.1 -> 2.56.1)
    $instClean = ($installed -replace '\.windows\.\d+$', '' -replace '^[vV]', '').Trim()
    $upClean   = ($upstream -replace '\.windows\.\d+$', '' -replace '^[vV]', '').Trim()

    if ($instClean -eq $upClean) { return 'UP TO DATE' }

    # Attempt semantic version parse
    try {
        $instVer = [version]($instClean -replace '^([0-9]+(?:\.[0-9]+){1,3}).*$', '$1')
        $upVer   = [version]($upClean -replace '^([0-9]+(?:\.[0-9]+){1,3}).*$', '$1')

        if ($instVer -lt $upVer) { return 'OUTDATED' }
        if ($instVer -gt $upVer) { return 'NEWER' }
        return 'UP TO DATE'
    }
    catch {
        if ($installed -ne $upstream) { return 'OUTDATED' }
        return 'UP TO DATE'
    }
}

# -----------------------------------------------------------------------------
# Audit / Comparison Function
# -----------------------------------------------------------------------------
function Invoke-ToolchainAudit([array]$TargetCatalog) {
    $results = [Collections.Generic.List[pscustomobject]]::new()

    foreach ($Tool in $TargetCatalog) {
        $inst = Get-LocalInstalledVersion $Tool
        $up   = Get-UpstreamVersion $Tool
        $stat = Compare-Versions $Tool.Id $inst $up

        $results.Add([pscustomobject]@{
            Id               = $Tool.Id
            Name             = $Tool.Name
            Category         = $Tool.Category
            InstalledVersion = $inst
            UpstreamVersion  = $up
            Status           = $stat
            ScriptPath       = $Tool.ScriptPath
        })
    }

    return $results
}

# -----------------------------------------------------------------------------
# Upgrader Execution Engine
# -----------------------------------------------------------------------------
function Invoke-ToolUpgrade($ToolRecord, [bool]$ForceInstall) {
    Write-Host
    Write-Host "==========================================================================================" -ForegroundColor Cyan
    Write-Host " UPGRADING: $($ToolRecord.Name) ($($ToolRecord.Id))" -ForegroundColor Cyan
    Write-Host "==========================================================================================" -ForegroundColor Cyan
    Write-Host "  Installed Version: $($ToolRecord.InstalledVersion)"
    Write-Host "  Target Version:    $($ToolRecord.UpstreamVersion)"
    Write-Host "  Installer Script:  $($ToolRecord.ScriptPath)"
    Write-Host

    if (-not (Test-Path -LiteralPath $ToolRecord.ScriptPath -PathType Leaf)) {
        Write-Host "✗ Installer script not found: $($ToolRecord.ScriptPath)" -ForegroundColor Red
        return $false
    }

    $params = @{}
    if ($ForceInstall) {
        $params['Force'] = $true
    }

    try {
        $global:LASTEXITCODE = 0
        & $ToolRecord.ScriptPath @params
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Successfully upgraded $($ToolRecord.Name)!" -ForegroundColor Green
            return $true
        } else {
            Write-Host "✗ Upgrade failed for $($ToolRecord.Name) (Exit Code: $LASTEXITCODE)" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "✗ Upgrade error for $($ToolRecord.Name): $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# -----------------------------------------------------------------------------
# Selection Logic: Resolve Targets from Switches
# -----------------------------------------------------------------------------
$ExplicitFlags = @(
    'Gpg4win', 'KeePassXC', 'MSYS2', 'Rust', 'Go', 'Node', 'Python',
    'Bun', 'Deno', 'Uv', 'Cmake', 'Ninja',
    'Git', 'Gh', 'SevenZip', 'Ripgrep', 'Fd', 'Jq', 'Fzf', 'Bat', 'Delta', 'Eza', 'Cloudflared',
    'VSCode', 'Cline', 'Hermes', 'Vibe', 'Ori', 'Antigravity', 'Copilot', 'Claude', 'Aider', 'Herdr'
)

$SelectedToolIds = [Collections.Generic.List[string]]::new()

foreach ($Flag in $ExplicitFlags) {
    $val = Get-Variable -Name $Flag -ValueOnly -ErrorAction SilentlyContinue
    if ($val) {
        $SelectedToolIds.Add($Flag)
    }
}

if ($CliTools) {
    $CliIds = @('Cline', 'Hermes', 'Vibe', 'Ori', 'Antigravity', 'Copilot', 'Claude', 'Aider', 'Herdr')
    foreach ($id in $CliIds) {
        if (-not $SelectedToolIds.Contains($id)) {
            $SelectedToolIds.Add($id)
        }
    }
}

# Determine target set
$TargetTools = if ($All -or ($SelectedToolIds.Count -eq 0 -and ($CheckOnly -or $NonInteractive))) {
    $ToolchainRegistry
} elseif ($SelectedToolIds.Count -gt 0) {
    $ToolchainRegistry | Where-Object { $SelectedToolIds.Contains($_.Id) }
} else {
    $null
}

# -----------------------------------------------------------------------------
# Interactive Menu (When run without arguments)
# -----------------------------------------------------------------------------
if ($null -eq $TargetTools -and -not $CheckOnly -and -not $NonInteractive) {
    Write-Host
    Write-Host "==========================================================================================" -ForegroundColor Cyan
    Write-Host " NON-ADMIN TOOLCHAIN UPGRADER & UPSTREAM AUDITOR — INTERACTIVE MENU" -ForegroundColor Cyan
    Write-Host "==========================================================================================" -ForegroundColor Cyan
    Write-Host " 1) Check for Updates (Audit all 33 tools against upstream feeds)"
    Write-Host " 2) Check Updates for AI Developer CLIs only"
    Write-Host " 3) Upgrade All Outdated Tools (Auto-detect)"
    Write-Host " 4) Upgrade Outdated AI Developer CLIs"
    Write-Host " 5) Select a specific tool to upgrade"
    Write-Host " 6) Force Re-install / Upgrade a tool"
    Write-Host " 7) Exit"
    Write-Host

    $Choice = Read-Host "Select an option [1-7]"
    switch ($Choice) {
        '1' { $CheckOnly = $true; $TargetTools = $ToolchainRegistry }
        '2' { $CheckOnly = $true; $TargetTools = $ToolchainRegistry | Where-Object { $_.Category -eq 'AI CLI' } }
        '3' { $All = $true; $TargetTools = $ToolchainRegistry }
        '4' { $CliTools = $true; $TargetTools = $ToolchainRegistry | Where-Object { $_.Category -eq 'AI CLI' } }
        '5' {
            Write-Host
            for ($i = 0; $i -lt $ToolchainRegistry.Count; $i++) {
                Write-Host (" {0,2}) {1,-15} ({2})" -f ($i + 1), $ToolchainRegistry[$i].Id, $ToolchainRegistry[$i].Name)
            }
            $toolIdx = Read-Host "Enter tool number [1-$($ToolchainRegistry.Count)]"
            if ($toolIdx -match '^\d+$' -and [int]$toolIdx -ge 1 -and [int]$toolIdx -le $ToolchainRegistry.Count) {
                $TargetTools = @($ToolchainRegistry[[int]$toolIdx - 1])
            } else {
                Write-Host "Invalid selection. Exiting." -ForegroundColor Yellow
                exit 0
            }
        }
        '6' {
            Write-Host
            for ($i = 0; $i -lt $ToolchainRegistry.Count; $i++) {
                Write-Host (" {0,2}) {1,-15} ({2})" -f ($i + 1), $ToolchainRegistry[$i].Id, $ToolchainRegistry[$i].Name)
            }
            $toolIdx = Read-Host "Enter tool number to force upgrade [1-$($ToolchainRegistry.Count)]"
            if ($toolIdx -match '^\d+$' -and [int]$toolIdx -ge 1 -and [int]$toolIdx -le $ToolchainRegistry.Count) {
                $TargetTools = @($ToolchainRegistry[[int]$toolIdx - 1])
                $Force = $true
            } else {
                Write-Host "Invalid selection. Exiting." -ForegroundColor Yellow
                exit 0
            }
        }
        default {
            Write-Host "Exiting."
            exit 0
        }
    }
}

if ($null -eq $TargetTools -or $TargetTools.Count -eq 0) {
    $TargetTools = $ToolchainRegistry
}

# -----------------------------------------------------------------------------
# Execute Audit
# -----------------------------------------------------------------------------
if (-not $Json) {
    Write-Host
    Write-Host "==> Auditing toolchain releases against upstream feeds..." -ForegroundColor Cyan
}
$AuditRecords = Invoke-ToolchainAudit $TargetTools

if ($Json) {
    $AuditRecords | ConvertTo-Json -Depth 4
    exit 0
}

# Display Audit Table
Write-Host
Write-Host "====================================================================================================" -ForegroundColor Cyan
Write-Host " TOOLCHAIN RELEASE & UPSTREAM AUDIT REPORT" -ForegroundColor Cyan
Write-Host "====================================================================================================" -ForegroundColor Cyan
Write-Host (" {0,-14} {1,-18} {2,-18} {3,-16} {4}" -f "TOOL", "INSTALLED", "UPSTREAM", "STATUS", "NAME")
Write-Host " --------------------------------------------------------------------------------------------------" -ForegroundColor DarkGray

$OutdatedCount = 0
$UpToDateCount = 0
$NotInstalledCount = 0
$UnknownCount = 0

foreach ($r in $AuditRecords) {
    $StatusBadge = switch ($r.Status) {
        'UP TO DATE'    { $UpToDateCount++;    "[UP TO DATE]   " }
        'OUTDATED'      { $OutdatedCount++;    "[OUTDATED]     " }
        'NOT INSTALLED' { $NotInstalledCount++;"[NOT INSTALLED]" }
        'NEWER'         { "[NEWER/DEV]    " }
        default         { $UnknownCount++;     "[UNKNOWN]      " }
    }

    $StatusColor = switch ($r.Status) {
        'UP TO DATE'    { 'Green' }
        'OUTDATED'      { 'Yellow' }
        'NOT INSTALLED' { 'DarkGray' }
        'NEWER'         { 'Cyan' }
        default         { 'Red' }
    }

    Write-Host (" {0,-14} {1,-18} {2,-18} " -f $r.Id, $r.InstalledVersion, $r.UpstreamVersion) -NoNewline
    Write-Host ("{0,-16}" -f $StatusBadge) -NoNewline -ForegroundColor $StatusColor
    Write-Host $r.Name -ForegroundColor White
}

Write-Host " --------------------------------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host (" SUMMARY: {0} Up to Date, {1} Outdated, {2} Not Installed, {3} Unknown" -f $UpToDateCount, $OutdatedCount, $NotInstalledCount, $UnknownCount) -ForegroundColor $(if ($OutdatedCount -gt 0) { 'Yellow' } else { 'Green' })
Write-Host "====================================================================================================" -ForegroundColor Cyan

if ($CheckOnly) {
    Write-Host
    if ($OutdatedCount -gt 0) {
        Write-Host "💡 $OutdatedCount tools are outdated. Run 'pwsh update-all.ps1 -All' to upgrade." -ForegroundColor Yellow
    } else {
        Write-Host "✓ All inspected tools are fully up to date with upstream releases." -ForegroundColor Green
    }
    exit 0
}

# -----------------------------------------------------------------------------
# Execute Upgrades
# -----------------------------------------------------------------------------
$ToUpgrade = if ($Force) {
    $AuditRecords | Where-Object { $_.Status -ne 'NOT INSTALLED' }
} else {
    $AuditRecords | Where-Object { $_.Status -eq 'OUTDATED' }
}

if ($ToUpgrade.Count -eq 0) {
    Write-Host
    if ($Force) {
        Write-Host "No installed tools available to force upgrade." -ForegroundColor Yellow
    } else {
        Write-Host "✓ Nothing to upgrade! All installed tools are already up to date." -ForegroundColor Green
        Write-Host "  (Use -Force if you wish to reinstall/re-extract existing versions)." -ForegroundColor DarkGray
    }
    exit 0
}

Write-Host
Write-Host "==> Starting upgrade of $($ToUpgrade.Count) tool(s)..." -ForegroundColor Yellow

$SuccessCount = 0
$FailureCount = 0

foreach ($record in $ToUpgrade) {
    $ok = Invoke-ToolUpgrade -ToolRecord $record -ForceInstall $Force
    if ($ok) {
        $SuccessCount++
    } else {
        $FailureCount++
    }
}

Write-Host
Write-Host "==========================================================================================" -ForegroundColor Cyan
Write-Host " UPGRADE SUMMARY: $SuccessCount succeeded, $FailureCount failed" -ForegroundColor $(if ($FailureCount -gt 0) { 'Red' } else { 'Green' })
Write-Host "==========================================================================================" -ForegroundColor Cyan

exit $(if ($FailureCount -gt 0) { 1 } else { 0 })
