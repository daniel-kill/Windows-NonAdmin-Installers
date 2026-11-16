#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 2: Extract and install PortableGit under $HOME\.local\git
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$DownloadDir = Join-Path $HOME 'Downloads\PortableGit'
$InstallRoot = Join-Path $HOME '.local\git'
$GitExe = Join-Path $InstallRoot 'cmd\git.exe'

Write-Step 'Locating downloaded PortableGit archive'
$MetadataFile = Join-Path $DownloadDir 'release-info.json'
if (-not (Test-Path -LiteralPath $MetadataFile -PathType Leaf)) {
    throw "Release metadata missing: $MetadataFile. Run 01-download-git.ps1 first."
}

$Metadata = Get-Content -LiteralPath $MetadataFile -Raw | ConvertFrom-Json
$ArchivePath = Join-Path $DownloadDir $Metadata.FileName
if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf)) {
    throw "Archive missing: $ArchivePath. Run 01-download-git.ps1 first."
}

Write-Host "Archive found: $ArchivePath"

Write-Step 'Re-verifying archive SHA-256 hash'
$ActualHash = (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash.ToLowerInvariant()
if ($ActualHash -ne $Metadata.Sha256.ToLowerInvariant()) {
    throw "Archive SHA-256 mismatch! Expected $($Metadata.Sha256), got $ActualHash"
}
Write-Host "SHA-256 verification passed: $ActualHash" -ForegroundColor Green

Write-Step 'Checking target installation directory'
if (Test-Path -LiteralPath $InstallRoot) {
    if ($Force) {
        Write-Warning "Removing existing installation at: $InstallRoot"
        Remove-Item -LiteralPath $InstallRoot -Recurse -Force
    }
    else {
        throw "PortableGit is already installed at $InstallRoot. Use -Force to reinstall."
    }
}

New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null

Write-Step 'Extracting PortableGit distribution'
$SevenZipPath = Join-Path $HOME '.local\7zip\7z.exe'
if (Test-Path -LiteralPath $SevenZipPath -PathType Leaf) {
    Write-Host "Extracting via local 7z: $SevenZipPath"
    $P = Start-Process -FilePath $SevenZipPath -ArgumentList @('x', $ArchivePath, "-o$InstallRoot", '-y') -Wait -PassThru -NoNewWindow
    if ($P.ExitCode -ne 0) {
        throw "7z extraction failed with exit code $($P.ExitCode)"
    }
}
else {
    Write-Host "Extracting via 7z SFX self-extractor..."
    $P = Start-Process -FilePath $ArchivePath -ArgumentList @('-y', "-o$InstallRoot") -Wait -PassThru -NoNewWindow
    if ($P.ExitCode -ne 0) {
        throw "PortableGit SFX extraction failed with exit code $($P.ExitCode)"
    }
}

if (-not (Test-Path -LiteralPath $GitExe -PathType Leaf)) {
    throw "Failed to locate git.exe at: $GitExe"
}

$VersionOutput = & $GitExe --version
Write-Host "Execution Test: $VersionOutput" -ForegroundColor Green

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 2 COMPLETE: PortableGit Installed' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Installation: $InstallRoot"
Write-Host "Binary:       $GitExe"
Write-Host "Version:      $VersionOutput"
Write-Host
Write-Host 'The Windows PATH has not been modified yet. Run Step 3 to configure environment.'
