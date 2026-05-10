---
name: location-search
description: Use when planning trips, finding nearby places, or integrating location features with a no-API-key default flow, including ZIP or postal-code lookup.
metadata:
  version: 0.3.0
  portable: true
  tags: [maps, geocode, location, search, routing, navigation, places]
  applies_to: [personal-assistant, workflow, automation]
---

# Location Search Skill

## What This Skill Covers

- No-key location search using OpenStreetMap services
- ZIP/postal-code-first workflows for privacy-preserving "near me" requests
- Nearby place lookup, current location fallback, and distance checks

## Preferred Helper Paths

Use the shared helper when possible:

```bash
bash ~/.dotfiles/hacks/personal-assistant/location-helper.sh
```

If a runtime restricts execution to OpenCode-managed script paths, use the wrapper instead:

```bash
bash ~/.config/opencode/scripts/location-helper.sh
```

Do not call `location-search.sh`; the supported helper is `location-helper.sh`.

## Personal Machine Activation

This skill is personal-machine only.

- Add `location-search` to `~/.personal-machine-skills.txt`.
- Bootstrap/runtime sync only exposes it when that allowlist includes the skill.

## Default No-Key Workflow

1. Resolve a location anchor from one of: saved ZIP/postal code, explicit ZIP/postal input, or current location fallback.
2. Convert that anchor to coordinates.
3. Run nearby search with Overpass (OpenStreetMap).
4. Return concise results with place name and address.

Supported commands:

```bash
bash ~/.dotfiles/hacks/personal-assistant/location-helper.sh current-location
bash ~/.dotfiles/hacks/personal-assistant/location-helper.sh location-from-zip 94102
bash ~/.dotfiles/hacks/personal-assistant/location-helper.sh find-nearby "coffee" 37.7749 -122.4194 2500
bash ~/.dotfiles/hacks/personal-assistant/location-helper.sh distance 37.7749 -122.4194 37.7849 -122.4094
```

## ZIP and Postal Code Model

### US ZIP codes

- Use `location-from-zip <zip>` for US ZIP and ZIP+4 input.
- Examples: `94102`, `10001`, `60614-1234`.
- Provider: `zippopotam.us` (free, no key).

### International postal codes

- Use Nominatim queries with postal code plus country context.
- Examples: `SW1A 1AA, UK`, `10115, DE`, `75008, FR`.
- Provider: `nominatim.openstreetmap.org` (free, no key).

```bash
curl -fsSL "https://nominatim.openstreetmap.org/search?format=jsonv2&limit=1&q=SW1A%201AA%2C%20UK"
```

Guidance:

- Always include country for ambiguous postal codes.
- If the first lookup fails, retry with city + country context.
- Store non-US values as `postal_code` or country-qualified text.

## Session-Memory Pattern

Reuse stored postal/ZIP preferences for future "near me" flows.

```text
session_memory action=track_user_preference category=workflow key=zip_code value=94102 confidence=1.0
```

## Provider and API Key Rules

| Use case | Default provider | API key required |
| --- | --- | --- |
| ZIP to coordinates (US) | zippopotam.us | No |
| Postal/address geocoding | OSM Nominatim | No |
| Nearby place search | OSM Overpass | No |
| Higher-volume commercial geocoding/routing | Google or Mapbox | Yes |

Default workflow stays keyless unless the user explicitly wants a paid provider.

## Practical Workflows

### Find coffee near a ZIP

```bash
coords=$(bash ~/.dotfiles/hacks/personal-assistant/location-helper.sh location-from-zip 94102)
lat=${coords%%,*}
lon=${coords##*,}
bash ~/.dotfiles/hacks/personal-assistant/location-helper.sh find-nearby "coffee" "$lat" "$lon" 2500
```

### Find parks near the current location

```bash
coords=$(bash ~/.dotfiles/hacks/personal-assistant/location-helper.sh current-location)
lat=${coords%%,*}
lon=${coords##*,}
bash ~/.dotfiles/hacks/personal-assistant/location-helper.sh find-nearby "park" "$lat" "$lon" 3000
```

### Measure distance between two points

```bash
bash ~/.dotfiles/hacks/personal-assistant/location-helper.sh distance 37.7749 -122.4194 37.7849 -122.4094
```

## Troubleshooting

- `ZIP lookup failed`: verify US ZIP format; for non-US postal codes use Nominatim with country context.
- `No nearby results`: increase radius (`2000` → `5000`) or broaden the query (`coffee` → `cafe`).
- `Current location unavailable`: install `corelocationcli` (`brew install corelocationcli`) or rely on IP fallback.
- If a runtime blocks the shared helper path, retry with the OpenCode wrapper path.

## Validation

```bash
bash ~/.dotfiles/hacks/personal-assistant/location-helper.sh help
bash ~/.dotfiles/hacks/personal-assistant/location-helper.sh location-from-zip 94102
bash ~/.dotfiles/hacks/personal-assistant/location-helper.sh find-nearby "coffee" 37.7749 -122.4194 2000
```
