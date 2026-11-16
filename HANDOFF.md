# Active Task Handoff: Windows-NonAdmin-Installers

## Current State

Phase 2 (Toolchain Expansion) is complete. The repository now features a complete multi-language developer platform containing five production-grade, cryptographically verified, non-administrator installer suites and a top-level unified CLI orchestrator:

1. `MSYS2-Installer`: Provisions MSYS2 with the full UCRT64 GCC toolchain group, GNU binutils, GNU Make, and pkg-config into `$HOME\msys64`.
2. `Rust-Installer`: Provisions the official Rust standalone GNU toolchain (`x86_64-pc-windows-gnu`) into `$HOME\.local\rust`, linking against MSYS2's UCRT64 toolchain.
3. `Go-Installer`: Provisions the official Go compiler and tools into `$HOME\.local\go`, setting `GOROOT` and `GOPATH` (`$HOME\go`).
4. `Node-Installer`: Provisions official Node.js LTS into `$HOME\.local\node` and configures a non-elevated user global package directory at `$HOME\.npm-global`.
5. `Python-Installer`: Provisions portable Python 3 into `$HOME\.local\python`, configures standard site-packages in `._pth`, and bootstraps `pip` via `get-pip.py`.
6. `install-all.ps1`: Top-level unified CLI runner with interactive console menu, detailed `--help` manual, inventory status check (`-List`), and batch provisioning flags (`-All`, `-Force`, selective toolchains).

---

## Completed

- [x] **Phase 0 — Core Modular Implementations:**
  - MSYS2: Steps 01–05 (download, key import, archive verification, SFX extraction, UCRT64 GCC toolchain).
  - Rust: Steps 01–03 (manifest auth, standalone extraction, user PATH configuration).
- [x] **Phase 1 — Orchestrations & Documentation Baseline:**
  - `install-msys2.ps1` and `install-rust.ps1` master orchestrators.
  - Baseline documentation suite: `AGENTS.md`, `README.md`, `ROADMAP.md`, `HANDOFF.md`.
- [x] **Phase 2 — Toolchain Expansion:**
  - **Go Installer (`Go-Installer/`):** `01-download-go.ps1`, `02-install-go.ps1`, `03-configure-go-environment.ps1`, `install-go.ps1`, `START_HERE.md`.
  - **Node.js Installer (`Node-Installer/`):** `01-download-node.ps1`, `02-install-node.ps1`, `03-configure-node-environment.ps1`, `install-node.ps1`, `START_HERE.md`.
  - **Python Installer (`Python-Installer/`):** `01-download-python.ps1`, `02-install-python.ps1`, `03-configure-python-environment.ps1`, `install-python.ps1`, `START_HERE.md`.
  - **Unified Runner (`install-all.ps1`):** Interactive menu, detailed help manual with examples, status dashboard, dependency-aware ordering (Rust requires MSYS2), and executive summary report.
  - **Documentation Alignment:** `README.md` and `ROADMAP.md` updated with comprehensive guides and completed milestone tracking.

---

## In Progress & Immediate Next Steps

1. **User Review:** Review Phase 2 deliverables with the user.
2. **Phase 3 Scoping:**
   - Implement dedicated uninstaller scripts (`uninstall-msys2.ps1`, `uninstall-rust.ps1`, `uninstall-go.ps1`, `uninstall-node.ps1`, `uninstall-python.ps1`) to provide clean rollbacks and PATH restorations.
   - Design automated GitHub Actions CI matrix on clean Windows Server runner.
3. **Commit & Push:** Stage all newly created and updated files, create GPG-signed commit, and push to `origin/master` upon confirmation.

---

## Blockers & Gotchas

- **PowerShell Version:** All scripts require PowerShell 7 (`pwsh.exe`) with `-ExecutionPolicy Bypass`. Legacy Windows PowerShell 5.1 is unsupported.
- **Dependency Ordering:** The `Rust-Installer` requires MSYS2 UCRT64 for its C/C++ linker tools. The `install-all.ps1` runner automatically detects this and orders MSYS2 ahead of Rust.
- **Environment Refresh:** Modifying the Windows Registry User `Path` affects new processes immediately, but existing terminal windows must be restarted to inherit updated paths.
- **Node.js Global Packages:** Global npm packages are directed to `$HOME\.npm-global` via `.npmrc` prefix configuration, ensuring `npm install -g` succeeds without elevation.
- **Python site-packages:** Embeddable Python requires `import site` enabled in `*._pth` to find packages installed via `pip install`; the installer configures this automatically.
