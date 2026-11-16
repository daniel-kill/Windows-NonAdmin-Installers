# 🚀 START HERE - GitHub CLI (gh) Installation

Official website: [https://cli.github.com/](https://cli.github.com/)  
Official repository: [https://github.com/cli/cli](https://github.com/cli/cli)

## Overview

The GitHub CLI (`gh`) brings pull requests, issues, releases, gists, and GitHub Actions workflows directly into your terminal.

## Quickstart

```powershell
.\install-gh.ps1
```

To force reinstall:
```powershell
.\install-gh.ps1 -Force
```

## What Gets Installed

- **Binary:** `gh.exe` under `$HOME\.local\gh\bin\`.
- **User Environment:** Prepends `$HOME\.local\gh\bin` to User `PATH`.
- **Integrity:** SHA-256 verified against official `checksums.txt` and Windows Authenticode signed by GitHub, Inc.
- **Elevation:** None required.

## Usage

```powershell
gh auth login
gh repo clone <repo>
gh issue list
gh pr create
```
