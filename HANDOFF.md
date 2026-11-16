# Active Task Handoff: Windows-NonAdmin-Installers

## Current State

The repository is a fully unified non-administrator developer platform for Windows 10/11 x86-64, hosting **22 dedicated, cryptographically verified installers** and a top-level unified CLI orchestrator:

### 1. Foundation & Security Tools
1. `Gpg4win-Installer`: Provisions Gpg4win suite (`$HOME\.local\gpg4win\Gpg4win`) and official GnuPG core engine (`$HOME\.local\gpg4win\GnuPG\bin\gpg.exe`) silently without UAC prompts using `$env:__COMPAT_LAYER = 'RunAsInvoker'`.
2. `KeePassXC-Installer`: Provisions KeePassXC desktop password manager (`$HOME\.local\keepassxc\KeePassXC.exe`) and `keepassxc-cli.exe` in portable mode with OpenPGP release signature verification and Authenticode validation.

### 2. Core Language Toolchains
3. `MSYS2-Installer`: Provisions MSYS2, UCRT64 GCC/G++, binutils, Make, and pkg-config into `$HOME\msys64`.
4. `Rust-Installer`: Provisions official Rust standalone GNU (`x86_64-pc-windows-gnu`) into `$HOME\.local\rust`.
5. `Go-Installer`: Provisions official Go compiler and tools into `$HOME\.local\go`, setting `GOROOT` and `GOPATH` (`$HOME\go`).
6. `Node-Installer`: Provisions Node.js LTS into `$HOME\.local\node` and configures user prefix at `$HOME\.npm-global`.
7. `Python-Installer`: Provisions portable Python 3 into `$HOME\.local\python`, configures site-packages, and bootstraps `pip`.

### 3. VCS & Core Terminal Utilities
8. `PortableGit-Installer`: Provisions official Git for Windows portable (`$HOME\.local\git`) with Git Bash, OpenSSH, curl, and fast 7-Zip extraction.
9. `GitHub-CLI`: Provisions official GitHub CLI (`$HOME\.local\gh\bin\gh.exe`) with SHA-256 and Authenticode validation (`GitHub, Inc.`).
10. `7Zip-Installer`: Provisions 7-Zip archiver CLI (`$HOME\.local\7zip\7z.exe`), `7z.dll`, and GUI extracted non-elevated via `msiexec /a`.
11. `Ripgrep-CLI`: Provisions ripgrep (`$HOME\.local\ripgrep\bin\rg.exe`) ultra-fast search engine with official SHA-256 validation.
12. `Fd-CLI`: Provisions fd (`$HOME\.local\fd\bin\fd.exe`) user-friendly find alternative with official SHA-256 validation.
13. `Jq-CLI`: Provisions jq (`$HOME\.local\jq\bin\jq.exe`) command-line JSON processor with official release checksum validation.

### 4. Editors & Development Environments
14. `VSCode-Installer`: Provisions official VS Code Portable (`$HOME\.local\vscode\Code.exe`) with isolated `data/` directory, Authenticode validation (`Microsoft Corporation`), and zero registry pollution.

### 5. AI Developer CLIs
15. `Cline-CLI`: Autonomous coding agent CLI installed globally in user space (`$HOME\.npm-global`).
16. `Hermes-CLI`: Nous Research Hermes Agent CLI in an isolated user virtualenv (`$HOME\.local\hermes`).
17. `Vibe-CLI`: Mistral AI Vibe coding assistant CLI in an isolated user virtualenv (`$HOME\.local\vibe`).
18. `Ori-CLI`: OpenRouter Ori CLI native Windows binary (`$HOME\.local\ori\bin\ori.exe`) verified via `SHA256SUMS`.
19. `Antigravity-CLI`: Google Antigravity CLI native Windows binary (`$HOME\.local\antigravity\bin\agy.exe`) verified via SHA-512 manifest.
20. `Copilot-CLI`: GitHub Copilot CLI (`@github/copilot`) installed in user space (`$HOME\.npm-global`).
21. `Claude-CLI`: Anthropic Claude Code CLI (`@anthropic-ai/claude-code`) installed in user space (`$HOME\.npm-global`).
22. `Aider-CLI`: Aider Pair Programmer CLI (`aider-chat`) in an isolated user virtualenv (`$HOME\.local\aider\venv`) with `bin\aider.cmd` launcher shim.

