#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 3: Configure persistent user PATH for Playwright CLI and verify execution
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

$NpmGlobalDir = Join-Path $HOME '.npm-global'
$BackupDir = Join-Path $NpmGlobalDir 'environment-backups'

Write-Step 'Backing up persistent user PATH'

if (-not (Test-Path -LiteralPath $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}

$CurrentRawUserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($null -eq $CurrentRawUserPath) { $CurrentRawUserPath = '' }

$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$BackupFile = Join-Path $BackupDir "path-backup-playwright-$Timestamp.txt"
Set-Content -LiteralPath $BackupFile -Value $CurrentRawUserPath -Encoding utf8NoBOM
Write-Host "User PATH backup saved: $BackupFile"

Write-Step 'Updating persistent user PATH'

$ExistingEntries = Get-UniquePathEntries -PathValue $CurrentRawUserPath
$FilteredEntries = [Collections.Generic.List[string]]::new()
$TargetNpmGlobal = Get-NormalizedPathEntry -Path $NpmGlobalDir

foreach ($Entry in $ExistingEntries) {
    $Norm = Get-NormalizedPathEntry -Path $Entry
    if ($Norm -ne $TargetNpmGlobal) {
        $FilteredEntries.Add($Entry)
    }
}

$NewEntries = @($NpmGlobalDir) + $FilteredEntries.ToArray()
$NewUserPath = ($NewEntries -join ';')
[Environment]::SetEnvironmentVariable('Path', $NewUserPath, 'User')

$env:PATH = "$NpmGlobalDir;$env:PATH"
Write-Host 'User PATH persistently updated.' -ForegroundColor Green

Write-Step 'Verifying Playwright CLI execution'

$PlaywrightCmd = Join-Path $NpmGlobalDir 'playwright-cli.cmd'
if (Test-Path -LiteralPath $PlaywrightCmd) {
    Write-Host "Executing: playwright-cli --version"
    $Output = & $PlaywrightCmd --version
    Write-Host "Playwright CLI Version: $Output" -ForegroundColor Green
}
else {
    Write-Host "Checking playwright-cli command in refreshed PATH..."
    $Cmd = Get-Command playwright-cli -ErrorAction SilentlyContinue
    if ($Cmd) {
        $Output = & $Cmd.Source --version
        Write-Host "Playwright CLI Version: $Output" -ForegroundColor Green
    }
    else {
        Write-Warning "playwright-cli command not immediately resolvable. Restart your shell to refresh PATH."
    }
}

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 3 COMPLETE: Playwright CLI Environment Configured' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
