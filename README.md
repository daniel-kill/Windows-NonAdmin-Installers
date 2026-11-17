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

### Foundation & Security Tools
| Toolchain | Folder | Target Path | Key Components |
| :--- | :--- | :--- | :--- |
| **Gpg4win & GnuPG** | `Gpg4win-Installer/` | `$HOME\.local\gpg4win` | GnuPG core engine (`gpg.exe`, `gpgv.exe`, `dirmngr.exe`) & Kleopatra |
| **KeePassXC & CLI** | `KeePassXC-Installer/` | `$HOME\.local\keepassxc` | KeePassXC GUI, `keepassxc-cli.exe`, `keepassxc-proxy.exe`, `.portable` mode |

### Core Developer Toolchains & Modern Runtimes
| Toolchain | Folder | Target Path | Key Components |
| :--- | :--- | :--- | :--- |
| **MSYS2 & UCRT64** | `MSYS2-Installer/` | `$HOME\msys64` | Bash, Pacman, UCRT64 GCC/G++, Binutils, Make, pkg-config |
| **Rust Standalone** | `Rust-Installer/` | `$HOME\.local\rust` | Rust stable GNU (`rustc`, `cargo`, `rustdoc`) linked to UCRT64 |
| **Go Toolchain** | `Go-Installer/` | `$HOME\.local\go` | Go compiler (`go.exe`), `gofmt.exe`, `GOPATH` (`$HOME\go`) |
| **Node.js LTS** | `Node-Installer/` | `$HOME\.local\node` | Node.js LTS (`node.exe`), `npm.cmd`, `npx.cmd`, `$HOME\.npm-global` |
| **Python Portable** | `Python-Installer/` | `$HOME\.local\python` | Python 3 embeddable runtime, bootstrapped `pip`, `Scripts\` |
| **Bun Runtime** | `Bun-CLI/` | `$HOME\.local\bun` | All-in-one JS/TS runtime, package manager, and bundler (`bun.exe`) |
| **Deno Runtime** | `Deno-CLI/` | `$HOME\.local\deno` | Secure TypeScript & JavaScript runtime with built-in tooling (`deno.exe`) |

### Native Build Systems
| Build Tool | Folder | Target Path | Key Components |
| :--- | :--- | :--- | :--- |
| **CMake Portable** | `CMake-Installer/` | `$HOME\.local\cmake` | Official build automation suite (`cmake.exe`, `ctest.exe`, `cpack.exe`) |
| **Ninja Build** | `Ninja-Installer/` | `$HOME\.local\ninja` | Ultra-fast, lightweight build tool (`ninja.exe`) |

### VCS & Core Terminal Utilities
| Tool / Utility | Folder | Target Path | Key Components |
| :--- | :--- | :--- | :--- |
| **PortableGit** | `PortableGit-Installer/` | `$HOME\.local\git` | Git for Windows portable (`git.exe`), Git Bash, OpenSSH, curl |
| **GitHub CLI (gh)** | `GitHub-CLI/` | `$HOME\.local\gh` | Official GitHub CLI (`gh.exe`) for issues, PRs, releases, and auth |
| **7-Zip Console** | `7Zip-Installer/` | `$HOME\.local\7zip` | 7-Zip archiver CLI (`7z.exe`), `7z.dll`, GUI extracted non-admin |
| **ripgrep (rg)** | `Ripgrep-CLI/` | `$HOME\.local\ripgrep` | Ultra-fast recursive regex search engine respecting `.gitignore` |
| **fd** | `Fd-CLI/` | `$HOME\.local\fd` | Simple, fast, and user-friendly alternative to `find` / `dir /s` |
| **jq** | `Jq-CLI/` | `$HOME\.local\jq` | Lightweight and flexible command-line JSON processor |
| **fzf** | `Fzf-CLI/` | `$HOME\.local\fzf` | Command-line interactive fuzzy finder (`fzf.exe`) |
| **bat** | `Bat-CLI/` | `$HOME\.local\bat` | Cat clone with syntax highlighting and Git integration (`bat.exe`) |
| **git-delta** | `Delta-CLI/` | `$HOME\.local\delta` | Syntax-highlighting pager for git, diff, and grep output (`delta.exe`) |
| **eza** | `Eza-CLI/` | `$HOME\.local\eza` | Modern replacement for `ls` and `dir` with git integration (`eza.exe`) |
| **cloudflared** | `Cloudflared-CLI/` | `$HOME\.local\cloudflared` | Cloudflare Tunnel daemon for non-admin localhost port tunneling |

### Editors & Development Environments
| Editor | Folder | Target Path | Key Components |
| :--- | :--- | :--- | :--- |
| **VS Code Portable** | `VSCode-Installer/` | `$HOME\.local\vscode` | Official VS Code portable (`Code.exe`) with isolated `data/` directory |

### AI Developer CLIs & Agent Runtimes
| Agent CLI / Runtime | Folder | Source / Type | Target Path | Official Docs |
| :--- | :--- | :--- | :--- | :--- |
| **Cline CLI** | `Cline-CLI/` | npm (`cline`) | `$HOME\.npm-global` | [cline.bot/cli](https://cline.bot/cli) |
| **Hermes Agent** | `Hermes-CLI/` | Python (`hermes-agent`) | `$HOME\.local\hermes` | [hermes-agent.nousresearch.com](https://hermes-agent.nousresearch.com/docs/user-guide/cli) |
| **Mistral Vibe** | `Vibe-CLI/` | Python (`mistral-vibe`) | `$HOME\.local\vibe` | [chat.mistral.ai/code/extensions](https://chat.mistral.ai/code/extensions) |
| **OpenRouter Ori** | `Ori-CLI/` | Native x64 Binary | `$HOME\.local\ori\bin\ori.exe` | [openrouter.ai/ori](https://openrouter.ai/ori) |
| **Google Antigravity** | `Antigravity-CLI/` | Native x64 Binary | `$HOME\.local\antigravity\bin\agy.exe` | [antigravity.google/product/antigravity-cli](https://antigravity.google/product/antigravity-cli) |
| **GitHub Copilot** | `Copilot-CLI/` | npm (`@github/copilot`) | `$HOME\.npm-global` | [github.com/github/copilot-cli](https://github.com/github/copilot-cli) |
| **Claude Code** | `Claude-CLI/` | npm (`@anthropic-ai/claude-code`) | `$HOME\.npm-global` | [docs.anthropic.com](https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview) |
| **Aider Pair Programmer** | `Aider-CLI/` | Python (`aider-chat`) | `$HOME\.local\aider` | [aider.chat](https://aider.chat/) |
| **Astral uv** | `Uv-CLI/` | Native x64 Binary | `$HOME\.local\uv\bin\uv.exe` | [docs.astral.sh/uv](https://docs.astral.sh/uv/) |
| **Herdr Runtime (hc)** | `Herdr-CLI/` | Native x64 Binary | `$HOME\.local\herdr\bin\hc.exe` | [herdr.dev](https://herdr.dev/) |

---

## Unified Multi-Toolchain CLI Runner (`install-all.ps1`)

The repository includes a top-level orchestrator script (`install-all.ps1`) featuring an interactive console menu, detailed help manual, and batch execution flags.

```powershell
# Show interactive console menu
.\install-all.ps1

