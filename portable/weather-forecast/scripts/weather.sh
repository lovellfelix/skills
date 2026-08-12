#!/usr/bin/env bash
set -euo pipefail

# Weather helper (no API key required)
# - Geocodes ZIP via Nominatim
# - Fetches forecast via Open-Meteo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/error-handling.sh" ]]; then
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/error-handling.sh"
else
  die() { echo "ERROR: $*" >&2; exit 1; }
  log_error() { echo "ERROR: $*" >&2; }
  log_warn() { echo "WARN: $*" >&2; }
  log_info() { echo "INFO: $*"; }
  require_command() {
    if ! command -v "$1" &>/dev/null; then
      log_error "Required command not found: $1"
      [[ -n "${2:-}" ]] && log_info "Install: $2"
      return 1
    fi
    return 0
  }
fi

usage() {
  cat <<'EOF'
Usage: weather.sh <command> [options]

Commands:
  today                 Current + today's summary
  forecast              Multi-day forecast (default: 3 days)

Options:
  --zip <zip>           ZIP code (US)
  --lat <lat> --lon <lon>
  --days <n>            For forecast (default: 3)
  --json                JSON output (default)

Examples:
  weather.sh today --zip 75077 --json
  weather.sh forecast --zip 75077 --days 5 --json
EOF
}

want_json=0
cmd="${1:-}"
shift || true

zip=""
lat=""
lon=""
days=3

cache_dir="${PERSONAL_ASSISTANT_CACHE_DIR:-${OPENCODE_CACHE_DIR:-$HOME/.opencode/cache}}"
zip_cache_file="$cache_dir/weather-zip-cache.json"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) want_json=1; shift ;;
    --zip) zip="${2:-}"; shift 2 ;;
    --lat) lat="${2:-}"; shift 2 ;;
    --lon) lon="${2:-}"; shift 2 ;;
    --days) days="${2:-3}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "(error: unknown arg: $1)" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$cmd" ]]; then
  usage
  exit 2
fi

require_command curl "brew install curl (macOS) or system package manager" || exit 1
require_command python3 "brew install python3 (macOS) or system package manager" || exit 1

mkdir -p "$cache_dir"

normalize_zip() {
  local z="$1"
  z="${z// /}"
  if [[ "$z" =~ ^[0-9]{5}$ ]]; then
    printf '%s' "$z"
    return 0
  fi
  log_error "Invalid ZIP code: $1 (expected 5 digits)"
  return 1
}

if [[ -n "$zip" ]]; then
  if ! zip=$(normalize_zip "$zip"); then
    die "Invalid ZIP code format"
  fi
fi

load_cached_coords() {
  local z="$1"
  [[ -f "$zip_cache_file" ]] || return 1

  python3 - "$z" "$zip_cache_file" <<'PY'
import json
import sys

zip_code=sys.argv[1]
path=sys.argv[2]

try:
  data=json.load(open(path,'r',encoding='utf-8'))
except Exception:
  raise SystemExit(1)

row=data.get(zip_code)
if not row:
  raise SystemExit(1)

lat=row.get('lat')
lon=row.get('lon')
name=row.get('name','')
if not lat or not lon:
  raise SystemExit(1)

print(json.dumps({'lat': lat, 'lon': lon, 'name': name}, ensure_ascii=True))
PY
}

store_cached_coords() {
  local z="$1"
  local la="$2"
  local lo="$3"
  local name="$4"

  python3 - "$z" "$la" "$lo" "$name" "$zip_cache_file" <<'PY'
import json
import sys

z, la, lo, name, path = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5]

try:
  data=json.load(open(path,'r',encoding='utf-8'))
except Exception:
  data={}

data[z]={'lat': la, 'lon': lo, 'name': name}

with open(path,'w',encoding='utf-8') as f:
  json.dump(data,f,indent=2,ensure_ascii=True)
  f.write('\n')
PY
}

geocode_zip() {
  local z="$1"
  local output
  local attempt=0
  local sleep_s=1
  
  # Nominatim requires a User-Agent and rate limiting (max 1 req/sec)
  while [[ $attempt -lt 2 ]]; do
    # Respect rate limiting
    [[ $attempt -gt 0 ]] && sleep "$sleep_s"

    if output=$(curl -sS \
      --connect-timeout 10 \
      --max-time 30 \
      -H 'User-Agent: personal-assistant-weather/1.0 (+https://github.com/lovellfelix/dotfiles)' \
      -H 'Accept: application/json' \
      -w "\n%{http_code}" \
      "https://nominatim.openstreetmap.org/search?format=json&countrycodes=us&limit=1&q=${z}" 2>&1); then
      http_code=$(printf '%s' "$output" | tail -n 1)
      body=$(printf '%s' "$output" | sed '$d')
      if [[ "$http_code" == "200" ]]; then
        output="$body"
        break
      fi

      if [[ "$http_code" == "403" || "$http_code" == "429" ]]; then
        log_warn "Geocoding rate-limited (HTTP $http_code); retrying"
      else
        log_error "Geocoding API request failed (HTTP $http_code)"
        return 1
      fi
    else
      log_error "Geocoding API request failed"
      return 1
    fi

    attempt=$((attempt + 1))
  done

  if [[ -z "${output:-}" ]]; then
    log_error "Geocoding API request failed"
    return 1
  fi
  
  if ! python3 -c 'import json,sys
data=json.load(sys.stdin)
if not data:
  raise SystemExit(1)
row=data[0]
print(json.dumps({"lat": row.get("lat"), "lon": row.get("lon"), "name": row.get("display_name","")}, ensure_ascii=True))' <<<"$output" 2>/dev/null; then
    log_error "No geocoding results for ZIP: $z"
    log_info "Verify ZIP code is valid US postal code"
    return 1
  fi
}

