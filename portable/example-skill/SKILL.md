---
name: example-skill
description: Portable starter skill package for defining concise, tool-agnostic workflows.
version: 0.1.0
portable: true
tags: [starter, template, portable]
---

# Example Skill

## What this skill does

Provides a minimal template for writing portable skills with a clear workflow and shared structure.

## Use when

- Creating a new portable skill package.
- Standardizing skill layout across runtimes.
- Documenting repeatable task workflows in a concise format.

## Do not use when

- The task requires runtime-specific behavior only.
- The work is a one-off note with no reuse value.

## Inputs expected

- Task objective and expected outcome.
- Constraints, quality checks, and required artifacts.
- Any runtime adapters that must consume this skill.

## Workflow

1. Define scope and expected outputs.
2. Capture the smallest reusable workflow.
3. Add core patterns and decision points.
4. Link examples and references for deeper detail.
5. Validate metadata and adapter mappings.

## Core patterns

- Keep instructions action-oriented and short.
- Separate portable guidance from runtime wiring.
- Prefer explicit inputs, checks, and completion criteria.

## Examples and reference

- `examples/`: concrete usage snippets.
- `reference/`: supporting docs and rationale.
- `scripts/`: optional helper automation.
