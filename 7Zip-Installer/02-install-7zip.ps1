#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 2: Extract and install 7-Zip under $HOME\.local\7zip
#
# Uses standard Windows non-admin MSI administrative extraction (msiexec /a).
# Zero elevation or UAC prompts required.
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$DownloadDir = Join-Path $HOME 'Downloads\7zip'
$InstallRoot = Join-Path $HOME '.local\7zip'
$SevenZipExe = Join-Path $InstallRoot '7z.exe'

Write-Step 'Locating downloaded 7-Zip MSI package'
$MetadataFile = Join-Path $DownloadDir 'release-info.json'
if (-not (Test-Path -LiteralPath $MetadataFile -PathType Leaf)) {
    throw "Release metadata missing: $MetadataFile. Run 01-download-7zip.ps1 first."
}

$Metadata = Get-Content -LiteralPath $MetadataFile -Raw | ConvertFrom-Json
$MsiPath = Join-Path $DownloadDir $Metadata.FileName
if (-not (Test-Path -LiteralPath $MsiPath -PathType Leaf)) {
    throw "MSI package missing: $MsiPath. Run 01-download-7zip.ps1 first."
}

Write-Host "Package found: $MsiPath"

Write-Step 'Checking target installation directory'
if (Test-Path -LiteralPath $InstallRoot) {
    if ($Force) {
        Write-Warning "Removing existing installation at: $InstallRoot"
        Remove-Item -LiteralPath $InstallRoot -Recurse -Force
    }
    else {
        throw "7-Zip is already installed at $InstallRoot. Use -Force to reinstall."
    }
}

New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null

Write-Step 'Extracting 7-Zip using non-elevated MSI extraction'
$TempExtract = Join-Path $env:TEMP ("7z-extract-" + [guid]::NewGuid().ToString('N'))

try {
    New-Item -ItemType Directory -Path $TempExtract -Force | Out-Null
    $Process = Start-Process -FilePath 'msiexec.exe' -ArgumentList @('/a', $MsiPath, '/qn', "TARGETDIR=$TempExtract") -Wait -PassThru

    if ($Process.ExitCode -ne 0) {
        throw "msiexec administrative extraction failed with exit code $($Process.ExitCode)"
    }

    $ExtractedFolder = Join-Path $TempExtract 'Files\7-Zip'
    if (-not (Test-Path -LiteralPath $ExtractedFolder -PathType Container)) {
        throw "Extraction did not produce expected 'Files\7-Zip' folder in: $TempExtract"
    }

    Write-Host "Deploying 7-Zip files to: $InstallRoot"
    Get-ChildItem -LiteralPath $ExtractedFolder | ForEach-Object {
        Move-Item -LiteralPath $_.FullName -Destination $InstallRoot -Force
    }
}
finally {
    if (Test-Path -LiteralPath $TempExtract) {
        Remove-Item -LiteralPath $TempExtract -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if (-not (Test-Path -LiteralPath $SevenZipExe -PathType Leaf)) {
    throw "Failed to locate 7z.exe in: $InstallRoot"
}

$HelpOutput = & $SevenZipExe --help | Select-Object -First 2
Write-Host "Execution Test: $($HelpOutput -join ' ')" -ForegroundColor Green

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 2 COMPLETE: 7-Zip Installed' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Binary: $SevenZipExe"
Write-Host
Write-Host 'The Windows PATH has not been modified yet. Run Step 3 to configure environment.'
