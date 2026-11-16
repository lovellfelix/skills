#!/usr/bin/env python3
"""event-sources.py — find event-calendar pages of family venues near a place.

Keyless and local-first: OpenStreetMap (zippopotam.us for US ZIPs, Overpass for
venues) finds libraries, museums, zoos, aquariums, nature reserves, arts and
community centres that publish a website; each website is then read for links
to its events calendar. Known calendar platforms are labelled so a caller can
read them the best way:

    libnet     Communico/LibNet library calendars (JS pages; read the
               /eeventcaldata JSON feed instead of the HTML)
    civicplus  CivicPlus city calendars (/calendar.aspx; server-rendered)
    html       anything else

Output (JSON on stdout):
    {"center": {"lat", "lon"},
     "sources": [{"venue", "kind", "distance_km", "url", "platform"}],
     "skipped": [{"venue", "reason"}]}

Usage:
    event-sources.py --zip 75077 [--radius-m 20000] [--max-venues 12]
    event-sources.py --lat 33.07 --lon -97.07 [...]

Only the ZIP or coordinates and the radius go to the map services; venue
websites are fetched like a browser would. Exit 1 when the place cannot be
resolved or the venue search fails.
"""
from __future__ import annotations

import argparse
import json
import math
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from html.parser import HTMLParser

USER_AGENT = "location-search-skill/0.4 (personal assistant; event discovery)"
BROWSER_UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) location-search-skill/0.4"
# Public Overpass instances, tried in order (the main one returns 502/504 under load).
OVERPASS_URLS = ("https://overpass-api.de/api/interpreter",
                 "https://overpass.kumi.systems/api/interpreter")
ZIP_URL = "https://api.zippopotam.us/us/{zip}"

# Venue kinds that run programs for children and families.
VENUE_FILTERS = (
    ('amenity', 'library|community_centre|arts_centre'),
    ('tourism', 'museum|zoo|aquarium|theme_park'),
    ('leisure', 'nature_reserve'),
)
EVENT_WORDS = re.compile(r"event|calendar|storytime|story-time|story time|programs?\b|kids|children|family",
                         re.IGNORECASE)
STRONG_WORDS = re.compile(r"event|calendar", re.IGNORECASE)
SKIP_LINKS = re.compile(r"^(mailto:|tel:|javascript:|#)|\.(pdf|jpe?g|png|gif|docx?)$|reserv|rental|login|"
                        r"facebook\.com|twitter\.com|x\.com|instagram\.com|youtube\.com",
                        re.IGNORECASE)


def http_get(url: str, ua: str = USER_AGENT, timeout: float = 20, data: bytes | None = None) -> bytes:
    req = urllib.request.Request(url, data=data, headers={"User-Agent": ua, "Accept": "*/*"})
    if not url.startswith(("http://", "https://")):
        raise ValueError("only http(s) URLs are fetched")
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return resp.read()


def zip_to_coords(zip_code: str) -> tuple[float, float]:
    if not re.fullmatch(r"\d{5}(-\d{4})?", zip_code):
        raise ValueError("ZIP must be 5 digits (or ZIP+4)")
    data = json.loads(http_get(ZIP_URL.format(zip=zip_code[:5])))
    place = data["places"][0]
    return float(place["latitude"]), float(place["longitude"])


def overpass_query(lat: float, lon: float, radius_m: int) -> str:
    around = f"(around:{radius_m},{lat},{lon})"
    parts = "".join(f'nwr[{key}~"^({values})$"][website]{around};' for key, values in VENUE_FILTERS)
    return f"[out:json][timeout:60];({parts});out center tags;"


