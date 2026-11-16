#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 2: Extract and install VS Code in portable mode under $HOME\.local\vscode
#
# Official Portable Mode Spec:
# Creating a 'data' folder inside the VS Code root instructs VS Code to store
# all session data, user profiles, extensions, and cache strictly in that folder,
# keeping it 100% portable and isolated from %APPDATA% and registry.
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$DownloadDir = Join-Path $HOME 'Downloads\vscode'
$InstallRoot = Join-Path $HOME '.local\vscode'
$CodeExe = Join-Path $InstallRoot 'Code.exe'
$CodeCmd = Join-Path $InstallRoot 'bin\code.cmd'
$DataDir = Join-Path $InstallRoot 'data'

Write-Step 'Locating downloaded VS Code archive'
$MetadataFile = Join-Path $DownloadDir 'release-info.json'
if (-not (Test-Path -LiteralPath $MetadataFile -PathType Leaf)) {
    throw "Release metadata missing: $MetadataFile. Run 01-download-vscode.ps1 first."
}

$Metadata = Get-Content -LiteralPath $MetadataFile -Raw | ConvertFrom-Json
$ArchivePath = Join-Path $DownloadDir $Metadata.FileName
if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf)) {
    throw "Archive missing: $ArchivePath. Run 01-download-vscode.ps1 first."
}

Write-Host "Archive found: $ArchivePath"

Write-Step 'Checking target installation directory'
if (Test-Path -LiteralPath $InstallRoot) {
    if ($Force) {
        Write-Warning "Removing existing installation at: $InstallRoot"
        Remove-Item -LiteralPath $InstallRoot -Recurse -Force
    }
    else {
        throw "VS Code is already installed at $InstallRoot. Use -Force to reinstall."
    }
}

New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null

Write-Step 'Extracting VS Code distribution'
$SevenZipPath = Join-Path $HOME '.local\7zip\7z.exe'
if (Test-Path -LiteralPath $SevenZipPath -PathType Leaf) {
    Write-Host "Extracting via local 7z: $SevenZipPath"
    $P = Start-Process -FilePath $SevenZipPath -ArgumentList @('x', $ArchivePath, "-o$InstallRoot", '-y') -Wait -PassThru -NoNewWindow
    if ($P.ExitCode -ne 0) {
        throw "7z extraction failed with exit code $($P.ExitCode)"
    }
}
else {
    Write-Host "Extracting via Expand-Archive..."
    Expand-Archive -LiteralPath $ArchivePath -DestinationPath $InstallRoot -Force
}

Write-Step 'Configuring Portable Mode (data/ folder)'
if (-not (Test-Path -LiteralPath $DataDir -PathType Container)) {
    New-Item -ItemType Directory -Path $DataDir -Force | Out-Null
    Write-Host "Created portable data directory: $DataDir" -ForegroundColor Green
}

if (-not (Test-Path -LiteralPath $CodeExe -PathType Leaf)) {
    throw "Failed to locate Code.exe at: $CodeExe"
}

# Authenticode signature check
$Sig = Get-AuthenticodeSignature -LiteralPath $CodeExe
Write-Host "Authenticode Status: $($Sig.Status)"
if ($Sig.SignerCertificate) {
    Write-Host "Signer Subject: $($Sig.SignerCertificate.Subject)"
}

$VersionOutput = & $CodeCmd -v | Select-Object -First 1
Write-Host "Execution Test: $VersionOutput" -ForegroundColor Green

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 2 COMPLETE: VS Code Portable Installed' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Installation: $InstallRoot"
Write-Host "Data Folder:  $DataDir (Portable Mode Active)" -ForegroundColor Green
Write-Host "Version:      $VersionOutput"
Write-Host
Write-Host 'The Windows PATH has not been modified yet. Run Step 3 to configure environment.'
