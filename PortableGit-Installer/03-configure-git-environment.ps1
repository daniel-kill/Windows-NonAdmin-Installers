#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Get-NormalizedPathEntry {
    param([Parameter(Mandatory)][string]$Path)
    $Expanded = [Environment]::ExpandEnvironmentVariables($Path.Trim().Trim('"'))
    if ([string]::IsNullOrWhiteSpace($Expanded)) { return $null }
    try { return [IO.Path]::GetFullPath($Expanded).TrimEnd('\') } catch { return $Expanded.TrimEnd('\') }
}

function Get-UniquePathEntries {
    param([AllowNull()][string]$PathValue)
    $Results = [Collections.Generic.List[string]]::new()
    $Seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    if ([string]::IsNullOrWhiteSpace($PathValue)) { return @() }
    foreach ($Entry in ($PathValue -split ';')) {
        if ([string]::IsNullOrWhiteSpace($Entry)) { continue }
        $Trimmed = $Entry.Trim().Trim('"')
        if ([string]::IsNullOrWhiteSpace($Trimmed)) { continue }
        $Normalized = Get-NormalizedPathEntry -Path $Trimmed
        if ($Normalized -and $Seen.Add($Normalized)) { $Results.Add($Trimmed) }
    }
    return $Results.ToArray()
}

$InstallRoot = Join-Path $HOME '.local\git'
$GitCmdDir = Join-Path $InstallRoot 'cmd'
$GitExe = Join-Path $GitCmdDir 'git.exe'
$BackupDir = Join-Path $InstallRoot 'environment-backups'

Write-Step 'Checking PortableGit installation'
if (-not (Test-Path -LiteralPath $GitExe -PathType Leaf)) {
    throw "git.exe not found at: $GitExe. Run 02-install-git.ps1 first."
}
Write-Host "git binary: $GitExe"

Write-Step 'Backing up persistent user PATH'
if (-not (Test-Path -LiteralPath $BackupDir -PathType Container)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}
$CurrentRawUserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($null -eq $CurrentRawUserPath) { $CurrentRawUserPath = '' }
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$BackupFile = Join-Path $BackupDir "path-backup-$Timestamp.txt"
Set-Content -LiteralPath $BackupFile -Value $CurrentRawUserPath -Encoding utf8NoBOM
Write-Host "User PATH backup saved to: $BackupFile"

Write-Step 'Updating persistent user PATH'
$ExistingEntries = Get-UniquePathEntries -PathValue $CurrentRawUserPath
$FilteredEntries = [Collections.Generic.List[string]]::new()
$TargetBin = Get-NormalizedPathEntry -Path $GitCmdDir

foreach ($Entry in $ExistingEntries) {
    $Norm = Get-NormalizedPathEntry -Path $Entry
    if ($Norm -ne $TargetBin) {
        $FilteredEntries.Add($Entry)
    }
}

$NewEntries = @($GitCmdDir) + $FilteredEntries.ToArray()
$NewUserPath = ($NewEntries -join ';')
[Environment]::SetEnvironmentVariable('Path', $NewUserPath, 'User')
Write-Host 'User PATH persistently updated.' -ForegroundColor Green

$env:PATH = "$GitCmdDir;$env:PATH"

Write-Step 'Testing git CLI from refreshed PATH'
$VersionOutput = & git --version
if ($LASTEXITCODE -ne 0) {
    throw "git --version failed with exit code $LASTEXITCODE"
}
Write-Host "Git Version: $VersionOutput" -ForegroundColor Green

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 3 COMPLETE: PortableGit Environment Configured' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Install Root: $InstallRoot"
Write-Host "User PATH:    Prepended $GitCmdDir"
Write-Host
Write-Host 'Restart any open terminal sessions to inherit the new user PATH.'
