# Repository Agent Guidelines: Windows-NonAdmin-Installers

Read [HANDOFF.md](HANDOFF.md) first, then [ROADMAP.md](ROADMAP.md), before starting work.
Before finishing any turn or session, record completed work, immediate next steps, and any blockers or gotchas in [HANDOFF.md](HANDOFF.md).

## Mandatory Commit Signing
Every commit created for this repository must have a valid cryptographic signature (GPG or SSH).
- Key: `daniel@danielkill.online` (or repository-specific configured signing key)
- Never create an unsigned commit or bypass signing checks. If signing fails or is unavailable, stop and notify the user.
- Verify each created commit using `git verify-commit <commit>` or `git log --show-signature -1`.
- Do not rewrite existing commits just to add signatures unless explicitly authorized.

## Central Documentation & Knowledge Base
Consult central shared guides, runtimes, and agent documentation here:
- **Windows:** `C:\Users\danie\Repos\shared\docs\`
- **WSL:** `/home/daniel/Repos/shared/docs/`

## Host Hardware & System Information
Authoritative machine snapshots, hardware inventory, and installed packages can be found at:
- **Windows:** `C:\Users\danie\Repos\shared\data\snapshots\danielpredpc\`
- **WSL:** `/home/daniel/Repos/shared/data\snapshots\danielpredpc-wsl/`

## Project Status & Scope Protocol
- **Status:** Initialized / Active Development
- Check existing files, tests, and configuration before modifying code.
- Store local private configuration, secrets, and credentials under `.private/` (which is git-ignored). Never commit private keys or secrets.
- Always use relative markdown links between repository documents.