def distance_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp, dl = p2 - p1, math.radians(lon2 - lon1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 6371.0 * 2 * math.asin(math.sqrt(a))


def venues_from_overpass(data: dict, lat: float, lon: float) -> list[dict]:
    """Named venues with a website, nearest first, one per website."""
    out, seen = [], set()
    for el in data.get("elements", []):
        tags = el.get("tags") or {}
        here = el if "lat" in el else (el.get("center") or {})
        website, name = (tags.get("website") or "").strip(), (tags.get("name") or "").strip()
        if not website or not name or "lat" not in here:
            continue
        if not website.startswith(("http://", "https://")):
            website = "https://" + website
        key = website.rstrip("/").lower()
        if key in seen:
            continue
        seen.add(key)
        kind = tags.get("amenity") or tags.get("tourism") or tags.get("leisure") or ""
        out.append({"venue": name, "kind": kind, "website": website,
                    "distance_km": round(distance_km(lat, lon, here["lat"], here["lon"]), 1)})
    return sorted(out, key=lambda v: v["distance_km"])


class _Links(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.links: list[tuple[str, str]] = []
        self._href: str | None = None
        self._text: list[str] = []

    def handle_starttag(self, tag, attrs):
        if tag == "a":
            self._href = dict(attrs).get("href") or None
            self._text = []

    def handle_data(self, data):
        if self._href is not None:
            self._text.append(data)

    def handle_endtag(self, tag):
        if tag == "a" and self._href is not None:
            self.links.append((self._href, " ".join("".join(self._text).split())))
            self._href = None


def platform_of(url: str) -> str:
    parts = urllib.parse.urlsplit(url)
    if parts.netloc.lower().endswith("libnet.info"):
        return "libnet"
    if parts.path.lower().endswith("calendar.aspx"):
        return "civicplus"
    return "html"


def normalize_source(url: str) -> str:
    """One URL per calendar: LibNet → its /events page; CivicPlus → keep CID only."""
    parts = urllib.parse.urlsplit(url)
    if platform_of(url) == "libnet":
        return f"{parts.scheme}://{parts.netloc}/events"
    if platform_of(url) == "civicplus":
        cid = urllib.parse.parse_qs(parts.query).get("CID")
        query = f"CID={cid[0]}" if cid else ""
        return urllib.parse.urlunsplit((parts.scheme, parts.netloc, "/calendar.aspx", query, ""))
    return urllib.parse.urlunsplit((parts.scheme, parts.netloc, parts.path, parts.query, ""))


def event_links(html: str, base: str, limit: int = 1) -> list[str]:
    """The likeliest events-calendar links on a venue page, best first."""
    parser = _Links()
    parser.feed(html)
    base_host = urllib.parse.urlsplit(base).netloc.lower()
    scored: dict[str, int] = {}
    for href, text in parser.links:
        if SKIP_LINKS.search(href) or not (EVENT_WORDS.search(href) or EVENT_WORDS.search(text)):
            continue
        url = urllib.parse.urljoin(base, href)
        if not url.startswith(("http://", "https://")):
            continue
        platform = platform_of(url)
        # Single events are found through their calendar; a LibNet event link
        # still names the calendar, so keep that one.
        if re.search(r"[?&]EID=", url, re.IGNORECASE) or (
                re.search(r"/events?/\d+", url) and platform != "libnet"):
            continue
        host = urllib.parse.urlsplit(url).netloc.lower()
        if host != base_host and platform == "html":
            continue
        score = {"libnet": 30, "civicplus": 20}.get(platform, 0)
        score += 10 if STRONG_WORDS.search(href) or STRONG_WORDS.search(text) else 0
        url = normalize_source(url)
        scored[url] = max(scored.get(url, 0), score)
    best = sorted(scored, key=lambda u: -scored[u])
    return [u for u in best if scored[u] > 0][:limit]


def query_overpass(query: str, fetch=http_get) -> dict:
    body = urllib.parse.urlencode({"data": query}).encode()
    last: Exception | None = None
    for url in OVERPASS_URLS:
        try:
            return json.loads(fetch(url, timeout=90, data=body))
        except (urllib.error.URLError, OSError, ValueError) as exc:
            last = exc
    raise last if last else ValueError("no Overpass instance configured")


def discover(lat: float, lon: float, radius_m: int, max_venues: int, fetch=http_get) -> dict:
    data = query_overpass(overpass_query(lat, lon, radius_m), fetch)
    sources, skipped, seen = [], [], set()
    for venue in venues_from_overpass(data, lat, lon)[:max_venues]:
        if platform_of(venue["website"]) != "html":
            links = [normalize_source(venue["website"])]  # the website is the calendar
        else:
            try:
                html = fetch(venue["website"], ua=BROWSER_UA, timeout=15).decode("utf-8", "replace")
            except urllib.error.HTTPError as exc:
                skipped.append({"venue": venue["venue"], "reason": f"website returned HTTP {exc.code}"})
                continue
            except (urllib.error.URLError, OSError, ValueError) as exc:
                skipped.append({"venue": venue["venue"],
                                "reason": f"website unreachable ({type(exc).__name__})"})
                continue
            links = event_links(html, venue["website"])
        if not links:
            skipped.append({"venue": venue["venue"], "reason": "no events link on its website"})
        for url in links:
            if url in seen:
                continue
            seen.add(url)
            sources.append({"venue": venue["venue"], "kind": venue["kind"],
                            "distance_km": venue["distance_km"], "url": url,
                            "platform": platform_of(url)})
    return {"center": {"lat": lat, "lon": lon}, "sources": sources, "skipped": skipped}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    where = parser.add_mutually_exclusive_group(required=True)
    where.add_argument("--zip", help="US ZIP code")
    where.add_argument("--lat", type=float, help="latitude (with --lon)")
    parser.add_argument("--lon", type=float)
    parser.add_argument("--radius-m", type=int, default=20000, help="search radius in metres (default 20000)")
    parser.add_argument("--max-venues", type=int, default=12, help="nearest venues to read (default 12)")
    args = parser.parse_args(argv)
    if args.lat is not None and args.lon is None:
        parser.error("--lat needs --lon")
    if not 500 <= args.radius_m <= 80000:
        parser.error("--radius-m must be between 500 and 80000")
    try:
        lat, lon = zip_to_coords(args.zip) if args.zip else (args.lat, args.lon)
        result = discover(lat, lon, args.radius_m, max(1, args.max_venues))
    except (urllib.error.URLError, OSError, ValueError, KeyError, IndexError) as exc:
        print(f"event-sources: {type(exc).__name__}: {exc}", file=sys.stderr)
        return 1
    json.dump(result, sys.stdout, indent=1)
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
