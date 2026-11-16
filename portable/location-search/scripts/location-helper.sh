#!/usr/bin/env bash
# Location helper for personal assistant
# Uses macOS CoreLocation and web APIs for location-based queries

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Overpass answers HTTP 406 to curl's default User-Agent; every call sends this.
UA="location-search-skill/0.4 (personal assistant)"
if [[ -f "$SCRIPT_DIR/error-handling.sh" ]]; then
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/error-handling.sh"
else
  die() { echo "ERROR: $*" >&2; exit 1; }
  log_error() { echo "ERROR: $*" >&2; }
  log_warn() { echo "WARN: $*" >&2; }
  log_info() { echo "INFO: $*"; }
  require_command() { if ! command -v "$1" &>/dev/null; then log_error "Required command not found: $1"; [[ -n "$2" ]] && log_info "Install: $2"; return 1; fi; return 0; }
fi

# Get user's current location using macOS CoreLocationCLI (if installed)
# Or fall back to IP-based geolocation
get_current_location() {
    # Try CoreLocationCLI if available
    if command -v CoreLocationCLI &>/dev/null; then
    if ! CoreLocationCLI -json 2>/dev/null | jq -r '.latitude, .longitude' | paste -sd ',' -; then
            log_warn "CoreLocationCLI failed, falling back to IP geolocation"
            log_info "Tip: grant Location permission to Terminal or install corelocationcli via: brew install corelocationcli"
            get_ip_location
        fi
        return
    fi
    
    # Fall back to IP-based location
    get_ip_location
}

get_ip_location() {
    local output
    if ! output=$(curl -fsSL -A "$UA" --connect-timeout 10 --max-time 20 "https://ipapi.co/json/" 2>&1); then
        log_error "IP geolocation failed"
        log_info "Check network connectivity"
        return 1
    fi
    
    if ! echo "$output" | jq -r '"\(.latitude),\(.longitude)"' 2>/dev/null; then
        log_error "Invalid response from geolocation service"
        return 1
    fi
}

# Get location from zip code
get_location_from_zip() {
    local zip="$1"
    local output
    
    if ! output=$(curl -fsSL -A "$UA" --connect-timeout 10 --max-time 20 "https://api.zippopotam.us/us/${zip}" 2>&1); then
        log_error "ZIP code lookup failed: $zip"
        log_info "Verify ZIP code is valid US postal code"
        return 1
    fi
    
    if ! echo "$output" | jq -r '.places[0] | "\(.latitude),\(.longitude)"' 2>/dev/null; then
        log_error "Invalid ZIP code or API response: $zip"
        return 1
    fi
}

# Find places nearby using Overpass API (OpenStreetMap - free, no API key)
find_nearby() {
    local query="$1"
    local lat="$2"
    local lon="$3"
    local radius="${4:-2000}"  # default 2km
    
    # Validate coordinates
    if ! [[ "$lat" =~ ^-?[0-9]+\.?[0-9]*$ ]] || ! [[ "$lon" =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
        log_error "Invalid coordinates: lat=$lat, lon=$lon"
        return 1
    fi
    
    # Map common queries to OSM tags
    local osm_query
    case "$query" in
        coffee*|cafe*)
            osm_query='amenity~"cafe|coffee_shop"'
            ;;
        restaurant*|food*)
            osm_query='amenity="restaurant"'
            ;;
        gas*)
            osm_query='amenity="fuel"'
            ;;
        hospital*)
            osm_query='amenity="hospital"'
            ;;
        pharmacy*)
            osm_query='amenity="pharmacy"'
            ;;
        atm*)
            osm_query='amenity="atm"'
            ;;
        park*)
            osm_query='leisure="park"'
            ;;
        gym*)
            osm_query='leisure="fitness_centre"'
            ;;
        librar*)
            osm_query='amenity="library"'
            ;;
        museum*)
            osm_query='tourism="museum"'
            ;;
        zoo*)
            osm_query='tourism="zoo"'
            ;;
        playground*)
            osm_query='leisure="playground"'
            ;;
        *)
            osm_query="name~\"$query\""
            ;;
    esac
    
    # nwr: buildings and areas (most libraries, parks, stores) are ways, not
    # nodes; "out center" gives them a point.
    local overpass_query="[out:json][timeout:40];nwr[${osm_query}](around:${radius},${lat},${lon});out center tags;"
    local output="" server

    # One request per server (rate limit: 1 req/sec); the main server is
    # often slow or answers 502/504, so a mirror is tried next.
    for server in https://overpass-api.de/api/interpreter https://overpass.kumi.systems/api/interpreter; do
        if output=$(curl -fsSL -A "$UA" \
            --connect-timeout 15 \
            --max-time 90 \
            --data-urlencode "data=${overpass_query}" \
            "$server" 2>/dev/null); then
            break
        fi
        output=""
    done
    if [[ -z "$output" ]]; then
        log_error "Overpass API request failed"
        log_info "Check network connectivity or try again (rate limit: 1 req/sec)"
        return 1
    fi

    if [[ "$(jq '[.elements[]? | select(.tags.name)] | length' <<< "$output" 2>/dev/null || echo 0)" == 0 ]]; then
        log_warn "No results found for: $query"
        return 1
    fi
    jq -r '.elements[] | select(.tags.name) | (if .lat then . else .center end) as $p
      | ([.tags["addr:housenumber"], .tags["addr:street"], .tags["addr:city"]] | map(select(. != null)) | join(" ")) as $addr
      | "\(.tags.name) | \($p.lat),\($p.lon) | \($addr)"' <<< "$output" | head -10
}

