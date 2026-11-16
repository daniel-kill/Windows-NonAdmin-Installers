# 🚀 START HERE - Hermes Agent CLI Installation

Official documentation: [https://hermes-agent.nousresearch.com/docs/user-guide/cli](https://hermes-agent.nousresearch.com/docs/user-guide/cli)

## Overview

This directory provides a zero-administrator installation for the **Hermes Agent CLI** by Nous Research on Windows 10/11 using PowerShell 7. The CLI installs into an isolated user-local environment under `$HOME\.local\hermes`, requiring no administrative elevation or UAC prompts.

## Quickstart

```powershell
.\install-hermes.ps1
```

To force reinstall:
```powershell
.\install-hermes.ps1 -Force
```

## Prerequisites

- **Python:** Python 3.10+ and pip. If not yet installed, run:
  ```powershell
  cd ..\Python-Installer
  .\install-python.ps1
  ```

## Usage

After installation, open a new terminal window:

```powershell
# View Hermes CLI commands and options
hermes --help

# Start an interactive agent session
hermes
```
