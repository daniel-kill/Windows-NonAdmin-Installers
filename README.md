# Windows-NonAdmin-Installers

Automated, cryptographically authenticated, zero-administrator developer toolchain and AI CLI installers for Windows 10 and 11 (x86-64) built in PowerShell 7.

This repository provides reproducible, fully non-elevated installers for modern developer toolchains and AI coding agent CLIs. Every binary and archive is cryptographically verified (pinned OpenPGP signatures, official SHA-256 / SHA-512 release checksums, and Authenticode inspection) before extraction, and all components install strictly into the current user's profile (`$HOME\msys64` and `$HOME\.local\...`) without requiring UAC elevation or modifying machine-wide system state.

---

## Project Documents

- [Agent Guidelines](AGENTS.md) — Operational guidelines, signing requirements, docs & hardware snapshot locations.
- [Active Handoff](HANDOFF.md) — Current state, in-progress tasks, gotchas, and immediate next steps.
- [Project Roadmap](ROADMAP.md) — Architecture constraints, milestone phases, and future toolchain expansions.

---

## Supported Toolchains & AI CLIs

### Core Developer Toolchains
| Toolchain | Folder | Target Path | Key Components |
| :--- | :--- | :--- | :--- |
| **MSYS2 & UCRT64** | `MSYS2-Installer/` | `$HOME\msys64` | Bash, Pacman, UCRT64 GCC/G++, Binutils, Make, pkg-config |
| **Rust Standalone** | `Rust-Installer/` | `$HOME\.local\rust` | Rust stable GNU (`rustc`, `cargo`, `rustdoc`) linked to UCRT64 |
| **Go Toolchain** | `Go-Installer/` | `$HOME\.local\go` | Go compiler (`go.exe`), `gofmt.exe`, `GOPATH` (`$HOME\go`) |
| **Node.js LTS** | `Node-Installer/` | `$HOME\.local\node` | Node.js LTS (`node.exe`), `npm.cmd`, `npx.cmd`, `$HOME\.npm-global` |
| **Python Portable** | `Python-Installer/` | `$HOME\.local\python` | Python 3 embeddable runtime, bootstrapped `pip`, `Scripts\` |

### AI Developer CLIs
| Agent CLI | Folder | Source / Type | Target Path | Official Docs |
| :--- | :--- | :--- | :--- | :--- |
| **Cline CLI** | `Cline-CLI/` | npm (`cline`) | `$HOME\.npm-global` | [cline.bot/cli](https://cline.bot/cli) |
| **Hermes Agent** | `Hermes-CLI/` | Python (`hermes-agent`) | `$HOME\.local\hermes` | [hermes-agent.nousresearch.com](https://hermes-agent.nousresearch.com/docs/user-guide/cli) |
| **Mistral Vibe** | `Vibe-CLI/` | Python (`mistral-vibe`) | `$HOME\.local\vibe` | [chat.mistral.ai/code/extensions](https://chat.mistral.ai/code/extensions) |
| **OpenRouter Ori** | `Ori-CLI/` | Native x64 Binary | `$HOME\.local\ori\bin\ori.exe` | [openrouter.ai/ori](https://openrouter.ai/ori) |
| **Google Antigravity** | `Antigravity-CLI/` | Native x64 Binary | `$HOME\.local\antigravity\bin\agy.exe` | [antigravity.google/product/antigravity-cli](https://antigravity.google/product/antigravity-cli) |
| **GitHub Copilot** | `Copilot-CLI/` | npm (`@github/copilot`) | `$HOME\.npm-global` | [github.com/github/copilot-cli](https://github.com/github/copilot-cli) |

---

## Unified Multi-Toolchain CLI Runner (`install-all.ps1`)

The repository includes a top-level orchestrator script (`install-all.ps1`) featuring an interactive console menu, detailed help manual, and batch execution flags.

```powershell
# Show interactive console menu
.\install-all.ps1