# Calculate distance between two points (Haversine formula)
calculate_distance() {
    local lat1="$1"
    local lon1="$2"
    local lat2="$3"
    local lon2="$4"
    
    # Use bc for calculation
    local distance
    distance=$(cat <<EOF | bc -l
        define haversine(lat1, lon1, lat2, lon2) {
            r = 6371000;  /* Earth radius in meters */
            phi1 = lat1 * 4*a(1)/180;
            phi2 = lat2 * 4*a(1)/180;
            dphi = (lat2 - lat1) * 4*a(1)/180;
            dlambda = (lon2 - lon1) * 4*a(1)/180;
            
            a = s(dphi/2)^2 + c(phi1) * c(phi2) * s(dlambda/2)^2;
            c = 2 * a(sqrt(a) / sqrt(1-a));
            
            return r * c;
        }
        haversine($lat1, $lon1, $lat2, $lon2)
EOF
)
    echo "$distance"
}

# Event calendars of family venues near a place, then their text: see
# event-sources.py and event-pages.py (Python stdlib, no API key).
get_local_events() {
    local lat="$1" lon="$2" radius_km="${3:-10}"
    python3 "$SCRIPT_DIR/event-sources.py" --lat "$lat" --lon "$lon" --radius-m "$((radius_km * 1000))"
}

# Main command router
case "${1:-help}" in
    current-location)
        get_current_location
        ;;
    
    location-from-zip)
        get_location_from_zip "$2"
        ;;
    
    find-nearby)
        # Usage: location-helper.sh find-nearby "coffee" "37.7749" "-122.4194" [radius]
        find_nearby "$2" "$3" "$4" "${5:-2000}"
        ;;
    
    distance)
        # Usage: location-helper.sh distance lat1 lon1 lat2 lon2
        calculate_distance "$2" "$3" "$4" "$5"
        ;;
    
    events)
        get_local_events "$2" "$3" "${4:-10}"
        ;;

    event-sources)
        # Usage: location-helper.sh event-sources --zip 94102 [--radius-m 20000]
        shift; exec python3 "$SCRIPT_DIR/event-sources.py" "$@"
        ;;

    event-pages)
        # Usage: location-helper.sh event-sources ... | jq .sources | location-helper.sh event-pages
        shift; exec python3 "$SCRIPT_DIR/event-pages.py" "$@"
        ;;
    
    help|*)
        cat <<HELP
Location Helper - macOS native location utilities

Usage:
    location-helper.sh current-location
        Get current location (lat,lon)
    
    location-helper.sh location-from-zip <zip>
        Convert zip code to coordinates
    
    location-helper.sh find-nearby <query> <lat> <lon> [radius_m]
        Find places near coordinates (default: 2km radius)
        Examples: coffee, restaurant, gas, hospital, pharmacy
    
    location-helper.sh distance <lat1> <lon1> <lat2> <lon2>
        Calculate distance between two points (meters)
    
    location-helper.sh events <lat> <lon> [radius_km]
        Event calendars of family venues nearby (default: 10km radius)

    location-helper.sh event-sources --zip <zip> [--radius-m M] [--max-venues N]
        Libraries, museums, zoos, nature reserves... near a ZIP and the
        events-calendar page of each (JSON; LibNet/CivicPlus labelled)

    location-helper.sh event-pages [--date D] [--days N] < sources.json
        Read those calendars as compact text (JSON), for a model to extract

Examples:
    # Find coffee shops near user's location
    location-helper.sh find-nearby "coffee" 37.7749 -122.4194
    
    # Get current location and find nearby restaurants
    coords=\$(location-helper.sh current-location)
    location-helper.sh find-nearby "restaurant" \${coords//,/ } 5000

Notes:
    - Uses free OpenStreetMap Overpass API (no API key required)
    - Respects Overpass rate limits (1 req/sec)
    - Falls back to IP geolocation if CoreLocationCLI unavailable
    - For better accuracy, install: brew install corelocationcli
HELP
        ;;
esac