# Display complete toolchain & CLI inventory status (33 managed tools)
.\install-all.ps1 -List

# Install Gpg4win cryptographic foundation
.\install-all.ps1 -Gpg4win

# Install KeePassXC password manager & CLI
.\install-all.ps1 -KeePassXC

# Install all tools across all categories in one sequence
.\install-all.ps1 -All

# Install only the 9 AI Developer CLIs & agent runtimes
.\install-all.ps1 -CliTools

# Install native build systems
.\install-all.ps1 -Cmake -Ninja

# Install next-gen JavaScript & TypeScript runtimes
.\install-all.ps1 -Bun -Deno

# Install modern VCS & core terminal utilities
.\install-all.ps1 -Git -Gh -SevenZip -Ripgrep -Fd -Jq -Fzf -Bat -Delta -Eza -Cloudflared

# Install portable code editor
.\install-all.ps1 -VSCode

# Install modern Python & agent orchestration runtimes
.\install-all.ps1 -Uv -Herdr

# Selectively install specific tools
.\install-all.ps1 -Gpg4win -Git -Gh -VSCode -Claude -Uv -Herdr

# Force clean reinstallation
.\install-all.ps1 -All -Force

# View detailed help manual and examples
.\install-all.ps1 -Help
```

---

## Lifecycle Management: Uninstallation, Auditing & Upgrades

Phase 3 introduces comprehensive lifecycle management tooling for the 33 non-admin developer toolchains.

### 1. Unified Uninstaller Orchestrator (`uninstall-all.ps1`)

Safely and cleanly removes installed toolchains, wipes user directories (`$HOME\.local\<tool>`, `$HOME\msys64`), cleans download caches (`$HOME\Downloads\<tool>`), terminates background daemons (e.g. `gpgconf --kill all`, `herdr-core`), and automatically purges tool directories from User PATH while storing timestamped backups under `$HOME\.local\environment-backups\`.

```powershell
# Interactive uninstaller menu
.\uninstall-all.ps1

