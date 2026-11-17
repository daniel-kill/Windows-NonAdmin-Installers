#Requires -Version 7.0

param(
    [switch]$KeepCache,
    [switch]$KeepBackups
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Uninstaller for uv Python Manager
# -----------------------------------------------------------------------------

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "UNINSTALLING UV PYTHON MANAGER" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

$InstallDir = $HOME\.local\uv
$DownloadDir = $HOME\Downloads\uv
$TargetPaths = @(
    "$HOME\.local\uv\bin",
    "$HOME\.local\uv"
)

# 1. Backup User PATH
$BackupDir = Join-Path $HOME '.local\environment-backups'
if (-not (Test-Path -LiteralPath $BackupDir -PathType Container)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}

$CurrentPath = [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::User)
if ($null -eq $CurrentPath) { $CurrentPath = '' }

$Timestamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$BackupFile = Join-Path $BackupDir "path-backup-pre-uninstall-Uv-CLI-$Timestamp.txt"
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

# 3. Update in-memory session PATH
$MemoryParts = $env:Path -split ';' | Where-Object {
    if ([string]::IsNullOrWhiteSpace($_)) { return $false }
    $Trimmed = $_.Trim().TrimEnd('\')
    return -not ($NormalizedTargets -contains $Trimmed)
}
$env:Path = $MemoryParts -join ';'

# 4. Remove installation directory
if (Test-Path -LiteralPath $InstallDir) {
    Write-Host "Removing installation directory: $InstallDir" -ForegroundColor Yellow
    Remove-Item -LiteralPath $InstallDir -Recurse -Force
    Write-Host "✓ Removed $InstallDir" -ForegroundColor Green
} else {
    Write-Host "Installation directory not present: $InstallDir" -ForegroundColor Gray
}

# 5. Remove download cache unless -KeepCache
if (-not $KeepCache -and $DownloadDir -and (Test-Path -LiteralPath $DownloadDir)) {
    Write-Host "Removing download cache: $DownloadDir" -ForegroundColor Yellow
    Remove-Item -LiteralPath $DownloadDir -Recurse -Force
    Write-Host "✓ Removed $DownloadDir" -ForegroundColor Green
}

Write-Host "✓ uv Python Manager uninstallation complete." -ForegroundColor Green
exit 0
