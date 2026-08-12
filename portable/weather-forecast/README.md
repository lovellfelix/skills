# Weather Forecast Skill

Portable skill for current weather and short forecasts using keyless providers.

## Quick Start

```bash
bash scripts/weather.sh today --zip 75077 --json
bash scripts/weather.sh forecast --zip 75077 --days 5 --json
```

If a runtime only allows OpenCode-managed paths, use `bash ~/.config/opencode/scripts/weather.sh ...` as a wrapper to the same shared helper.

## Notes

- ZIP-first workflow keeps prompts simple for personal assistant tasks.
- Open-Meteo provides the forecast data.
- OSM Nominatim handles ZIP geocoding.
- No API key is required for the default flow.
