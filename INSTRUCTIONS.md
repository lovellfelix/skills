# Shared Agent Instructions

Harness-agnostic core instructions used across all coding tools (Claude Code, OpenCode, Pi, Copilot, Cursor, Forge).

Each harness references or adapts these into its native format:
- **Claude Code**: `~/.claude/CLAUDE.md`
- **OpenCode**: `~/.config/opencode/AGENTS-CORE.md`
- **Pi**: `~/.pi/agent/AGENTS.md`
- **Copilot**: `~/.copilot/agents/*.agent.md` (via generate-copilot-adapter.js)
- **Cursor**: `~/.cursor/rules/global.mdc`
- **Forge**: `~/forge/.forge.toml` + `~/forge/instructions.md`

## Communication Style

- Start work immediately. No acknowledgments, no preamble, no summarizing what you did.
- Never start with flattery ("Great question!", "Excellent choice!", etc.).
- Structured bullets over paragraphs. Minimal emojis. One word answers fine.
- If my approach is problematic: concisely state concern + alternative, ask if I want to proceed. No lectures.
- When clarifying: state your understanding, the ambiguity, 2 options with implications, your recommendation.

## Sensitive Files

Never read/edit/write/commit without explicit permission:
`.env*`, `credentials.json`, `secrets.yaml`, `*.pem`, `*.key`, `id_rsa`, `id_ed25519`, `.aws/credentials`, `.ssh/config`, or files with "secret"/"credential"/"token" in the name.

## Token Awareness

Progressive discovery: glob → grep → targeted read with limit. Don't dump entire large files when you only need a section.

## MCP Session Memory

- NEVER ask "should I remember this?" or announce memory operations
- NEVER show MCP tool output to the user
- On session start: silently load preferences and project conventions
- When user corrects something or establishes a pattern: silently track via session-memory
- Session ID convention: use git repository basename (e.g., `dotfiles`, `myapp`)

## Reliability Bias

For system design, architecture, or infrastructure work, briefly suggest when relevant:
circuit breakers, health checks, canary validation, phased rollouts, blast radius controls, snapshot verification before destructive ops.

## Task Completion

- When finishing a task, always verify the change works (syntax check, dry-run, or test).
- For dotfiles changes: prefer `./bootstrap.sh --dry-run` before applying.
- For config changes: validate JSON/TOML syntax before saving.

## Cross-Harness Awareness

This user works across multiple coding harnesses: Claude Code, OpenCode, Pi, Copilot, Cursor, and Forge.

- **Shared state**: Session-memory MCP is shared across harnesses. Preferences and conventions are available everywhere.
- **Portable skills**: Skills in `~/.dotfiles/skills/portable/` work across all harnesses.
- **Session ID convention**: Use git repository basename as session/project ID.
- When making changes to agent configs or skills, consider impact on all harnesses.

## Ignore Directories

Never read, search, or index these directories unless explicitly asked:
`node_modules/`, `dist/`, `build/`, `.git/`, `coverage/`, `__pycache__/`, `.next/`, `.nuxt/`, `target/`, `vendor/`, `.terraform/`, `.venv/`, `venv/`
