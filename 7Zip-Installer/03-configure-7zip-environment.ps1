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

$InstallRoot = Join-Path $HOME '.local\7zip'
$SevenZipExe = Join-Path $InstallRoot '7z.exe'
$BackupDir = Join-Path $InstallRoot 'environment-backups'

Write-Step 'Checking 7-Zip installation'
if (-not (Test-Path -LiteralPath $SevenZipExe -PathType Leaf)) {
    throw "7z.exe not found at: $SevenZipExe. Run 02-install-7zip.ps1 first."
}
Write-Host "7z binary: $SevenZipExe"

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
$TargetBin = Get-NormalizedPathEntry -Path $InstallRoot

foreach ($Entry in $ExistingEntries) {
    $Norm = Get-NormalizedPathEntry -Path $Entry
    if ($Norm -ne $TargetBin) {
        $FilteredEntries.Add($Entry)
    }
}

$NewEntries = @($InstallRoot) + $FilteredEntries.ToArray()
$NewUserPath = ($NewEntries -join ';')
[Environment]::SetEnvironmentVariable('Path', $NewUserPath, 'User')
Write-Host 'User PATH persistently updated.' -ForegroundColor Green

$env:PATH = "$InstallRoot;$env:PATH"

Write-Step 'Testing 7z CLI from refreshed PATH'
$HelpLine = & 7z --help | Select-Object -First 2
Write-Host "7-Zip execution: $($HelpLine -join ' ')" -ForegroundColor Green

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 3 COMPLETE: 7-Zip Environment Configured' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Install Root: $InstallRoot"
Write-Host "User PATH:    Prepended $InstallRoot"
Write-Host
Write-Host 'Restart any open terminal sessions to inherit the new user PATH.'