# List installed status across all 33 tools
.\uninstall-all.ps1 -List

# Cleanly uninstall a specific tool (e.g., KeePassXC)
.\uninstall-all.ps1 -KeePassXC

# Uninstall all 9 AI Developer CLIs while retaining download installers
.\uninstall-all.ps1 -CliTools -KeepCache

# Complete clean removal of all 33 tools
.\uninstall-all.ps1 -All
```

Each tool directory also contains an isolated, modular `uninstall-<tool>.ps1` (e.g., `Gpg4win-Installer/uninstall-gpg4win.ps1`, `VSCode-Installer/uninstall-vscode.ps1`).

---

### 2. Toolchain Integrity Auditor (`audit-tools.ps1`)

Scans all 33 toolchains, verifying binary presence on disk, CLI version command execution, Authenticode digital signatures (`GitHub, Inc.`, `DroidMonkey Apps, LLC`, etc.), and User PATH configuration:

```powershell
# Run full human-readable integrity report
.\audit-tools.ps1

# Output structured JSON for automation or CI pipelines
.\audit-tools.ps1 -Json
```

---

### 3. Upstream Release Auditor & Upgrader (`update-all.ps1`)

Monitors upstream release feeds (GitHub Releases, npm registry, PyPI, Go dev API, Node.js distribution catalog, Herdr manifest), compares installed versions against available releases, and orchestrates clean in-place updates. Automatically leverages `$env:GITHUB_TOKEN` or `gh auth token` to avoid rate limits.

```powershell
# Interactive update menu
.\update-all.ps1

# Audit only (dry-run comparison table of installed vs upstream)
.\update-all.ps1 -CheckOnly

# Audit only AI Developer CLIs
.\update-all.ps1 -CliTools -CheckOnly

# Upgrade all outdated tools
.\update-all.ps1 -All

# Upgrade only outdated AI Developer CLIs
.\update-all.ps1 -CliTools

# Force re-install / upgrade of a specific tool
.\update-all.ps1 -Gh -Force

