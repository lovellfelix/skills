---
name: incident-postmortem
description: "Use when writing a postmortem after a production incident or operational failure to produce a concise, blameless analysis focused on decisions, causes, and concrete follow-ups."
version: 0.3.0
portable: true
tags: [incident, postmortem, reliability, root-cause-analysis, operations]
---

# Incident Postmortem

## Style Defaults

- Concise, factual, and no-blame.
- Focus on decision points, not raw event dumps.
- Separate trigger, contributing factors, and root cause.
- Emphasize operational learning: prevention, detection, response.
- Keep it readable in one pass.

## What I Do

- Build postmortems that explain what happened and why.
- Distill timeline to moments that changed incident trajectory.
- Clarify causal layers:
  - Trigger
  - Contributing Factors
  - Root Cause
- Produce actionable, owned follow-ups tied to incident evidence.

## When to Use Me

- You need a postmortem after production degradation or outage.
- Existing write-up is a log dump with weak analysis.
- Follow-ups are vague or unowned.
- Team needs clear operational learning without blame language.

## Output Structure

Use this exact structure:

1. Summary (mandatory)
2. Impact (mandatory)
3. Timeline (mandatory)
4. Trigger (mandatory)
5. Contributing Factors (mandatory)
6. Root Cause (mandatory)
7. Resolution (mandatory)
8. What Worked (optional for minor incidents)
9. What Didn't (optional for minor incidents)
10. Follow-Ups (mandatory)

## Output Format

- Keep the document readable in one pass.
- Optimize for clarity, not narrative.
- Prefer bullets over long paragraphs.

Section expectations:

- Summary: 2–3 lines (what, duration, impact)
- Impact: quantified
- Timeline: key decisions only (HH:MM UTC format)
- Follow-Ups: concrete and owned

## Guidelines / Constraints

- Timeline should fit roughly one screen.
- Identify the primary trigger; include secondary only if impactful.
- Contributing factors explain severity or delay.
- Root cause explains recurrence risk.
- Resolution states what restored service.
- No therapy language, no blame.
- Make detection explicit.

## Follow-Up Rules

Each follow-up must include:
- Owner
- Action
- Type (`prevent`, `detect`, `respond`)
- Due date
- Traceability (link to incident ticket, alert, or log entry)

## Steps

1. Gather incident data (ask user for timeline, impact, resolution if not in context).
2. Identify trigger, contributing factors, and root cause separately.
3. Draft each section in order: Summary → Root Cause → Follow-Ups.
4. Apply Follow-Up Rules to every follow-up item.
5. Validate: no blame language, timeline fits one screen, all follow-ups owned.
