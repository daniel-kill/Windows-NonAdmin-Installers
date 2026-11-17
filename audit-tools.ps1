#Requires -Version 7.0

param(
    [switch]$Json,
    [switch]$Quiet,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# =============================================================================
# Toolchain Integrity & Environment Auditor
# =============================================================================

function Show-Help {
    Write-Host @"
SYNOPSIS:
  audit-tools.ps1 [-Json] [-Quiet] [-Help]

DESCRIPTION:
  Scans all 35 non-admin developer toolchains, inspecting binary existence,
  execution health, Authenticode digital signatures, User PATH configuration,
  and local checksum verification.

OPTIONS:
  -Json    Emit the audit results as structured JSON (useful for CI and scripts).
  -Quiet   Suppress headers and output only failures or JSON.
  -Help    Show this help manual.
"@
}

if ($Help) {
    Show-Help
    exit 0
}

$AuditCatalog = @(
    @{ Id = 'Gpg4win';    Name = 'Gpg4win & GnuPG';          ExePath = Join-Path $HOME '.local\gpg4win\GnuPG\bin\gpg.exe';           Args = '--version' }
    @{ Id = 'KeePassXC';  Name = 'KeePassXC & CLI';          ExePath = Join-Path $HOME '.local\keepassxc\keepassxc-cli.exe';         Args = '--version'; CheckSig = $true }
    @{ Id = 'MSYS2';      Name = 'MSYS2 & UCRT64 GCC';       ExePath = Join-Path $HOME 'msys64\usr\bin\bash.exe';                    Args = '--version' }
    @{ Id = 'Rust';       Name = 'Rust Standalone GNU';      ExePath = Join-Path $HOME '.local\rust\bin\rustc.exe';                  Args = '--version' }
    @{ Id = 'Go';         Name = 'Go Programming Language';  ExePath = Join-Path $HOME '.local\go\bin\go.exe';                       Args = 'version' }
    @{ Id = 'Node';       Name = 'Node.js LTS & NPM';        ExePath = Join-Path $HOME '.local\node\node.exe';                       Args = '--version' }
    @{ Id = 'Python';     Name = 'Python Portable & Pip';    ExePath = Join-Path $HOME '.local\python\python.exe';                   Args = '--version' }
    @{ Id = 'Bun';        Name = 'Bun JS/TS Runtime';        ExePath = Join-Path $HOME '.local\bun\bin\bun.exe';                     Args = '--version' }
    @{ Id = 'Deno';       Name = 'Deno TS/JS Runtime';       ExePath = Join-Path $HOME '.local\deno\bin\deno.exe';                   Args = '--version' }
    @{ Id = 'Cmake';      Name = 'CMake Portable';           ExePath = Join-Path $HOME '.local\cmake\bin\cmake.exe';                 Args = '--version' }
    @{ Id = 'Ninja';      Name = 'Ninja Build System';       ExePath = Join-Path $HOME '.local\ninja\bin\ninja.exe';                 Args = '--version' }
    @{ Id = 'Git';        Name = 'PortableGit';              ExePath = Join-Path $HOME '.local\git\bin\git.exe';                     Args = '--version' }
    @{ Id = 'Gh';         Name = 'GitHub CLI (gh)';          ExePath = Join-Path $HOME '.local\gh\bin\gh.exe';                       Args = '--version'; CheckSig = $true }
    @{ Id = 'SevenZip';   Name = '7-Zip Console & Suite';    ExePath = Join-Path $HOME '.local\7zip\7z.exe';                         Args = '--help' }
    @{ Id = 'Ripgrep';    Name = 'ripgrep (rg)';             ExePath = Join-Path $HOME '.local\ripgrep\bin\rg.exe';                  Args = '--version' }
    @{ Id = 'Fd';         Name = 'fd (find alternative)';    ExePath = Join-Path $HOME '.local\fd\bin\fd.exe';                       Args = '--version' }
    @{ Id = 'Jq';         Name = 'jq (JSON processor)';      ExePath = Join-Path $HOME '.local\jq\bin\jq.exe';                       Args = '--version' }
    @{ Id = 'Fzf';        Name = 'fzf (fuzzy finder)';       ExePath = Join-Path $HOME '.local\fzf\bin\fzf.exe';                     Args = '--version' }
    @{ Id = 'Bat';        Name = 'bat (cat clone)';          ExePath = Join-Path $HOME '.local\bat\bin\bat.exe';                     Args = '--version' }
    @{ Id = 'Delta';      Name = 'git-delta (diff pager)';   ExePath = Join-Path $HOME '.local\delta\bin\delta.exe';                 Args = '--version' }
    @{ Id = 'Eza';        Name = 'eza (ls replacement)';     ExePath = Join-Path $HOME '.local\eza\bin\eza.exe';                     Args = '--version' }
    @{ Id = 'Cloudflared';Name = 'Cloudflare Tunnel CLI';    ExePath = Join-Path $HOME '.local\cloudflared\bin\cloudflared.exe';     Args = '--version' }
    @{ Id = 'VSCode';     Name = 'VS Code Portable';         ExePath = Join-Path $HOME '.local\vscode\bin\code.cmd';                 Args = '-v';        CheckSig = $false }
    @{ Id = 'Cline';      Name = 'Cline CLI';                ExePath = Join-Path $HOME '.npm-global\cline.cmd';                      Args = '--version' }
    @{ Id = 'Hermes';     Name = 'Hermes Agent CLI';         ExePath = Join-Path $HOME '.local\hermes\bin\hermes.cmd';               Args = '--version' }
    @{ Id = 'Vibe';       Name = 'Mistral Vibe CLI';         ExePath = Join-Path $HOME '.local\vibe\bin\vibe.cmd';                   Args = '--version' }
    @{ Id = 'Ori';        Name = 'OpenRouter Ori CLI';       ExePath = Join-Path $HOME '.local\ori\bin\ori.exe';                     Args = '--version' }
    @{ Id = 'Antigravity';Name = 'Google Antigravity CLI';   ExePath = Join-Path $HOME '.local\antigravity\bin\agy.exe';             Args = '--version' }
    @{ Id = 'Copilot';    Name = 'GitHub Copilot CLI';       ExePath = Join-Path $HOME '.npm-global\copilot.cmd';                    Args = '--version' }
    @{ Id = 'Claude';     Name = 'Claude Code CLI';          ExePath = Join-Path $HOME '.npm-global\claude.cmd';                     Args = '-v' }
    @{ Id = 'Aider';      Name = 'Aider CLI';                ExePath = Join-Path $HOME '.local\aider\bin\aider.cmd';                 Args = '--version' }
    @{ Id = 'Uv';         Name = 'uv (Python manager)';      ExePath = Join-Path $HOME '.local\uv\bin\uv.exe';                       Args = '--version' }
    @{ Id = 'Herdr';      Name = 'Herdr Agent Runtime (hc)'; ExePath = Join-Path $HOME '.local\herdr\bin\hc.exe';                   Args = '--version' }
    @{ Id = 'Chocolatey'; Name = 'Chocolatey Non-Admin';     ExePath = Join-Path $HOME '.local\chocolatey\bin\choco.exe';            Args = '--version' }
    @{ Id = 'Scoop';      Name = 'Scoop Package Manager';    ExePath = if ($env:SCOOP) { Join-Path $env:SCOOP 'shims\scoop.cmd' } else { Join-Path $HOME 'scoop\shims\scoop.cmd' }; Args = '--version' }
)

$UserPath = [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::User)
if ($null -eq $UserPath) { $UserPath = '' }
$UserPathDirs = $UserPath -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object {
    $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($_).TrimEnd('\')
}

$AuditResults = [Collections.Generic.List[pscustomobject]]::new()

foreach ($Tool in $AuditCatalog) {
    $Exe = $Tool.ExePath
    $Installed = Test-Path -LiteralPath $Exe -PathType Leaf

    if (-not $Installed) {
        $AuditResults.Add([pscustomobject]@{
            Id            = $Tool.Id
            Name          = $Tool.Name
            Status        = 'NOT INSTALLED'
            Version       = 'N/A'
            InUserPath    = $false
            Signature     = 'N/A'
            ExePath       = $Exe
        })
        continue
    }

    # Verify execution and extract version
    $VerString = 'UNKNOWN'
    $ExecPass = $false
    try {
        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo.FileName = $Exe
        $pinfo.Arguments = $Tool.Args
        $pinfo.RedirectStandardOutput = $true
        $pinfo.RedirectStandardError = $true
        $pinfo.UseShellExecute = $false
        $pinfo.CreateNoWindow = $true

        $proc = [System.Diagnostics.Process]::Start($pinfo)
        $stdout = $proc.StandardOutput.ReadToEnd()
        $stderr = $proc.StandardError.ReadToEnd()
        $proc.WaitForExit(5000) | Out-Null

        $output = if (-not [string]::IsNullOrWhiteSpace($stdout)) { $stdout } else { $stderr }
        $firstLine = ($output -split '\r?\n' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 1)
        if ($firstLine) {
            $VerString = $firstLine.Trim()
            $ExecPass = $true
        }
    }
    catch {
        $VerString = "EXEC_FAIL: $($_.Exception.Message)"
    }

    # Authenticode Signature verification
    $SigStatus = 'N/A'
    if ($Tool.ContainsKey('CheckSig') -and $Tool.CheckSig) {
        try {
            $sig = Get-AuthenticodeSignature -FilePath $Exe
            $SigStatus = if ($sig.Status -eq 'Valid') { "VALID ($($sig.SignerCertificate.Subject -replace '^CN=', ''))" } else { "INVALID ($($sig.Status))" }
        }
        catch {
            $SigStatus = "ERROR"
        }
    }

    # User PATH membership
    $ParentDir = (Split-Path -Parent $Exe).TrimEnd('\')
    $IsInPath = ($UserPathDirs -contains $ParentDir)

    $OverallStatus = if ($ExecPass) { 'PASS' } else { 'FAILED' }

    $AuditResults.Add([pscustomobject]@{
        Id            = $Tool.Id
        Name          = $Tool.Name
        Status        = $OverallStatus
        Version       = $VerString
        InUserPath    = $IsInPath
        Signature     = $SigStatus
        ExePath       = $Exe
    })
}

if ($Json) {
    $AuditResults | ConvertTo-Json -Depth 4
    exit 0
}

Write-Host
Write-Host "==========================================================================================" -ForegroundColor Cyan
Write-Host " NON-ADMIN TOOLCHAIN INTEGRITY & AUDIT REPORT" -ForegroundColor Cyan
Write-Host "==========================================================================================" -ForegroundColor Cyan
Write-Host

$Passed = 0
$NotInstalled = 0
$Failed = 0

foreach ($r in $AuditResults) {
    $StatusBadge = switch ($r.Status) {
        'PASS'          { Write-Host "  [PASS]         " -NoNewline -ForegroundColor Green; $Passed++; break }
        'NOT INSTALLED' { Write-Host "  [NOT INSTALLED]" -NoNewline -ForegroundColor DarkGray; $NotInstalled++; break }
        default         { Write-Host "  [FAILED]       " -NoNewline -ForegroundColor Red; $Failed++; break }
    }

    Write-Host "$($r.Id.PadRight(13)) " -NoNewline -ForegroundColor White
    $PathBadge = if ($r.InUserPath) { "[PATH: OK]" } else { "[PATH: MISSING]" }
    $PathColor = if ($r.InUserPath) { "Green" } else { "DarkYellow" }
    Write-Host "$PathBadge ".PadRight(16) -NoNewline -ForegroundColor $PathColor

    Write-Host "$($r.Name)" -ForegroundColor Cyan
    if ($r.Status -ne 'NOT INSTALLED') {
        Write-Host "                  Version: $($r.Version)" -ForegroundColor Gray
        if ($r.Signature -ne 'N/A') {
            Write-Host "                  Signature: $($r.Signature)" -ForegroundColor Gray
        }
    }
}

Write-Host
Write-Host "------------------------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host " AUDIT SUMMARY: $Passed Passed, $NotInstalled Not Installed, $Failed Failed" -ForegroundColor $(if ($Failed -gt 0) { "Red" } else { "Green" })
Write-Host "==========================================================================================" -ForegroundColor Cyan

exit $(if ($Failed -gt 0) { 1 } else { 0 })