fetch_open_meteo() {
  local la="$1"
  local lo="$2"
  local tz="auto"
  local output

  if ! output=$(curl -fsSL \
    --connect-timeout 10 \
    --max-time 30 \
    -H 'User-Agent: personal-assistant-weather/1.0 (+https://github.com/lovellfelix/dotfiles)' \
    -H 'Accept: application/json' \
    "https://api.open-meteo.com/v1/forecast?latitude=${la}&longitude=${lo}&current=temperature_2m,precipitation,wind_speed_10m&daily=temperature_2m_max,temperature_2m_min,precipitation_sum&temperature_unit=fahrenheit&wind_speed_unit=mph&precipitation_unit=inch&timezone=${tz}" 2>&1); then
    log_error "Weather API request failed"
    log_info "Check network connectivity and try again; Open-Meteo may throttle if abused"
    return 1
  fi
  
  if ! python3 -c 'import json,sys; print(json.dumps(json.load(sys.stdin), ensure_ascii=True))' <<<"$output" 2>/dev/null; then
    log_error "Weather API returned invalid JSON"
    return 1
  fi
}

ensure_coords() {
  if [[ -n "$lat" && -n "$lon" ]]; then
    return 0
  fi
  if [[ -n "$zip" ]]; then
    local cached
    if cached=$(load_cached_coords "$zip" 2>/dev/null); then
      lat=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["lat"])' <<<"$cached")
      lon=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["lon"])' <<<"$cached")
      place=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("name",""))' <<<"$cached")
      export place
      return 0
    fi

    local geo
    if ! geo=$(geocode_zip "$zip"); then
      log_error "Could not geocode ZIP: $zip"
      log_info "Verify ZIP code and network connectivity"
      exit 1
    fi
    lat=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["lat"])' <<<"$geo")
    lon=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["lon"])' <<<"$geo")
    place=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("name",""))' <<<"$geo")
    export place

    store_cached_coords "$zip" "$lat" "$lon" "$place" 2>/dev/null || true
    return 0
  fi
  log_error "Location not specified"
  log_info "Provide --zip <zip> or --lat <lat> --lon <lon>"
  exit 2
}

render_today() {
  python3 -c 'import json,sys
data=json.load(sys.stdin)
daily=data.get("daily",{})
cur=data.get("current",{})
out={
  "source":"open-meteo",
  "place": "'"${place:-}"'" ,
  "coords": {"lat": "'"${lat:-}"'" , "lon": "'"${lon:-}"'"},
  "timezone": data.get("timezone"),
  "current": {
    "time": cur.get("time"),
    "temp_f": cur.get("temperature_2m"),
    "precip_in": cur.get("precipitation"),
    "wind_mph": cur.get("wind_speed_10m"),
  },
  "today": {
    "date": (daily.get("time") or [None])[0],
    "high_f": (daily.get("temperature_2m_max") or [None])[0],
    "low_f": (daily.get("temperature_2m_min") or [None])[0],
    "precip_sum_in": (daily.get("precipitation_sum") or [None])[0],
  }
}
print(json.dumps(out, ensure_ascii=True))'
}

render_forecast() {
  local n="$1"
  python3 -c 'import json,sys
n=int(sys.argv[1])
data=json.load(sys.stdin)
daily=data.get("daily",{})
times=daily.get("time") or []
hi=daily.get("temperature_2m_max") or []
lo=daily.get("temperature_2m_min") or []
ps=daily.get("precipitation_sum") or []
days=[]
for i in range(min(n, len(times))):
  days.append({"date": times[i], "high_f": hi[i] if i < len(hi) else None, "low_f": lo[i] if i < len(lo) else None, "precip_sum_in": ps[i] if i < len(ps) else None})
out={"source":"open-meteo", "timezone": data.get("timezone"), "days": days}
print(json.dumps(out, ensure_ascii=True))' "$n"
}

ensure_coords
raw=$(fetch_open_meteo "$lat" "$lon")

case "$cmd" in
  today)
    if [[ $want_json -eq 1 ]]; then
      render_today <<<"$raw"
    else
      render_today <<<"$raw" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d)'
    fi
    ;;
  forecast)
    if [[ $want_json -eq 1 ]]; then
      render_forecast "$days" <<<"$raw"
    else
      render_forecast "$days" <<<"$raw" | python3 -c 'import json,sys; print(json.load(sys.stdin))'
    fi
    ;;
  *)
    echo "(error: unknown command: $cmd)" >&2
    usage
    exit 2
    ;;
esac