# Output audit data as structured JSON
.\update-all.ps1 -Json
```

---

## Prerequisites & Requirements

- **Operating System:** Windows 10 or Windows 11 (64-bit x86-64).
- **Shell:** PowerShell 7.0 or later (`pwsh.exe`).
- **Permissions:** Standard User (no administrator / UAC elevation required).
- **Disk Space:** ~5–8 GB free space on an NTFS drive for all tools combined.
- **Dependencies:**
  - GnuPG (`gpg.exe`) is required for verifying MSYS2, Rust, and release signatures. If not present on your system, run `Gpg4win-Installer\install-gpg4win.ps1` or `.\install-all.ps1 -Gpg4win`.
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
# Foundation & Security Tools
cd Gpg4win-Installer;        .\install-gpg4win.ps1
cd ..\KeePassXC-Installer;   .\install-keepassxc.ps1

# Core Toolchains & Modern Runtimes
cd ..\MSYS2-Installer;       .\install-msys2.ps1
cd ..\Rust-Installer;        .\install-rust.ps1
cd ..\Go-Installer;          .\install-go.ps1
cd ..\Node-Installer;        .\install-node.ps1
cd ..\Python-Installer;      .\install-python.ps1
cd ..\Bun-CLI;               .\install-bun.ps1
cd ..\Deno-CLI;              .\install-deno.ps1

# Native Build Systems
cd ..\CMake-Installer;       .\install-cmake.ps1
cd ..\Ninja-Installer;       .\install-ninja.ps1

# VCS & Core Terminal Utilities
cd ..\PortableGit-Installer; .\install-git.ps1
cd ..\GitHub-CLI;            .\install-gh.ps1
cd ..\7Zip-Installer;        .\install-7zip.ps1
cd ..\Ripgrep-CLI;           .\install-ripgrep.ps1
cd ..\Fd-CLI;                .\install-fd.ps1
cd ..\Jq-CLI;                .\install-jq.ps1
cd ..\Fzf-CLI;               .\install-fzf.ps1
cd ..\Bat-CLI;               .\install-bat.ps1
cd ..\Delta-CLI;             .\install-delta.ps1
cd ..\Eza-CLI;               .\install-eza.ps1
cd ..\Cloudflared-CLI;       .\install-cloudflared.ps1

# Editors & Development Environments
cd ..\VSCode-Installer;       .\install-vscode.ps1

# AI Developer CLIs & Agent Runtimes
cd ..\Cline-CLI;             .\install-cline.ps1
cd ..\Hermes-CLI;            .\install-hermes.ps1
cd ..\Vibe-CLI;              .\install-vibe.ps1
cd ..\Ori-CLI;               .\install-ori.ps1
cd ..\Antigravity-CLI;       .\install-antigravity.ps1
cd ..\Copilot-CLI;           .\install-copilot.ps1
cd ..\Claude-CLI;            .\install-claude.ps1
cd ..\Aider-CLI;             .\install-aider.ps1
cd ..\Uv-CLI;                .\install-uv.ps1
cd ..\Herdr-CLI;             .\install-herdr.ps1
```

---

## Security & Verification Guarantees

| Property | Implementation Detail |
| :--- | :--- |
| **Privilege Model** | Zero elevation required. All operations scoped strictly to `$HOME` (`$HOME\msys64`, `$HOME\.local\...`, `$HOME\.npm-global`). |
| **GPG Fingerprint Pinning** | MSYS2 (`0EBF782C5D53F7E5FB02A66746BD761F7A49B0EC`), Rust (`108F66205EAEB0AAA8DD5E1C85AB96E6FA1BE5FE`), and KeePassXC (`BF5A669F2272CF4324C1FDA8CFB4C2166397D0D2`). |
| **Integrity Verification** | Detached OpenPGP signatures (`GOODSIG`/`VALIDSIG`), SHA-256 release digests (Go, Node, Python, Bun, Deno, CMake, uv, Herdr, cloudflared, fzf, bat, delta, eza, Ori, Gpg4win, KeePassXC, GitHub CLI, ripgrep, fd, jq, PortableGit, 7-Zip), SHA-512 (Antigravity), and Windows Authenticode signatures (`GitHub, Inc.`, `Microsoft Corporation`, `DroidMonkey Apps, LLC`, etc.). |
| **Zero-Registry Isolation** | Portable modes activated where available (e.g. VS Code isolated `data/` directory, KeePassXC `.portable` flag) preventing `%APPDATA%` and registry pollution. |
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
  Install GnuPG non-admin directly from this repository:
  ```powershell
  cd Gpg4win-Installer
  .\install-gpg4win.ps1
  ```
- **"Command not found after install"**:
  Restart your terminal session to ensure the refreshed User PATH is loaded by your shell.
