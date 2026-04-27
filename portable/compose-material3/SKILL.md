---
name: compose-material3
description: Use when building Android UI components with Jetpack Compose and Material Design 3 to produce modern, distinctive interfaces that avoid generic boilerplate.
version: 0.1.0
portable: false
tags: [android, kotlin, compose, material3, ui]
---

# Compose Material 3

Use this skill to design and implement polished Android interfaces with Jetpack Compose and Material 3.

## Outcomes

- Build visually intentional screens with clear hierarchy and spacing rhythm
- Apply Material 3 tokens for color, typography, shape, and elevation
- Improve component quality for default, pressed, focused, disabled, and loading states
- Avoid generic patterns (flat structure, repetitive spacing, weak contrast, default-only styling)

## When To Use

- Building a new Compose screen or flow
- Migrating XML views to Compose with modern Material 3 structure
- Refreshing a UI that feels boilerplate or visually inconsistent
- Creating a reusable design system layer in Compose

## Implementation Checklist

1. Define semantic tokens (`colorScheme`, typography scale, shape scale, spacing constants).
2. Structure layout with intentional sections (hero/content/actions) and responsive constraints.
3. Build components with explicit state handling and accessible touch targets.
4. Add focused motion (entry, state transition, feedback), not decorative animation overload.
5. Validate light/dark behavior and contrast before finalizing.

## Material 3 Guardrails

- Prefer semantic color roles (`primaryContainer`, `surfaceVariant`) over hardcoded hex values.
- Keep typography roles consistent (`headlineSmall`, `titleMedium`, `bodyLarge`) across screens.
- Use consistent spacing increments; avoid arbitrary per-component spacing.
- Ensure state visibility without relying on color alone.

## Validation

- Verify screen behavior on phone and tablet breakpoints
- Check TalkBack labels and focus order
- Confirm contrast and readability in light and dark themes
- Run project checks (`./gradlew test`, `./gradlew lint`, and a debug build)

## Personal Machine Activation

This skill is personal-machine only.

- Add `compose-material3` to the allowlist in `~/.personal-machine-skills.txt`.
- Bootstrap and runtime sync only expose it when that allowlist includes the skill.
