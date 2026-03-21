---
name: personal-planning
description: Use when planning trips, family outings, personal events, or life milestones with concrete actions and contingencies.
version: 0.1.0
portable: false
tags: [planning, personal, travel, events, opencode]
---

# Personal Planning

Create practical, low-stress plans for trips, events, and personal goals.

## Planning Categories

| Category | Examples | Focus |
|----------|----------|-------|
| Day Trips | Beach, museum, hiking | Timing, packing, meals, parking |
| Weekend Getaways | Nearby city, cabin, camping | Lodging, route, activity pacing |
| Vacations | Flight + hotel trips | Booking, itinerary, budget, risks |
| Events | Birthday, BBQ, reunion | Guests, food, setup, cleanup |
| Milestones | Moving, wedding prep | Timeline, vendors, dependencies |

## 5-Phase Framework

1. Dream: define outcome, people, and rough dates.
2. Research: compare options, costs, and constraints.
3. Book: lock reservations and major logistics.
4. Prepare: complete checklists and confirmations.
5. Enjoy: execute with backup plans and safety info.

## Output Template

```markdown
# Plan: [Title]
**Dates**: [Start] - [End]
**Participants**: [Names]

## Goal
[One clear sentence]

## Schedule
| Time | Activity | Location | Notes |
|------|----------|----------|-------|
| ...  | ...      | ...      | ...   |

## Pre-Plan Checklist
| Task | Owner | Due | Status |
|------|-------|-----|--------|
| ...  | ...   | ... | [ ]    |

## Budget
| Category | Estimate | Actual |
|----------|----------|--------|
| ...      | $X       |        |

## Risks & Backup Plans
| Risk | Backup |
|------|--------|
| ...  | ...    |

## Emergency Info
- Local emergency number
- Nearest hospital/urgent care
- Critical reservation numbers
```

## Planning Rules

- Prefer concrete actions over generic advice.
- Add owners, due dates, and success criteria to each key task.
- Include at least one weather/logistics fallback for major activities.
- Keep plans scannable with tables and short bullets.

## Preference Learning (silent)

Capture recurring preferences in session memory when users reveal them.

```javascript
session-memory_track_user_preference({ user_id: "default", preference_key: "travel_style", preference_value: "mid-range" })
session-memory_track_user_preference({ user_id: "default", preference_key: "accommodation_preference", preference_value: "Airbnb over hotels" })
session-memory_track_user_preference({ user_id: "default", preference_key: "dietary_restrictions", preference_value: "nut allergy" })
```
