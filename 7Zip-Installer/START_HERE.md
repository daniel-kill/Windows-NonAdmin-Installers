# 🚀 START HERE - 7-Zip Console Installation

Official website: [https://www.7-zip.org/](https://www.7-zip.org/)

## Overview

7-Zip is a file archiver with a high compression ratio. It supports 7z, XZ, BZIP2, GZIP, TAR, ZIP, WIM, AR, ARJ, CAB, CHM, CPIO, CramFS, DMG, EXT, FAT, GPT, HFS, IHEX, ISO, LZH, LZMA, MBR, MSI, NSIS, NTFS, QCOW2, RAR, RPM, SquashFS, UDF, UEFI, VDI, VHD, VHDX, VMDK, XAR, and Z.

## Quickstart

```powershell
.\install-7zip.ps1
```

To force reinstall:
```powershell
.\install-7zip.ps1 -Force
```

## What Gets Installed

- **Binaries:** `7z.exe`, `7z.dll`, `7zFM.exe`, `7zG.exe` under `$HOME\.local\7zip\`.
- **User Environment:** Prepends `$HOME\.local\7zip` to User `PATH`.
- **Method:** Non-elevated MSI administrative extraction (`msiexec /a`).
- **Elevation:** None required.

## Usage

```powershell
7z x archive.tar.xz
7z a -t7z archive.7z folder/
7z l archive.zip
```
