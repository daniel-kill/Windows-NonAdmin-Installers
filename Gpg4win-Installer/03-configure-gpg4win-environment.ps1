#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 3: Configure persistent user PATH for GnuPG and Gpg4win
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

$InstallRoot = Join-Path $HOME '.local\gpg4win'
$BackupDir = Join-Path $InstallRoot 'environment-backups'

Write-Step 'Locating GnuPG & Gpg4win binaries'

$GpgFile = Get-ChildItem -LiteralPath $InstallRoot -Filter 'gpg.exe' -Recurse | Select-Object -First 1
if (-not $GpgFile) {
    throw "gpg.exe not found in $InstallRoot. Run 02-install-gpg4win.ps1 first."
}

$GnuPgBinDir = $GpgFile.DirectoryName
Write-Host "GnuPG binary directory: $GnuPgBinDir"

$Gpg4winBinDir = Join-Path $InstallRoot 'Gpg4win\bin'

Write-Step 'Backing up persistent user PATH'

if (-not (Test-Path -LiteralPath $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}

$CurrentRawUserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($null -eq $CurrentRawUserPath) { $CurrentRawUserPath = '' }

$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$BackupFile = Join-Path $BackupDir "path-backup-gpg4win-$Timestamp.txt"
Set-Content -LiteralPath $BackupFile -Value $CurrentRawUserPath -Encoding utf8NoBOM
Write-Host "User PATH backup saved: $BackupFile"

Write-Step 'Updating persistent user PATH'

$ExistingEntries = Get-UniquePathEntries -PathValue $CurrentRawUserPath
$FilteredEntries = [Collections.Generic.List[string]]::new()

$TargetGnuPg = Get-NormalizedPathEntry -Path $GnuPgBinDir
$TargetGpg4win = if (Test-Path -LiteralPath $Gpg4winBinDir) { Get-NormalizedPathEntry -Path $Gpg4winBinDir } else { $null }

foreach ($Entry in $ExistingEntries) {
    $Norm = Get-NormalizedPathEntry -Path $Entry
    if ($Norm -ne $TargetGnuPg -and $Norm -ne $TargetGpg4win) {
        $FilteredEntries.Add($Entry)
    }
}

$AddDirs = @($GnuPgBinDir)
if ($TargetGpg4win) { $AddDirs += $Gpg4winBinDir }

$NewEntries = $AddDirs + $FilteredEntries.ToArray()
$NewUserPath = ($NewEntries -join ';')
[Environment]::SetEnvironmentVariable('Path', $NewUserPath, 'User')

$env:PATH = ($AddDirs -join ';') + ";$env:PATH"
Write-Host 'User PATH persistently updated.' -ForegroundColor Green

Write-Step 'Verifying GnuPG command execution'

$Ver = & $GpgFile.FullName --version | Select-Object -First 1
Write-Host "GPG Version: $Ver" -ForegroundColor Green

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 3 COMPLETE: Gpg4win Environment Configured' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "GnuPG Path:   $GnuPgBinDir"
if ($TargetGpg4win) {
    Write-Host "Gpg4win Path: $Gpg4winBinDir"
}
Write-Host
Write-Host 'GnuPG is now available in your user PATH!' -ForegroundColor Green
Write-Host 'Restart any open terminal sessions to inherit the new PATH.'
