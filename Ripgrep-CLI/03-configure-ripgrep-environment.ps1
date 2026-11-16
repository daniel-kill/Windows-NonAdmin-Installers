#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 3: Configure persistent user environment for ripgrep and verify CLI
# -----------------------------------------------------------------------------

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

$InstallRoot = Join-Path $HOME '.local\ripgrep'
$BinDir = Join-Path $InstallRoot 'bin'
$RgExe = Join-Path $BinDir 'rg.exe'
$BackupDir = Join-Path $InstallRoot 'environment-backups'

Write-Step 'Checking ripgrep installation'
if (-not (Test-Path -LiteralPath $RgExe -PathType Leaf)) {
    throw "rg.exe not found at: $RgExe. Run 02-install-ripgrep.ps1 first."
}
Write-Host "rg binary: $RgExe"

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
$TargetBin = Get-NormalizedPathEntry -Path $BinDir

foreach ($Entry in $ExistingEntries) {
    $Norm = Get-NormalizedPathEntry -Path $Entry
    if ($Norm -ne $TargetBin) {
        $FilteredEntries.Add($Entry)
    }
}

$NewEntries = @($BinDir) + $FilteredEntries.ToArray()
$NewUserPath = ($NewEntries -join ';')
[Environment]::SetEnvironmentVariable('Path', $NewUserPath, 'User')
Write-Host 'User PATH persistently updated.' -ForegroundColor Green

$env:PATH = "$BinDir;$env:PATH"

Write-Step 'Testing rg CLI from refreshed PATH'
$VersionOutput = & rg --version | Select-Object -First 1
if ($LASTEXITCODE -ne 0) {
    throw "rg --version failed with exit code $LASTEXITCODE"
}
Write-Host "ripgrep Version: $VersionOutput" -ForegroundColor Green

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 3 COMPLETE: ripgrep Environment Configured' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Install Root: $InstallRoot"
Write-Host "User PATH:    Prepended $BinDir"
Write-Host
Write-Host 'Restart any open terminal sessions to inherit the new user PATH.'
