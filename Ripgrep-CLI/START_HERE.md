# 🚀 START HERE - ripgrep (rg) Installation

Official website: [https://github.com/BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep)

## Overview

`ripgrep` (`rg`) is an ultra-fast, line-oriented search tool that recursively searches current directories for regex patterns while respecting `.gitignore` rules.

## Quickstart

```powershell
.\install-ripgrep.ps1
```

To force reinstall:
```powershell
.\install-ripgrep.ps1 -Force
```

## What Gets Installed

- **Binary:** `rg.exe` under `$HOME\.local\ripgrep\bin\`.
- **User Environment:** Prepends `$HOME\.local\ripgrep\bin` to User `PATH`.
- **Integrity:** SHA-256 verified against official release checksums.
- **Elevation:** None required.

## Usage

```powershell
rg "search_pattern"
rg -t py "def my_function"
rg -i "case_insensitive"
```
