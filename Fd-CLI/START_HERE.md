# 🚀 START HERE - fd Installation

Official website: [https://github.com/sharkdp/fd](https://github.com/sharkdp/fd)

## Overview

`fd` is a simple, fast, and user-friendly alternative to `find` / `dir /s`. It provides sensible defaults (colored output, respects `.gitignore`, regex and glob matching).

## Quickstart

```powershell
.\install-fd.ps1
```

To force reinstall:
```powershell
.\install-fd.ps1 -Force
```

## What Gets Installed

- **Binary:** `fd.exe` under `$HOME\.local\fd\bin\`.
- **User Environment:** Prepends `$HOME\.local\fd\bin` to User `PATH`.
- **Integrity:** SHA-256 verified against release metadata.
- **Elevation:** None required.

## Usage

```powershell
fd myfile
fd -e md
fd -H "hidden_pattern"
```