# Display complete toolchain & CLI inventory status
.\install-all.ps1 -List

# Install all core toolchains and AI CLIs in one sequence
.\install-all.ps1 -All

# Install only the 6 AI Developer CLIs
.\install-all.ps1 -CliTools

# Selectively install specific tools
.\install-all.ps1 -Antigravity -Ori -Cline

# Force clean reinstallation
.\install-all.ps1 -All -Force

# View detailed help manual and examples
.\install-all.ps1 -Help
```

---

## Prerequisites & Requirements

- **Operating System:** Windows 10 or Windows 11 (64-bit x86-64).
- **Shell:** PowerShell 7.0 or later (`pwsh.exe`).
- **Permissions:** Standard User (no administrator / UAC elevation required).
- **Disk Space:** ~5–8 GB free space on an NTFS drive for all tools combined.
- **Dependencies:**
  - GnuPG (`gpg.exe`) available in `PATH` (e.g. from Gpg4win or Git for Windows).
  - Active internet connection for artifact downloads.
- **Path Rules:** Installation paths must not contain spaces, non-ASCII characters, or reparse points (symlinks/junctions).

---

## Quickstart

Run with execution policy bypass if scripts are restricted on your host:

```powershell
pwsh -ExecutionPolicy Bypass -File .\install-all.ps1 -All
```

Once installation finishes, close and reopen your terminal, CMD, Windows Terminal, or VS Code sessions so they inherit the updated **User PATH**.

---

## Modular Step-by-Step Execution

Each directory is completely self-contained and modular:

```powershell
# Core Toolchains
cd MSYS2-Installer;   .\install-msys2.ps1
cd ..\Rust-Installer;  .\install-rust.ps1
cd ..\Go-Installer;    .\install-go.ps1
cd ..\Node-Installer;  .\install-node.ps1
cd ..\Python-Installer;.\install-python.ps1

# AI Developer CLIs
cd ..\Cline-CLI;       .\install-cline.ps1
cd ..\Hermes-CLI;      .\install-hermes.ps1
cd ..\Vibe-CLI;        .\install-vibe.ps1
cd ..\Ori-CLI;         .\install-ori.ps1
cd ..\Antigravity-CLI; .\install-antigravity.ps1
cd ..\Copilot-CLI;     .\install-copilot.ps1
```

---

## Security & Verification Guarantees

| Property | Implementation Detail |
| :--- | :--- |
| **Privilege Model** | Zero elevation required. All operations scoped strictly to `$HOME` (`$HOME\msys64`, `$HOME\.local\...`, `$HOME\.npm-global`). |
| **GPG Fingerprint Pinning** | MSYS2 (`0EBF782C5D53F7E5FB02A66746BD761F7A49B0EC`) and Rust (`108F66205EAEB0AAA8DD5E1C85AB96E6FA1BE5FE`). |
| **Integrity Verification** | Detached OpenPGP signatures (`GOODSIG`/`VALIDSIG`), SHA-256 release digests (Go, Node, Python, Ori), SHA-512 (Antigravity), and Windows Authenticode signatures. |
| **Fail-Fast Safety** | Any verification failure halts immediately before extraction or execution. Partial installs are cleaned up on error. |
| **Environment Isolation** | User PATH changes are backed up with timestamped recovery files under each toolchain's `environment-backups/` folder. System/Machine PATH is never touched. |

---

## Troubleshooting

- **"File ... cannot be loaded because running scripts is disabled"**:
  Run PowerShell with execution policy bypass:
  ```powershell
  pwsh -ExecutionPolicy Bypass -File .\install-all.ps1 -All
  ```
- **"GnuPG was not found in PATH"**:
  Ensure `gpg.exe` is installed and accessible in your PATH. If you have Git for Windows installed, it is typically located at `C:\Program Files\Git\usr\bin\gpg.exe`.
- **"Command not found after install"**:
  Restart your terminal session to ensure the refreshed User PATH is loaded by your shell.
