# 🚀 START HERE - jq Installation

Official website: [https://github.com/jqlang/jq](https://github.com/jqlang/jq)

## Overview

`jq` is a lightweight and flexible command-line JSON processor. It is like `sed` for JSON data—you can use it to slice, filter, map, and transform structured data.

## Quickstart

```powershell
.\install-jq.ps1
```

To force reinstall:
```powershell
.\install-jq.ps1 -Force
```

## What Gets Installed

- **Binary:** `jq.exe` under `$HOME\.local\jq\bin\`.
- **User Environment:** Prepends `$HOME\.local\jq\bin` to User `PATH`.
- **Integrity:** SHA-256 verified against release metadata.
- **Elevation:** None required.

## Usage

```powershell
Get-Content package.json | jq .name
curl.exe -s https://api.github.com/repos/jqlang/jq/releases/latest | jq '.tag_name, .assets[].name'
```
