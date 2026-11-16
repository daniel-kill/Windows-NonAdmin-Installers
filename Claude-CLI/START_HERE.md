# 🚀 START HERE - Claude Code CLI Installation

Official documentation: [https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview](https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview)

## Overview

Claude Code is Anthropic's agentic coding tool that lives in your terminal, understands your codebase, edits files, executes tests, and automates git workflows.

## Prerequisites

- **Node.js:** Requires Node.js 20+. If missing, run `..\Node-Installer\install-node.ps1`.

## Quickstart

```powershell
.\install-claude.ps1
```

To force reinstall:
```powershell
.\install-claude.ps1 -Force
```

## What Gets Installed

- **Package:** `@anthropic-ai/claude-code` under `$HOME\.npm-global\`.
- **Launchers:** `claude.cmd`, `claude` in `$HOME\.npm-global\`.
- **User Environment:** Prepends `$HOME\.npm-global` to User `PATH`.
- **Elevation:** None required.

## Usage

```powershell
claude
claude "Explain how this repository is structured"
```
