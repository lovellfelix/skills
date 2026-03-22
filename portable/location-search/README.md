# Location Search Skill

Portable skill for location search, geocoding, and nearby discovery with a no-API-key default flow.

## Quick Start

```bash
bash ~/.config/opencode/scripts/location-helper.sh help
bash ~/.config/opencode/scripts/location-helper.sh location-from-zip 94102
bash ~/.config/opencode/scripts/location-helper.sh find-nearby "coffee" 37.7749 -122.4194 2000
```

Default behavior uses free OpenStreetMap-based services and does not require API keys.

## ZIP and Postal Code Usage

### US ZIP codes (no key)

```bash
bash ~/.config/opencode/scripts/location-helper.sh location-from-zip 10001
```

### International postal codes (no key)

Use Nominatim with postal text plus country context:

```bash
curl -fsSL "https://nominatim.openstreetmap.org/search?format=jsonv2&limit=1&q=SW1A%201AA%2C%20UK"
```

## API Key Policy

| Scenario | API key |
| --- | --- |
| Default geocoding and nearby search (OSM + zippopotam.us) | Not needed |
| Google Maps optional provider | Required |
| Mapbox optional provider | Required |

Use paid providers only when you need higher quotas or provider-specific features.

## Common Workflows

```bash
# ZIP -> coordinates -> nearby search
coords=$(bash ~/.config/opencode/scripts/location-helper.sh location-from-zip 94102)
lat=${coords%%,*}
lon=${coords##*,}
bash ~/.config/opencode/scripts/location-helper.sh find-nearby "restaurant" "$lat" "$lon" 3000
```

```bash
# Current location -> nearby parks
coords=$(bash ~/.config/opencode/scripts/location-helper.sh current-location)
lat=${coords%%,*}
lon=${coords##*,}
bash ~/.config/opencode/scripts/location-helper.sh find-nearby "park" "$lat" "$lon" 3000
```

## Troubleshooting

- ZIP lookup only supports US ZIP values through the helper shortcut.
- For non-US postal codes, use Nominatim query with country context.
- If results are empty, increase radius and retry with a broader query.
- Respect free OSM usage limits for automated workflows.

## Skill Path Resolution

Preferred skill path resolution order:

1. `skills/portable/<name>/SKILL.md`
2. `skills/runtime-specific/opencode/<name>/SKILL.md`
3. Legacy fallback: `~/.config/opencode/skills/<name>/SKILL.md`

See `SKILL.md` for the full workflow and provider guidance.

## Optional Paid Provider Example

```env
MAPS_PROVIDER=google
GOOGLE_MAPS_API_KEY=your_key_here
```
