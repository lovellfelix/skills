---
name: phased-rollout
description: Execute phased deployments across environments with monitoring windows and rollback capability. Use when coordinating multi-environment releases, canary deployments, or high-risk launches requiring explicit safety gates.
version: 0.1.0
portable: false
tags: [deployment, rollout, release, operations, opencode, work]
---

# Phased Rollout Skill

Use this skill when planning or executing staged production rollouts with safety gates.

## Work Machine Activation

- This is a work-machine-only skill.
- It is linked only when the local work-machine flag file exists: `~/.work-env-skills`.
- The runtime linker can use a custom flag path via `SKILL_WORK_MACHINE_FLAG_FILE=/path/to/flag`.

## What I do

- Deploy progressively through dev, staging, and production phases.
- Enforce monitoring windows between rollout phases.
- Require pre-deploy checks before advancing to the next phase.
- Keep rollback points and audit-friendly deployment state.

## When to use me

- Coordinated multi-environment releases with explicit go/no-go gates.
- High-risk launches that require canary or phased progression.
- Incident-sensitive changes where fast rollback readiness is required.
- Resuming interrupted rollouts from the last known good phase.
