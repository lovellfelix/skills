---
name: java-to-kotlin-migration
description: Use when migrating Android projects from Java to Kotlin while maintaining behavior and test coverage.
metadata:
  version: 0.1.0
  portable: true
  tags: [android, kotlin, java, migration]
---

# Java-to-Kotlin Migration Skill

Use this skill when migrating Android (or JVM) code from Java to Kotlin.

## Goals

- Preserve behavior (no feature changes during migration)
- Improve null safety and readability
- Adopt Kotlin idioms where they reduce risk and complexity
- Keep the migration incremental and testable

## Workflow

1. Identify the smallest safe slice to migrate first (leaf classes first).
2. Convert one file at a time (Java -> Kotlin).
3. Fix compilation at each step.
4. Run the tightest validation available after each conversion.
5. Move to the next file only after checks pass.

## Patterns

- Getters/setters -> Kotlin properties
- Static members -> `companion object` (or top-level functions when appropriate)
- Anonymous classes -> lambdas (when readability stays high)
- Null checks -> `?.` and `?:` (avoid `!!` unless truly unavoidable)
- Collections -> prefer standard library (`map`, `filter`, `firstOrNull`) when it stays clear

## Android-Specific Guidance

- Prefer ViewBinding/data binding over `findViewById` only when already used in project
- Prefer coroutines over callback chains only when project already uses coroutines
- Keep lifecycle safety: avoid leaking `Activity`/`Context`

## Risk Controls

- Avoid architecture changes during migration
- Keep changes scoped to the migrated file plus minimal call-site fixes
- If migration touches public APIs, document signature changes

## Validation

Run the smallest existing checks that provide confidence:

- `./gradlew test`
- `./gradlew lint`
- `./gradlew assembleDebug`

## Personal Machine Activation

This skill is personal-machine only.

- Add `java-to-kotlin-migration` to `~/.personal-machine-skills.txt`.
- Keep it off shared/shared machines unless you explicitly allowlist it there.
