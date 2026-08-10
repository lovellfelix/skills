#!/usr/bin/env python3

from __future__ import annotations

import json
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent
SKILLS_ROOT = REPO_ROOT  # this repo IS the skills root (moved out of dotfiles' skills/)
PORTABLE_ROOT = SKILLS_ROOT / "portable"
RUNTIME_ROOT = SKILLS_ROOT / "runtime-specific"
ARCHIVE_ROOT = SKILLS_ROOT / "archive"
INDEX_PATH = SKILLS_ROOT / "INDEX.md"
REGISTRY_PATH = SKILLS_ROOT / "registry.json"


def parse_frontmatter(skill_path: Path) -> dict[str, str]:
    """Parse SKILL.md frontmatter, flattening agentskills.io `metadata:` block.

    Returns a flat dict where keys nested under `metadata:` are merged with
    top-level keys (top-level wins on conflict). Supports the agentskills.io
    spec while remaining backward-compatible with the older flat layout.
    """
    lines = skill_path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0].strip() != "---":
        return {}

    top: dict[str, str] = {}
    meta: dict[str, str] = {}
    in_meta = False
    for line in lines[1:]:
        if line.strip() == "---":
            break
        if not line.strip():
            in_meta = False
            continue
        if line[:1] in (" ", "\t"):
            if in_meta and ":" in line:
                key, value = line.strip().split(":", 1)
                meta[key.strip()] = value.strip().strip('"')
            continue
        if ":" not in line:
            in_meta = False
            continue
        key, value = line.split(":", 1)
        key, value = key.strip(), value.strip()
        if key == "metadata" and value == "":
            in_meta = True
            continue
        in_meta = False
        top[key] = value.strip('"')
    merged = dict(meta)
    merged.update(top)
    return merged


def read_skill_metadata(skill_dir: Path) -> dict[str, object]:
    manifest_path = skill_dir / "manifest.json"
    skill_md_path = skill_dir / "SKILL.md"

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    frontmatter = parse_frontmatter(skill_md_path)

    return {
        "name": str(manifest.get("name") or frontmatter.get("name") or skill_dir.name),
        "description": str(frontmatter.get("description") or ""),
        "version": str(manifest.get("version") or frontmatter.get("version") or ""),
        "portable": bool(manifest.get("portable", True)),
        "personal_machine_only": bool(manifest.get("personal_machine_only", False)),
        "local_overlay_only": bool(manifest.get("local_overlay_only", False)),
        "runtime": manifest.get("runtime"),
        "entrypoint": str(manifest.get("entrypoint") or "SKILL.md"),
        "tags": manifest.get("tags") or [],
        "adapters": manifest.get("adapters") or {},
        "compatibility": manifest.get("compatibility") or {},
    }


def collect_portable_skills() -> list[dict[str, object]]:
    results: list[dict[str, object]] = []
    if not PORTABLE_ROOT.is_dir():
        return results

    for skill_dir in sorted(
        [p for p in PORTABLE_ROOT.iterdir() if p.is_dir()], key=lambda p: p.name
    ):
        if (
            not (skill_dir / "manifest.json").is_file()
            or not (skill_dir / "SKILL.md").is_file()
        ):
            continue
        meta = read_skill_metadata(skill_dir)
        results.append(
            {
                "name": meta["name"],
                "location": f"portable/{skill_dir.name}/",
                "description": meta["description"],
                "version": meta["version"],
                "portable": meta["portable"],
                "personal_machine_only": meta["personal_machine_only"],
                "local_overlay_only": meta["local_overlay_only"],
                "runtime": meta["runtime"],
                "entrypoint": meta["entrypoint"],
                "tags": meta["tags"],
                "adapters": meta["adapters"],
                "compatibility": meta["compatibility"],
            }
        )
    return results


def collect_runtime_skills() -> dict[str, list[dict[str, object]]]:
    grouped: dict[str, list[dict[str, object]]] = {}
    if not RUNTIME_ROOT.is_dir():
        return grouped

    runtime_dirs = sorted(
        [p for p in RUNTIME_ROOT.iterdir() if p.is_dir()], key=lambda p: p.name
    )
    for runtime_dir in runtime_dirs:
        skills: list[dict[str, object]] = []
        for skill_dir in sorted(
            [p for p in runtime_dir.iterdir() if p.is_dir()], key=lambda p: p.name
        ):
            if (
                not (skill_dir / "manifest.json").is_file()
                or not (skill_dir / "SKILL.md").is_file()
            ):
                continue
            meta = read_skill_metadata(skill_dir)
            skills.append(
                {
                    "name": meta["name"],
                    "location": f"runtime-specific/{runtime_dir.name}/{skill_dir.name}/",
                    "description": meta["description"],
                    "version": meta["version"],
                    "portable": meta["portable"],
                    "personal_machine_only": meta["personal_machine_only"],
                    "local_overlay_only": meta["local_overlay_only"],
                    "runtime": meta["runtime"],
                    "entrypoint": meta["entrypoint"],
                    "tags": meta["tags"],
                    "adapters": meta["adapters"],
                    "compatibility": meta["compatibility"],
                }
            )
        grouped[runtime_dir.name] = skills

    return grouped


