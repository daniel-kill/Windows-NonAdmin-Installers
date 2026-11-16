#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 2: Install Gpg4win & GnuPG into user space ($HOME\.local\gpg4win)
#
# Parameters:
#   -Force: Remove any existing installation at $HOME\.local\gpg4win and reinstall.
#
# Technical Details:
#   Uses __COMPAT_LAYER=RunAsInvoker to execute the silent installer (/S)
#   under the standard user token without requesting administrator privileges or UAC.
#   Provisions both the GnuPG core engine ($HOME\.local\gpg4win\GnuPG\bin\gpg.exe)
#   and Gpg4win tools ($HOME\.local\gpg4win\Gpg4win\bin\kleopatra.exe).
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$DownloadDir = Join-Path $HOME 'Downloads\Gpg4win'
$InstallRoot = Join-Path $HOME '.local\gpg4win'
$Gpg4winSubDir = Join-Path $InstallRoot 'Gpg4win'
$GnuPgSubDir = Join-Path $InstallRoot 'GnuPG'
$GpgExe = Join-Path $GnuPgSubDir 'bin\gpg.exe'

Write-Step 'Checking target installation directory'

if (Test-Path -LiteralPath $InstallRoot) {
    if ($Force) {
        Write-Warning "Removing existing installation at: $InstallRoot"
        Remove-Item -LiteralPath $InstallRoot -Recurse -Force
    }
    else {
        throw "Gpg4win is already installed at $InstallRoot. Use -Force to reinstall."
    }
}

if (-not (Test-Path -LiteralPath $Gpg4winSubDir)) {
    New-Item -ItemType Directory -Path $Gpg4winSubDir -Force | Out-Null
}

$MetadataFile = Join-Path $DownloadDir 'release-info.json'
if (-not (Test-Path -LiteralPath $MetadataFile)) {
    throw "Metadata file missing. Run 01-download-gpg4win.ps1 first."
}

$Metadata = Get-Content -LiteralPath $MetadataFile -Raw | ConvertFrom-Json
$InstallerPath = Join-Path $DownloadDir $Metadata.FileName

if (-not (Test-Path -LiteralPath $InstallerPath)) {
    throw "Installer binary missing: $InstallerPath. Run 01-download-gpg4win.ps1 first."
}

Write-Step 'Re-verifying installer SHA-256'
$ActualHash = (Get-FileHash -LiteralPath $InstallerPath -Algorithm SHA256).Hash.ToLowerInvariant()
if ($ActualHash -ne $Metadata.Sha256.ToLowerInvariant()) {
    throw "SHA-256 mismatch before installation!"
}

Write-Step 'Executing non-admin silent installer'
Write-Host "Installer: $InstallerPath"
Write-Host "Target:    $Gpg4winSubDir"

$PreviousCompat = $env:__COMPAT_LAYER
try {
    # Suppress UAC prompt and run with user token
    $env:__COMPAT_LAYER = 'RunAsInvoker'

    $Proc = Start-Process `
        -FilePath $InstallerPath `
        -ArgumentList @('/S', "/D=$Gpg4winSubDir") `
        -Wait `
        -PassThru

    if ($Proc.ExitCode -ne 0) {
        throw "Installer exited with non-zero exit code: $($Proc.ExitCode)"
    }
}
finally {
    if ($null -eq $PreviousCompat) {
        Remove-Item Env:\__COMPAT_LAYER -ErrorAction SilentlyContinue
    }
    else {
        $env:__COMPAT_LAYER = $PreviousCompat
    }
}

# Allow file flush
Start-Sleep -Seconds 3

# Check for gpg.exe
if (-not (Test-Path -LiteralPath $GpgExe -PathType Leaf)) {
    # If GnuPG installed directly in Gpg4win\bin\gpg.exe or GnuPG\bin\gpg.exe
    $AltGpg = Join-Path $Gpg4winSubDir 'bin\gpg.exe'
    if (Test-Path -LiteralPath $AltGpg) {
        $GpgExe = $AltGpg
    }
    else {
        # Search anywhere inside InstallRoot
        $FoundGpg = Get-ChildItem -LiteralPath $InstallRoot -Filter 'gpg.exe' -Recurse | Select-Object -First 1
        if ($FoundGpg) {
            $GpgExe = $FoundGpg.FullName
        }
        else {
            throw "Installation completed but gpg.exe was not found under: $InstallRoot"
        }
    }
}

Write-Host "Found gpg.exe: $GpgExe" -ForegroundColor Green

Write-Step 'Verifying GnuPG binary execution'
$VersionOutput = & $GpgExe --version | Select-Object -First 1
Write-Host "Version output: $VersionOutput" -ForegroundColor Green

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 2 COMPLETE: Gpg4win & GnuPG Installed' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Location: $InstallRoot"
Write-Host "Binary:   $GpgExe"
Write-Host
Write-Host 'Run Step 3 to configure the user PATH.'
