---
name: weather-forecast
description: Use when the user asks for current weather, today's conditions, or a short forecast without relying on paid weather APIs.
version: 0.1.0
portable: true
tags: [weather, forecast, portable, personal-assistant]
applies_to: [personal-assistant, workflow, automation]
---

# Weather Forecast Skill

## What This Skill Covers

- Current conditions and today's summary
- Short multi-day forecasts
- ZIP-first weather lookup without API keys
- Lat/lon fallback when coordinates are already known

## Preferred Helper Paths

Use the shared helper when possible:

```bash
bash ~/.dotfiles/hacks/personal-assistant/weather.sh
```

If a runtime restricts execution to OpenCode-managed paths, use the wrapper instead:

```bash
bash ~/.config/opencode/scripts/weather.sh
```

## Personal Machine Activation

This skill is personal-machine only.

- Add `weather-forecast` to `~/.personal-machine-skills.txt`.
- Bootstrap/runtime sync only exposes it when that allowlist includes the skill.

## Default No-Key Workflow

1. Prefer a stored ZIP/postal preference when available.
2. Otherwise accept an explicit `--zip` or `--lat/--lon` input.
3. Call the helper.
4. Return concise weather results, not raw API dumps unless JSON was requested.

Supported commands:

```bash
bash ~/.dotfiles/hacks/personal-assistant/weather.sh today --zip 75077 --json
bash ~/.dotfiles/hacks/personal-assistant/weather.sh forecast --zip 75077 --days 5 --json
bash ~/.dotfiles/hacks/personal-assistant/weather.sh today --lat 32.9919 --lon -97.0700 --json
```

## Session-Memory Pattern

If the user often asks for local weather, reuse a saved ZIP value.

```text
session_memory action=track_user_preference category=workflow key=zip_code value=75077 confidence=1.0
```

## Provider Rules

| Use case | Default provider | API key required |
| --- | --- | --- |
| ZIP geocoding | OSM Nominatim | No |
| Weather forecast | Open-Meteo | No |
| Paid weather provider | Optional future path | Yes |

Default behavior stays keyless.

## Practical Workflows

### Today's weather from ZIP

```bash
bash ~/.dotfiles/hacks/personal-assistant/weather.sh today --zip 75077 --json
```

### Five-day forecast from ZIP

```bash
bash ~/.dotfiles/hacks/personal-assistant/weather.sh forecast --zip 75077 --days 5 --json
```

### Forecast from known coordinates

```bash
bash ~/.dotfiles/hacks/personal-assistant/weather.sh forecast --lat 32.9919 --lon -97.0700 --days 3 --json
```

## Troubleshooting

- `Invalid ZIP code`: use a 5-digit US ZIP.
- `Location not specified`: pass `--zip` or `--lat/--lon`.
- `Weather API request failed`: retry once and keep the request volume low.
- If a runtime blocks the shared helper path, retry with the OpenCode wrapper path.

## Validation

```bash
bash ~/.dotfiles/hacks/personal-assistant/weather.sh today --zip 75077 --json
bash ~/.dotfiles/hacks/personal-assistant/weather.sh forecast --zip 75077 --days 3 --json
bash ~/.config/opencode/scripts/weather.sh today --zip 75077 --json
```