def collect_archive_skills() -> list[str]:
    if not ARCHIVE_ROOT.is_dir():
        return []

    entries = [p for p in ARCHIVE_ROOT.iterdir() if p.is_dir()]
    return [f"- `{entry.name}/`" for entry in sorted(entries, key=lambda p: p.name)]


def runtime_heading(runtime: str) -> str:
    names = {
        "opencode": "OpenCode",
    }
    return names.get(runtime, runtime.replace("-", " ").title())


def build_index() -> str:
    portable = collect_portable_skills()
    runtime = collect_runtime_skills()
    archive = collect_archive_skills()

    lines: list[str] = [
        "# Skills Index",
        "",
        "<!-- Generated by hacks/generate-skills-index.py. Do not edit manually. -->",
        "",
        "Root-level skills are organized by portability and runtime. This index lists all available skill packages.",
        "",
        "## Portable Skills",
        "",
        "Portable skills are tool-agnostic and work across multiple runtimes (OpenCode, Cursor, Claude, etc.).",
        "",
        "| Name | Location | Purpose |",
        "|------|----------|---------|",
    ]

    for skill in portable:
        lines.append(
            f"| **{skill['name']}** | `{skill['location']}` | {skill['description']} |"
        )

    runtime_names = [name for name in sorted(runtime.keys()) if runtime[name]]
    if runtime_names:
        lines.extend(
            [
                "",
                "## Runtime-Specific Skills",
                "",
                "Skills with runtime-specific adapters or overlays.",
                "",
            ]
        )

        for runtime_name in runtime_names:
            lines.extend(
                [
                    f"### {runtime_heading(runtime_name)}",
                    "",
                    "| Name | Location | Purpose |",
                    "|------|----------|---------|",
                ]
            )
            for skill in runtime[runtime_name]:
                lines.append(
                    f"| **{skill['name']}** | `{skill['location']}` | {skill['description']} |"
                )
            lines.append("")

    if not runtime_names:
        lines.append("")

    lines.extend(
        [
            "## Archive",
            "",
            "Deprecated or superseded skills kept for historical traceability.",
            "",
        ]
    )

    if archive:
        lines.extend(archive)
    else:
        lines.append("(No archived skills yet)")

    lines.extend(
        [
            "",
            "## Discovery & Convention",
            "",
            "See [`reference/DISCOVERY.md`](./reference/DISCOVERY.md) for:",
            "- Naming and file structure",
            "- Required metadata",
            "- Trigger documentation ('use when' patterns)",
            "- Portable vs runtime-specific placement",
            "",
            "## Adding a New Skill",
            "",
            "1. Run `./hacks/new-skill.sh <skill-name>` (or add `--runtime <runtime>` for runtime-specific skills).",
            "2. Fill in `SKILL.md` and `manifest.json` metadata/content.",
            "3. Run `python3 ./hacks/generate-skills-index.py` to refresh this index.",
            "4. Confirm generated artifacts (`skills/INDEX.md` and `skills/registry.json`) are updated.",
            "5. Validate with `./hacks/validate-skills.sh`.",
            "",
            "See `AUTHORING.md` and `reference/DISCOVERY.md` for detailed conventions.",
        ]
    )

    return "\n".join(lines) + "\n"


def build_registry() -> dict[str, object]:
    portable = collect_portable_skills()
    runtime = collect_runtime_skills()

    skills: list[dict[str, object]] = []
    for item in portable:
        skills.append(
            {
                "name": item["name"],
                "description": item["description"],
                "version": item["version"],
                "portable": item["portable"],
                "personal_machine_only": item.get("personal_machine_only", False),
                "local_overlay_only": item.get("local_overlay_only", False),
                "runtime": item.get("runtime"),
                "location": item["location"],
                "entrypoint": item["entrypoint"],
                "tags": item["tags"],
                "adapters": item["adapters"],
                "compatibility": item["compatibility"],
            }
        )

    for runtime_name in sorted(runtime.keys()):
        for item in runtime[runtime_name]:
            skills.append(
                {
                    "name": item["name"],
                    "description": item["description"],
                    "version": item["version"],
                    "portable": item["portable"],
                    "personal_machine_only": item.get("personal_machine_only", False),
                    "local_overlay_only": item.get("local_overlay_only", False),
                    "runtime": item.get("runtime") or runtime_name,
                    "location": item["location"],
                    "entrypoint": item["entrypoint"],
                    "tags": item["tags"],
                    "adapters": item["adapters"],
                    "compatibility": item["compatibility"],
                }
            )

    skills.sort(key=lambda item: str(item["location"]))

    return {
        "schema_version": "1.0",
        "skills": skills,
    }


def main() -> int:
    INDEX_PATH.write_text(build_index(), encoding="utf-8")
    REGISTRY_PATH.write_text(
        json.dumps(build_registry(), indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(f"Updated {INDEX_PATH.relative_to(REPO_ROOT)}")
    print(f"Updated {REGISTRY_PATH.relative_to(REPO_ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
