---
name: location-search
description: Use when planning trips, finding nearby places, or integrating location features with a no-API-key default flow, including ZIP or postal-code lookup.
metadata:
  version: 0.4.0
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
bash scripts/location-helper.sh
```

If a runtime restricts execution to OpenCode-managed script paths, use the wrapper instead:

```bash
bash ~/.config/opencode/scripts/location-helper.sh
```

Do not call `location-search.sh`; the supported helper is `location-helper.sh`.

## Personal Machine Activation

This skill is personal-machine only.

- Linked automatically when `~/.overlay/local/.enabled` is absent (no allowlist to maintain).

## Default No-Key Workflow

1. Resolve a location anchor from one of: saved ZIP/postal code, explicit ZIP/postal input, or current location fallback.
2. Convert that anchor to coordinates.
3. Run nearby search with Overpass (OpenStreetMap).
4. Return concise results with place name and address.

Supported commands:

```bash
bash scripts/location-helper.sh current-location
bash scripts/location-helper.sh location-from-zip 94102
bash scripts/location-helper.sh find-nearby "coffee" 37.7749 -122.4194 2500
bash scripts/location-helper.sh distance 37.7749 -122.4194 37.7849 -122.4094
bash scripts/location-helper.sh event-sources --zip 94102 --radius-m 20000
bash scripts/location-helper.sh event-sources --zip 94102 | jq .sources \
  | bash scripts/location-helper.sh event-pages --days 8
```

`find-nearby` maps library, museum, zoo, playground, park, coffee, restaurant,
gas, hospital, pharmacy, atm and gym to OSM tags (fast, indexed); anything else
is a name match, which Overpass serves slowly.

## Local Events (no API key)

For "what's on for kids near me" style work (the kids-events job uses this):

1. `event-sources` finds libraries, museums, zoos, aquariums, nature reserves,
   arts and community centres near a ZIP that publish a website, then the
   events-calendar link on each site (one per venue, nearest first). Output is
   JSON: `sources` (`venue`, `kind`, `distance_km`, `url`, `platform`) and
   `skipped` (with the reason: blocked, unreachable, no events link).
2. `event-pages` reads those sources as compact text for a model:
   - `libnet` (Communico/LibNet library calendars render in JavaScript): the
     `/eeventcaldata` JSON feed, one line per event with its age group;
     adult/teen/senior-only events are dropped.
   - `civicplus` (`/calendar.aspx`) and `html`: the page as text, scripts and
     styles removed, starting near the first date when the page is long.

Pages are fetched with Python's HTTP client: some city sites (Akamai) refuse
curl. A site that still refuses or renders its calendar only in JavaScript
yields little text; add that venue's direct calendar URL to the caller's own
source list instead. Overpass is slow or returns 502/504 under load; both the
helper and `event-sources` fall back to `overpass.kumi.systems`. Cache the
discovered sources (a week is plenty): venues and calendar links rarely change.

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

## Session Memory

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
coords=$(bash scripts/location-helper.sh location-from-zip 94102)
lat=${coords%%,*}
lon=${coords##*,}
bash scripts/location-helper.sh find-nearby "coffee" "$lat" "$lon" 2500
```

### Find parks near the current location

```bash
coords=$(bash scripts/location-helper.sh current-location)
lat=${coords%%,*}
lon=${coords##*,}
bash scripts/location-helper.sh find-nearby "park" "$lat" "$lon" 3000
```

### Measure distance between two points

```bash
bash scripts/location-helper.sh distance 37.7749 -122.4194 37.7849 -122.4094
```

## Troubleshooting

- `ZIP lookup failed`: verify US ZIP format; for non-US postal codes use Nominatim with country context.
- `No nearby results`: increase radius (`2000` → `5000`) or broaden the query (`coffee` → `cafe`).
- `Current location unavailable`: install `corelocationcli` (`brew install corelocationcli`) or rely on IP fallback.
- If a runtime blocks the shared helper path, retry with the OpenCode wrapper path.

## Validation

```bash
bash scripts/location-helper.sh help
bash scripts/location-helper.sh location-from-zip 94102
bash scripts/location-helper.sh find-nearby "coffee" 37.7749 -122.4194 2000
```
