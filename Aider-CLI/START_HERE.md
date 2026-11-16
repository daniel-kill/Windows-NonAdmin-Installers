# 🚀 START HERE - Aider CLI Installation

Official website: [https://aider.chat/](https://aider.chat/)  
Official documentation: [https://aider.chat/docs/](https://aider.chat/docs/)

## Overview

Aider is an AI pair-programming tool in your terminal that allows you to edit code in your local git repository. It coordinates with Claude, DeepSeek, OpenAI, or local models to write and refactor code, run tests, and automatically create git commits.

## Prerequisites

- **Python:** Requires Python 3.10+. If missing, run `..\Python-Installer\install-python.ps1`.
- **Git:** Requires Git. If missing, run `..\PortableGit-Installer\install-git.ps1`.

## Quickstart

```powershell
.\install-aider.ps1
```

To force reinstall:
```powershell
.\install-aider.ps1 -Force
```

## What Gets Installed

- **Virtual Environment:** `$HOME\.local\aider\venv\`
- **Launcher Shim:** `aider.cmd` in `$HOME\.local\aider\bin\`
- **User Environment:** Prepends `$HOME\.local\aider\bin` to User `PATH`.
- **Elevation:** None required.

## Usage

```powershell
cd \path\to\your\repo
aider
aider --model openrouter/anthropic/claude-3.7-sonnet
```
