# Windows-NonAdmin-Installers

Automated, cryptographically authenticated, zero-administrator developer toolchain installers for Windows 10 and 11 (x86-64) built in PowerShell 7.

This repository provides reproducible, fully non-elevated installers for modern developer toolchains. Every binary and archive is cryptographically verified (pinned OpenPGP signatures, official SHA-256 release checksums, and Authenticode inspection) before extraction, and all components install strictly into the current user's profile (`$HOME\msys64` and `$HOME\.local\...`) without requiring UAC elevation or modifying machine-wide system state.

---

## Project Documents

- [Agent Guidelines](AGENTS.md) — Operational guidelines, signing requirements, docs & hardware snapshot locations.
- [Active Handoff](HANDOFF.md) — Current state, in-progress tasks, gotchas, and immediate next steps.
- [Project Roadmap](ROADMAP.md) — Architecture constraints, milestone phases, and future toolchain expansions.

---

## Toolchains Provided

| Toolchain | Folder | Target Path | Key Included Components |
| :--- | :--- | :--- | :--- |
| **MSYS2 & UCRT64** | `MSYS2-Installer/` | `$HOME\msys64` | Bash, Pacman, UCRT64 GCC/G++, Binutils, Make, pkg-config |
| **Rust Standalone** | `Rust-Installer/` | `$HOME\.local\rust` | Rust stable GNU (`rustc`, `cargo`, `rustdoc`) linked to UCRT64 |
| **Go Toolchain** | `Go-Installer/` | `$HOME\.local\go` | Go compiler (`go.exe`), `gofmt.exe`, `GOPATH` (`$HOME\go`) |
| **Node.js LTS** | `Node-Installer/` | `$HOME\.local\node` | Node.js LTS (`node.exe`), `npm.cmd`, `npx.cmd`, `$HOME\.npm-global` |
| **Python Portable** | `Python-Installer/` | `$HOME\.local\python` | Python 3 embeddable runtime, bootstrapped `pip`, `Scripts\` |

### 1. MSYS2 & UCRT64 GCC Toolchain (`MSYS2-Installer/`)
A complete Unix-like build environment and native Windows C/C++ compiler toolchain targeting the modern Universal C Runtime (UCRT).
- OpenPGP key retrieval from keyserver verified against pinned primary fingerprint `0EBF782C5D53F7E5FB02A66746BD761F7A49B0EC`.
- Release SHA-256 and Authenticode validation.
- Multi-pass `pacman -Syu` full system upgrade and native PE32+ test compilation.

### 2. Rust Standalone GNU Toolchain (`Rust-Installer/`)
A self-contained native Rust toolchain (`x86_64-pc-windows-gnu`) configured to utilize MSYS2's UCRT64 GCC and GNU binutils linker.
- Pinned Rust release key verification (`108F66205EAEB0AAA8DD5E1C85AB96E6FA1BE5FE`).
- Persistent User PATH update with automated backup to `$HOME\.local\rust\environment-backups/`.
- Automated native Cargo project test build and run.

### 3. Go Toolchain (`Go-Installer/`)
Official stable Go distribution extracted to user-local space.
- Discovers and downloads latest stable release from `https://go.dev/dl/?mode=json`.
- Cryptographic SHA-256 verification against the official manifest hash.
- Configures `GOROOT` (`$HOME\.local\go`) and `GOPATH` (`$HOME\go`), prepends binary directories to User PATH with automated backup.
- Native Go compile and execution verification (`go run` and `go build`).

### 4. Node.js LTS Toolchain (`Node-Installer/`)
Official Node.js Long Term Support distribution with a zero-admin global package configuration.
- Discovers latest LTS release from `https://nodejs.org/dist/index.json`.
- Cryptographic SHA-256 verification against official `SHASUMS256.txt`.
- Configures user `.npmrc` to route global packages to `$HOME\.npm-global`, enabling `npm install -g <pkg>` without elevation.
- Prepends `$HOME\.local\node` and `$HOME\.npm-global` to User PATH with automated backup.

### 5. Python Portable Toolchain (`Python-Installer/`)
Full-featured portable Python 3 runtime with standard site-packages and bootstrapped pip.
- Discovers official 64-bit Windows embeddable package and verifies SHA-256 digest.
- Automatically enables `import site` in `._pth` for full user `site-packages` compatibility.
- Bootstraps `pip` and `setuptools` via `get-pip.py`.
- Prepends `$HOME\.local\python` and `$HOME\.local\python\Scripts` to User PATH with automated backup.

---

## Unified Multi-Toolchain CLI Runner (`install-all.ps1`)

The repository includes a top-level orchestrator script (`install-all.ps1`) featuring an interactive menu, detailed help manual, and batch execution flags.

```powershell
# Show interactive console menu
.\install-all.ps1

# Display toolchain inventory & installation status
.\install-all.ps1 -List

# Install all toolchains in one sequence
.\install-all.ps1 -All

# Selectively install specific toolchains
.\install-all.ps1 -Go -Node -Python

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
- **Disk Space:** ~5 GB free space on an NTFS drive for all toolchains combined.
- **Dependencies:**
  - GnuPG (`gpg.exe`) available in `PATH` (e.g. from Gpg4win or Git for Windows).
  - Active internet connection for release artifact downloads.
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

Each toolchain directory is completely modular and can be run independently:

```powershell
# MSYS2 & UCRT64 GCC
cd MSYS2-Installer; .\install-msys2.ps1

# Rust Standalone (requires MSYS2)
cd ..\Rust-Installer; .\install-rust.ps1

# Go
cd ..\Go-Installer; .\install-go.ps1

# Node.js LTS & NPM
cd ..\Node-Installer; .\install-node.ps1

# Python & Pip
cd ..\Python-Installer; .\install-python.ps1
```

---

## Security & Verification Guarantees

| Property | Implementation Detail |
| :--- | :--- |
| **Privilege Model** | Zero elevation required. All operations scoped strictly to `$HOME` (`$HOME\msys64` and `$HOME\.local\...`). |
| **GPG Fingerprint Pinning** | MSYS2 (`0EBF782C5D53F7E5FB02A66746BD761F7A49B0EC`) and Rust (`108F66205EAEB0AAA8DD5E1C85AB96E6FA1BE5FE`). |
| **Integrity Verification** | Detached OpenPGP signatures (`GOODSIG`/`VALIDSIG`), SHA-256 release digests, and Windows Authenticode signatures. |
| **Fail-Fast Safety** | Any verification failure halts immediately before extraction or execution. Partial installs are cleaned up on error. |
| **Environment Isolation** | User PATH changes are backed up with timestamped recovery files under each toolchain's `environment-backups/` folder. System PATH is never touched. |

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
