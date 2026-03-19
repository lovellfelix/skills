# Skills Index

Root-level skills are organized by portability and runtime. This index lists all available skill packages.

## Portable Skills

Portable skills are tool-agnostic and work across multiple runtimes (OpenCode, Cursor, Claude, etc.).

| Name | Location | Purpose |
|------|----------|---------|
| **ask** | `portable/ask/` | Source-priority Q&A workflow (project notes, memory, codebase, web) |
| **documentation** | `portable/documentation/` | Generate and update documentation with language-aware formatting and conventions |
| **email-best-practices** | `portable/email-best-practices/` | Email feature implementation, authentication, compliance, and delivery patterns |
| **example-skill** | `portable/example-skill/` | Minimal template for creating new skill packages |
| **find-skills** | `portable/find-skills/` | Discover and install agent skills for specific tasks or capabilities |
| **frontend-design** | `portable/frontend-design/` | Create distinctive, production-grade frontend interfaces and UI components |
| **mcp-builder** | `portable/mcp-builder/` | Build MCP servers for LLM integration with external services |
| **python-code-style** | `portable/python-code-style/` | Python code style, linting, formatting, naming conventions, and docstrings |
| **refactoring** | `portable/refactoring/` | Simplify and refine code for clarity, consistency, and maintainability |
| **release-skills** | `portable/release-skills/` | Universal release workflow (version bumping, changelog, deployment) |
| **shadcn-ui** | `portable/shadcn-ui/` | shadcn/ui component library setup, configuration, and React integration patterns |
| **testing** | `portable/testing/` | Universal testing with framework auto-detection (Python, JS, TS, Go, Kotlin) |
| **writing-plans** | `portable/writing-plans/` | Structure multi-step tasks with dependencies before touching code |

## Runtime-Specific Skills

Skills with runtime-specific adapters or overlays.

### OpenCode

| Name | Location | Purpose |
|------|----------|---------|
| **morning** | `runtime-specific/opencode/morning/` | Morning briefing workflow tied to OpenCode scripts and session memory |
| **standup** | `runtime-specific/opencode/standup/` | Daily standup synthesis from OpenCode-integrated data sources |
| **graph** | `runtime-specific/opencode/graph/` | Work-item graph tracking for OpenCode session-memory tools |
| **ask** | `runtime-specific/opencode/ask/` | OpenCode ask workflow with Obsidian notes and session-memory fallback |
| **graph-tracker** | `runtime-specific/opencode/graph-tracker/` | Persistent graph tracking across engineering and personal contexts |
| **obsidian-work-notes** | `runtime-specific/opencode/obsidian-work-notes/` | Obsidian CLI-first workflow for OpenCode work notes |

## Archive

Deprecated or superseded skills kept for historical traceability.

(No archived skills yet)

## Discovery & Convention

See [`reference/DISCOVERY.md`](./reference/DISCOVERY.md) for:
- Naming and file structure
- Required metadata
- Trigger documentation ('use when' patterns)
- Portable vs runtime-specific placement

## Adding a New Skill

1. Create a directory under `portable/<skill-name>/` (or `runtime-specific/<runtime>/` if runtime-specific).
2. Add required files: `SKILL.md`, `manifest.json`.
3. Include frontmatter metadata in `SKILL.md` for discovery.
4. Update this index to list your skill.

See `reference/DISCOVERY.md` for detailed conventions.
