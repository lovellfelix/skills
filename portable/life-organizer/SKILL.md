---
name: life-organizer
description: Use when the user asks to review personal reminders, calendar events, Apple Notes context, family plans, or general life-admin tasks on a macOS machine.
version: 0.1.0
portable: true
tags: [personal, reminders, calendar, notes, family, planning, portable, macos]
applies_to: [personal-assistant, life, planning, reminders]
---

# Life Organizer Skill

## What This Skill Covers

- Reviewing Apple Reminders, Calendar, and Notes together
- Planning family events and general life-admin tasks
- Turning loose reminders into concrete next actions, owners, and due dates
- Building a quick personal status view for the week or upcoming event

## Platform Rule

This skill depends on macOS Apple app automation.

Use these shared helpers only:

```bash
bash ~/.dotfiles/hacks/macos-automation/apple-reminders.sh
bash ~/.dotfiles/hacks/macos-automation/apple-calendar.sh
bash ~/.dotfiles/hacks/macos-automation/apple-notes-safe.sh
bash ~/.dotfiles/hacks/personal-assistant/location-helper.sh
bash ~/.dotfiles/hacks/personal-assistant/weather.sh
```

Never call raw `osascript` directly when these wrappers exist.

## Default Review Workflow

### 1. Gather the current picture

```bash
bash ~/.dotfiles/hacks/macos-automation/apple-calendar.sh today --json
bash ~/.dotfiles/hacks/macos-automation/apple-calendar.sh week --json
bash ~/.dotfiles/hacks/macos-automation/apple-reminders.sh overdue --json
bash ~/.dotfiles/hacks/macos-automation/apple-reminders.sh today --json
bash ~/.dotfiles/hacks/macos-automation/apple-reminders.sh all --json
bash ~/.dotfiles/hacks/macos-automation/apple-notes-safe.sh read-context
```

### 2. Pull targeted note context when needed

```bash
bash ~/.dotfiles/hacks/macos-automation/apple-notes-safe.sh list-tags 30
bash ~/.dotfiles/hacks/macos-automation/apple-notes-safe.sh find-tagged "family,health" 20
bash ~/.dotfiles/hacks/macos-automation/apple-notes-safe.sh link-personal-context "family,school" 10 --json
```

### 3. Synthesize into a usable plan

Return a concise answer with:

- urgent items first
- what is due today/overdue
- upcoming calendar constraints
- missing follow-ups or reminders to create
- one recommended next action

## Family Event Planning Workflow

Use this when planning birthdays, outings, appointments, school events, or trips.

1. Identify date, attendees, and constraints.
2. Review calendar conflicts.
3. Review related reminders and Apple Notes context.
4. Add/retag notes if information is fragmented.
5. Build a checklist with owner, due date, and fallback.
6. If location/weather matters, use the shared helpers.

Useful commands:

```bash
bash ~/.dotfiles/hacks/macos-automation/apple-calendar.sh search "birthday" --json
bash ~/.dotfiles/hacks/macos-automation/apple-reminders.sh search "party" --json
bash ~/.dotfiles/hacks/macos-automation/apple-notes-safe.sh suggest-tags "Alice birthday" "guest list cake venue ideas"
bash ~/.dotfiles/hacks/macos-automation/apple-notes-safe.sh write-tagged "family,event-birthday" "Alice birthday" "<p>Guest list, cake, venue ideas</p>"
bash ~/.dotfiles/hacks/personal-assistant/location-helper.sh find-nearby "park" 33.0 -97.0 5000
bash ~/.dotfiles/hacks/personal-assistant/weather.sh forecast --zip 75077 --days 5 --json
```

## Reminder Cleanup Workflow

When the user wants to reorganize life admin:

- review overdue reminders first
- group related reminders by family/topic/time horizon
- identify reminders that should become calendar events
- identify reminders that need note context
- suggest 3-5 concrete next actions max

Useful commands:

```bash
bash ~/.dotfiles/hacks/macos-automation/apple-reminders.sh overdue --json
bash ~/.dotfiles/hacks/macos-automation/apple-reminders.sh today --json
bash ~/.dotfiles/hacks/macos-automation/apple-reminders.sh lists
bash ~/.dotfiles/hacks/macos-automation/apple-reminders.sh show "Family" --json
bash ~/.dotfiles/hacks/macos-automation/apple-notes-safe.sh improve-tag-cluster "family,school" 20
```

## Output Patterns

### Daily life review

- Today
- Overdue
- Upcoming
- Notes/context to revisit
- Best next action

### Family event plan

- Goal
- Constraints
- Checklist
- Risks / fallback
- Next action

### General life-admin cleanup

- Must do now
- Can batch later
- Waiting on someone else
- Missing reminder or note

## Rules

- Never invent personal data; summarize only what the scripts return.
- Keep work context out of Apple Notes workflows.
- Prefer stable shared tags like `family`, `school`, `health`, `event-birthday`, `resource-school`.
- If a reminder really belongs on the calendar, say so explicitly.
- If location or weather affects the plan, include one fallback.

## Validation

```bash
bash ~/.dotfiles/hacks/macos-automation/apple-calendar.sh today --json
bash ~/.dotfiles/hacks/macos-automation/apple-reminders.sh today --json
bash ~/.dotfiles/hacks/macos-automation/apple-notes-safe.sh list-tags 10
```
