#Requires -Version 7.0

param(
    [switch]$KeepCache,
    [switch]$KeepBackups
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Uninstaller for Scoop Package Manager
# -----------------------------------------------------------------------------

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "UNINSTALLING SCOOP NON-ADMIN" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

$InstallDir = if ($env:SCOOP) { $env:SCOOP } else { Join-Path $HOME 'scoop' }
$DownloadDir = Join-Path $HOME 'Downloads\scoop'
$TargetPaths = @(
    Join-Path $InstallDir 'shims',
    $InstallDir
)

# 1. Backup User PATH
$BackupDir = Join-Path $HOME '.local\environment-backups'
if (-not (Test-Path -LiteralPath $BackupDir -PathType Container)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}

$CurrentPath = [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::User)
if ($null -eq $CurrentPath) { $CurrentPath = '' }

$Timestamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$BackupFile = Join-Path $BackupDir "path-backup-pre-uninstall-Scoop-$Timestamp.txt"
$CurrentPath | Set-Content -LiteralPath $BackupFile -Encoding utf8
Write-Host "Current User PATH backed up to: $BackupFile" -ForegroundColor DarkGray

# 2. Clean User PATH
$NormalizedTargets = $TargetPaths | ForEach-Object {
    $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($_).TrimEnd('\')
}

$PathParts = $CurrentPath -split ';' | Where-Object {
    if ([string]::IsNullOrWhiteSpace($_)) { return $false }
    $Trimmed = $_.Trim().TrimEnd('\')
    return -not ($NormalizedTargets -contains $Trimmed)
}

$NewPath = $PathParts -join ';'
[Environment]::SetEnvironmentVariable('Path', $NewPath, [EnvironmentVariableTarget]::User)
Write-Host "Cleaned User PATH environment variable." -ForegroundColor Green

# 3. Remove User Environment Variable SCOOP
[Environment]::SetEnvironmentVariable('SCOOP', $null, [EnvironmentVariableTarget]::User)
$env:SCOOP = $null
Write-Host "Removed User Environment Variable: SCOOP" -ForegroundColor Green

# 4. Update in-memory session PATH
$MemoryParts = $env:Path -split ';' | Where-Object {
    if ([string]::IsNullOrWhiteSpace($_)) { return $false }
    $Trimmed = $_.Trim().TrimEnd('\')
    return -not ($NormalizedTargets -contains $Trimmed)
}
$env:Path = $MemoryParts -join ';'

# 5. Remove installation directory
if (Test-Path -LiteralPath $InstallDir) {
    Write-Host "Removing installation directory: $InstallDir" -ForegroundColor Yellow
    Remove-Item -LiteralPath $InstallDir -Recurse -Force
    Write-Host "✓ Removed $InstallDir" -ForegroundColor Green
} else {
    Write-Host "Installation directory not present: $InstallDir" -ForegroundColor Gray
}

# 6. Remove download cache unless -KeepCache
if (-not $KeepCache -and $DownloadDir -and (Test-Path -LiteralPath $DownloadDir)) {
    Write-Host "Removing download cache: $DownloadDir" -ForegroundColor Yellow
    Remove-Item -LiteralPath $DownloadDir -Recurse -Force
    Write-Host "✓ Removed $DownloadDir" -ForegroundColor Green
}

Write-Host "✓ Scoop non-admin uninstallation complete." -ForegroundColor Green
exit 0