### 6. Unified Orchestrator
- `install-all.ps1`: Interactive console menu, `-List` status dashboard, detailed `-Help` manual, batch flags (`-All`, `-CliTools`, `-Git`, `-Gh`, `-SevenZip`, `-Ripgrep`, `-Fd`, `-Jq`, `-VSCode`, `-Claude`, `-Aider`, `-Gpg4win`, `-KeePassXC`, `-Force`), and dependency management.

---

## Completed Checklist

- [x] **Phase 0 — Core Modular Implementations:** MSYS2 & Rust modular steps.
- [x] **Phase 1 — Orchestrations & Documentation Baseline:** Master scripts and repository standards.
- [x] **Phase 2 — Toolchain Expansion:** Go, Node.js, Python, Gpg4win, KeePassXC, and `install-all.ps1`.
- [x] **Phase 2.5 — AI Developer CLIs:** Cline, Hermes, Vibe, Ori, Antigravity, Copilot.
- [x] **Phase 2.75 — Modern VCS Utilities, Search Tools, Editors & Agent Expansion:**
  - [x] `PortableGit-Installer/` (official .7z.exe, SHA-256 verification, high-speed 7z extraction, PATH config, `install-git.ps1`, `START_HERE.md`).
  - [x] `GitHub-CLI/` (official release discovery, SHA-256 & Authenticode verification, PATH config, `install-gh.ps1`, `START_HERE.md`).
  - [x] `7Zip-Installer/` (official MSI discovery, non-elevated `msiexec /a` extraction, PATH config, `install-7zip.ps1`, `START_HERE.md`).
  - [x] `Ripgrep-CLI/` (official release discovery, SHA-256 verification, PATH config, `install-ripgrep.ps1`, `START_HERE.md`).
  - [x] `Fd-CLI/` (official release discovery, SHA-256 verification, PATH config, `install-fd.ps1`, `START_HERE.md`).
  - [x] `Jq-CLI/` (official release discovery, SHA-256 verification, functional JSON query test, PATH config, `install-jq.ps1`, `START_HERE.md`).
  - [x] `VSCode-Installer/` (Microsoft redirect resolution, 7z extraction, isolated `data/` portable mode, Authenticode verification, PATH config, `install-vscode.ps1`, `START_HERE.md`).
  - [x] `Claude-CLI/` (Node.js prereq inspection, user-global npm install, PATH config, `install-claude.ps1`, `START_HERE.md`).
  - [x] `Aider-CLI/` (Python 3.10+ & Git prereq inspection, isolated venv install, launcher shim, PATH config, `install-aider.ps1`, `START_HERE.md`).
  - [x] `install-all.ps1` expanded to 22 tools with individual flags, category headers, and `-CliTools` expanded to 8 AI CLIs.
  - [x] `README.md` and `ROADMAP.md` updated with complete tool tables, modular execution snippets, and Phase 2.75 tracking.

---

## In Progress & Immediate Next Steps

1. **User Review:** Review the complete 22-tool non-admin suite and verified operations.
2. **Commit & Push:** Stage all newly created and updated files, create GPG-signed commit, and push to `origin/master` upon user confirmation.
3. **Phase 3 Scoping:**
   - Develop dedicated uninstallation scripts (`uninstall-*.ps1`) for clean rollbacks and PATH restoration.
   - Design automated headless CI regression test workflow.

---

## Blockers & Gotchas

- **PowerShell Version:** Requires PowerShell 7 (`pwsh.exe`) with `-ExecutionPolicy Bypass`.
- **7-Zip Non-Admin MSI Extraction:** `msiexec.exe /a <msi> /qn TARGETDIR=<dir>` operates fully in user-space without UAC elevation.
- **VS Code Portable Mode:** Placing an empty `data` directory inside `$HOME\.local\vscode` directs all user configuration, caches, and extensions to remain inside the folder, preventing any writes to `%APPDATA%\Code` or the Windows Registry.
- **KeePassXC Password Generation Parameter:** In `keepassxc-cli generate`, password length is passed via `-L <length>` (e.g. `-L 32`), as `-l` denotes the `--lower` flag for lowercase character inclusion.
- **Node.js-based CLIs:** `Cline`, `Copilot`, and `Claude Code` require Node.js. If missing, running `..\Node-Installer\install-node.ps1` resolves this prerequisite immediately.
- **Python-based CLIs:** `Hermes`, `Vibe`, and `Aider` require Python 3.10+. If missing, running `..\Python-Installer\install-python.ps1` resolves this prerequisite immediately.
- **Environment Refresh:** Modifying the Windows Registry User `Path` takes effect immediately for new shells, but active terminal sessions must be restarted to inherit the refreshed PATH.
