---
name: location-search
description: "Location search and geocoding with a no-API-key default flow, including ZIP/postal-code based nearby lookup."
version: 0.2.0
portable: true
tags: [maps, geocode, location, search, routing, navigation, places, portable]
applies_to: [personal-assistant, workflow, automation]
---

# Location Search Skill

## What This Skill Covers

- No-key location search using free OpenStreetMap services
- ZIP/postal-code-first workflows for privacy-preserving "near me" requests
- Nearby place lookup and basic distance calculations
- Practical fallback handling for invalid inputs and API limits

## When to Use This Skill

Use this skill when the user asks for:

- "near me" discovery (coffee, parks, pharmacy, etc.)
- address or ZIP/postal geocoding
- quick distance checks between points
- local suggestions without paid map providers

## Default No-Key Workflow

Default behavior should not require any API key.

1. Resolve a location anchor from one of: saved ZIP/postal code, explicit ZIP/postal input, or current location fallback.
2. Convert anchor to coordinates.
3. Run nearby search with Overpass (OpenStreetMap).
4. Return concise, user-facing results with place name and address.

Use this script entrypoint:

```bash
bash ~/.config/opencode/scripts/location-helper.sh
```

Supported commands:

```bash
bash ~/.config/opencode/scripts/location-helper.sh current-location
bash ~/.config/opencode/scripts/location-helper.sh location-from-zip 94102
bash ~/.config/opencode/scripts/location-helper.sh find-nearby "coffee" 37.7749 -122.4194 2500
bash ~/.config/opencode/scripts/location-helper.sh distance 37.7749 -122.4194 37.7849 -122.4094
```

Do not call `location-search.sh`; this runtime supports `location-helper.sh`.

## ZIP and Postal Code Model

### US ZIP codes (built-in shortcut)

- Use `location-from-zip <zip>` for US ZIP and ZIP+4 input.
- Examples: `94102`, `10001`, `60614-1234`.
- Provider: `zippopotam.us` (free, no key).

```bash
bash ~/.config/opencode/scripts/location-helper.sh location-from-zip 94102
```

### International postal codes (no-key geocoding)

- Use Nominatim queries with postal code plus country context.
- Examples: `SW1A 1AA, UK`, `10115, DE`, `75008, FR`.
- Provider: `nominatim.openstreetmap.org` (free, no key).

```bash
curl -fsSL "https://nominatim.openstreetmap.org/search?format=jsonv2&limit=1&q=SW1A%201AA%2C%20UK"
```

Guidance:

- Always include country for ambiguous postal codes.
- If the first lookup fails, retry with city + country context.
- Store the user preference as postal text if the country is non-US.

## MCP Preference Pattern

Store location preference in MCP memory and reuse it for future "near me" tasks.

```typescript
session-memory_track_user_preference({
  user_id: "default",
  preference_key: "zip_code",
  preference_value: "94102",
  confidence: 1.0
})
```

For non-US users, use `postal_code` or a country-qualified value (for example, `SW1A 1AA, UK`).

## Provider and API Key Rules

| Use case | Default provider | API key required |
| --- | --- | --- |
| ZIP to coordinates (US) | zippopotam.us | No |
| Postal/address geocoding | OSM Nominatim | No |
| Nearby place search | OSM Overpass | No |
| High-volume commercial geocoding/routing | Google or Mapbox | Yes (optional path only) |

Key policy:

- Default workflow: no API key required.
- Optional provider upgrades: API keys are needed only when you explicitly choose Google/Mapbox for quota/features.

## Practical Workflows

### "Find coffee near my ZIP"

```bash
coords=$(bash ~/.config/opencode/scripts/location-helper.sh location-from-zip 94102)
lat=${coords%%,*}
lon=${coords##*,}
bash ~/.config/opencode/scripts/location-helper.sh find-nearby "coffee" "$lat" "$lon" 2500
```

### "Find parks near my current location"

```bash
coords=$(bash ~/.config/opencode/scripts/location-helper.sh current-location)
lat=${coords%%,*}
lon=${coords##*,}
bash ~/.config/opencode/scripts/location-helper.sh find-nearby "park" "$lat" "$lon" 3000
```

### "How far is point A from point B?"

```bash
bash ~/.config/opencode/scripts/location-helper.sh distance 37.7749 -122.4194 37.7849 -122.4094
```

## Troubleshooting

- `ZIP lookup failed`: check for US ZIP format; for non-US postal codes use Nominatim query flow.
- `No nearby results`: increase radius (`2000` -> `5000`) or broaden query (`coffee` -> `cafe`).
- `Rate limit response`: wait briefly and retry; keep OSM requests low-volume.
- `Current location unavailable`: install `corelocationcli` (`brew install corelocationcli`) or rely on IP fallback.
- Script not found: use `bash ~/.config/opencode/scripts/location-helper.sh ...`.

## Validation

```bash
bash ~/.config/opencode/scripts/location-helper.sh help
bash ~/.config/opencode/scripts/location-helper.sh location-from-zip 94102
bash ~/.config/opencode/scripts/location-helper.sh find-nearby "coffee" 37.7749 -122.4194 2000
```
