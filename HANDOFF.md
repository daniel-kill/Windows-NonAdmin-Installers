# Active Task Handoff: Windows-NonAdmin-Installers

## Current State

The repository is a fully unified non-administrator developer platform for Windows 10/11 x86-64, hosting **12 dedicated, cryptographically verified installers** and a top-level unified CLI orchestrator:

### 1. Foundation & Cryptographic Prerequisites
1. `Gpg4win-Installer`: Provisions Gpg4win suite (`$HOME\.local\gpg4win\Gpg4win`) and official GnuPG core engine (`$HOME\.local\gpg4win\GnuPG\bin\gpg.exe`) silently without UAC prompts using `$env:__COMPAT_LAYER = 'RunAsInvoker'`.

### 2. Core Language Toolchains
2. `MSYS2-Installer`: Provisions MSYS2, UCRT64 GCC/G++, binutils, Make, and pkg-config into `$HOME\msys64`.
3. `Rust-Installer`: Provisions official Rust standalone GNU (`x86_64-pc-windows-gnu`) into `$HOME\.local\rust`.
4. `Go-Installer`: Provisions official Go compiler and tools into `$HOME\.local\go`, setting `GOROOT` and `GOPATH` (`$HOME\go`).
5. `Node-Installer`: Provisions Node.js LTS into `$HOME\.local\node` and configures user prefix at `$HOME\.npm-global`.
6. `Python-Installer`: Provisions portable Python 3 into `$HOME\.local\python`, configures site-packages, and bootstraps `pip`.

### 3. AI Developer CLIs
7. `Cline-CLI`: Autonomous coding agent CLI installed globally in user space (`$HOME\.npm-global`).
8. `Hermes-CLI`: Nous Research Hermes Agent CLI in an isolated user virtualenv (`$HOME\.local\hermes`).
9. `Vibe-CLI`: Mistral AI Vibe coding assistant CLI in an isolated user virtualenv (`$HOME\.local\vibe`).
10. `Ori-CLI`: OpenRouter Ori CLI native Windows binary (`$HOME\.local\ori\bin\ori.exe`) verified via `SHA256SUMS`.
11. `Antigravity-CLI`: Google Antigravity CLI native Windows binary (`$HOME\.local\antigravity\bin\agy.exe`) verified via SHA-512 manifest.
12. `Copilot-CLI`: GitHub Copilot CLI (`@github/copilot`) installed in user space (`$HOME\.npm-global`).

### 4. Unified Orchestrator
- `install-all.ps1`: Interactive console menu, `-List` status dashboard, detailed `-Help` manual, batch flags (`-All`, `-CliTools`, `-Gpg4win`, `-Force`), and dependency management.

---

## Completed Checklist

- [x] **Phase 0 — Core Modular Implementations:** MSYS2 & Rust modular steps.
- [x] **Phase 1 — Orchestrations & Documentation Baseline:** Master scripts and repository standards.
- [x] **Phase 2 — Toolchain Expansion:** Go, Node.js, Python, Gpg4win, and `install-all.ps1`.
- [x] **Phase 2.5 — AI Developer CLIs:**
  - [x] `Cline-CLI/` (prereq check, npm user-global install, PATH config, `install-cline.ps1`, `START_HERE.md`).
  - [x] `Hermes-CLI/` (prereq check, isolated venv install, launcher shim, PATH config, `install-hermes.ps1`, `START_HERE.md`).
  - [x] `Vibe-CLI/` (prereq check, isolated venv install, launcher shim, PATH config, `install-vibe.ps1`, `START_HERE.md`).
  - [x] `Ori-CLI/` (binary download, SHA256SUMS verification, binary install, PATH config, `install-ori.ps1`, `START_HERE.md`).
  - [x] `Antigravity-CLI/` (manifest query, SHA-512 verification, binary install, PATH config, `install-antigravity.ps1`, `START_HERE.md`).
  - [x] `Copilot-CLI/` (prereq check, npm user-global install, PATH config, `install-copilot.ps1`, `START_HERE.md`).
  - [x] `Gpg4win-Installer/` (official download & digest/authenticode verification, silent non-admin install, PATH config, `install-gpg4win.ps1`, `START_HERE.md`).
  - [x] `install-all.ps1` expanded with `-CliTools`, `-Gpg4win`, individual CLI flags, and interactive menu options.
  - [x] `README.md` and `ROADMAP.md` updated with full tables, quickstarts, and milestone tracking.

---

## In Progress & Immediate Next Steps

1. **User Review:** Review the new CLI installers and test capabilities with the user.
2. **Phase 3 Scoping:**
   - Develop dedicated uninstallation scripts (`uninstall-*.ps1`) for clean rollbacks and PATH restoration.
   - Design automated regression test workflow.
3. **Commit & Push:** Stage all newly created and updated files, create GPG-signed commit, and push to `origin/master` upon confirmation.

---

## Blockers & Gotchas

- **PowerShell Version:** Requires PowerShell 7 (`pwsh.exe`) with `-ExecutionPolicy Bypass`.
- **Node.js-based CLIs:** `Cline` and `Copilot` require Node.js. If missing, running `..\Node-Installer\install-node.ps1` resolves this prerequisite immediately.
- **Python-based CLIs:** `Hermes` and `Vibe` require Python 3.10+. If missing, running `..\Python-Installer\install-python.ps1` resolves this prerequisite immediately.
- **Environment Refresh:** Modifying the Windows Registry User `Path` takes effect immediately for new shells, but active terminal sessions must be restarted to inherit the refreshed PATH.
