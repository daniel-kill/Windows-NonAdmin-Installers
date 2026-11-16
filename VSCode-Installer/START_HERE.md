# 🚀 START HERE - VS Code Portable Installation

Official website: [https://code.visualstudio.com/](https://code.visualstudio.com/)  
Portable Mode docs: [https://code.visualstudio.com/docs/editor/portable](https://code.visualstudio.com/docs/editor/portable)

## Overview

Visual Studio Code is a lightweight but powerful code editor and development environment. This installer deploys the official 64-bit portable build into user space (`$HOME\.local\vscode`) with a dedicated `data/` directory.

In **Portable Mode**:
- Extensions, settings, workspace storage, and caches are kept strictly inside `$HOME\.local\vscode\data\`.
- Machine-wide `%APPDATA%` and the Windows registry remain completely untouched.

## Quickstart

```powershell
.\install-vscode.ps1
```

To force reinstall:
```powershell
.\install-vscode.ps1 -Force
```

## What Gets Installed

- **Location:** `$HOME\.local\vscode\`
- **Key Executables:** `Code.exe`, `bin\code.cmd`
- **Data Directory:** `$HOME\.local\vscode\data\`
- **User Environment:** Prepends `$HOME\.local\vscode\bin` to User `PATH`.
- **Integrity:** Windows Authenticode signed by `Microsoft Corporation`.
- **Elevation:** None required.

## Usage

```powershell
code .
code myfile.py
code --install-extension ms-python.python
```
