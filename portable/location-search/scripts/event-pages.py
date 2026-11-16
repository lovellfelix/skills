#!/usr/bin/env python3
"""event-pages.py — read event-calendar sources as compact text for a model.

Input (stdin): a JSON array of sources, as event-sources.py prints them under
"sources" ({"url", "platform", "venue"?}), or plain URLs one per line.

    libnet     the calendar's /eeventcaldata JSON feed for the date window;
               one line per event, adults/teens/seniors-only events dropped
    civicplus  the server-rendered calendar page, as text
    html       the page, as text (scripts, styles and markup removed)

Output (stdout, JSON):
    {"version": 1, "pages": [{"venue", "url", "platform", "ok": true, "text"} |
               {"venue", "url", "platform", "ok": false, "error"}]}

Usage:
    event-pages.py [--date YYYY-MM-DD] [--days 8] [--max-chars 6000] < sources.json

Pages are fetched with Python's HTTP client and a browser-like User-Agent:
some city sites refuse curl outright. Exit 1 only on unreadable input.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import date
from html.parser import HTMLParser

# Bumped when the output's fields change incompatibly; callers check it.
FORMAT_VERSION = 1
BROWSER_UA ="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) location-search-skill/0.4"
# An event is dropped when every age group it lists matches this.
ADULT_ONLY = re.compile(r"adult|teen|senior|18\+|21\+", re.IGNORECASE)
# LibNet age groups carry no numbers; a model given only "Tweens" often leaves
# the age range empty, so the usual span goes next to the group.
AGE_HINTS = ((re.compile(r"tween", re.IGNORECASE), "about 9-12 years"),
             (re.compile(r"elementary|school age", re.IGNORECASE), "about 5-11 years"))


def http_get(url: str, timeout: float = 20) -> bytes:
    if not url.startswith(("http://", "https://")):
        raise ValueError("only http(s) URLs are fetched")
    req = urllib.request.Request(url, headers={"User-Agent": BROWSER_UA, "Accept": "*/*"})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return resp.read()


class _Text(HTMLParser):
    SKIP = {"script", "style", "noscript", "svg", "head", "template"}
    BREAK = {"p", "div", "li", "tr", "br", "h1", "h2", "h3", "h4", "h5", "h6", "section", "article"}

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.parts: list[str] = []
        self._skip = 0

    def handle_starttag(self, tag, attrs):
        if tag in self.SKIP:
            self._skip += 1
        elif tag in self.BREAK:
            self.parts.append("\n")

    def handle_endtag(self, tag):
        if tag in self.SKIP and self._skip:
            self._skip -= 1

    def handle_data(self, data):
        if not self._skip:
            self.parts.append(data)


def html_to_text(html: str) -> str:
    parser = _Text()
    parser.feed(html)
    lines = (" ".join(line.split()) for line in "".join(parser.parts).splitlines())
    return "\n".join(line for line in lines if line)


FIRST_DATE = re.compile(
    r"\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?\s+\d{1,2}\b|\b\d{4}-\d{2}-\d{2}\b")


def trim(text: str, max_chars: int) -> str:
    """Keep max_chars, starting near the first date when the page is longer:
    city calendar pages open with kilobytes of navigation."""
    if len(text) > max_chars:
        m = FIRST_DATE.search(text)
        if m:
            text = text[max(0, m.start() - 200):]
    return text[:max_chars]


def platform_of(url: str) -> str:
    parts = urllib.parse.urlsplit(url)
    if parts.netloc.lower().endswith("libnet.info"):
        return "libnet"
    if parts.path.lower().endswith("calendar.aspx"):
        return "civicplus"
    return "html"


def libnet_feed_url(url: str, start: date, days: int) -> str:
    parts = urllib.parse.urlsplit(url)
    req = {"private": False, "date": start.isoformat(), "days": days,
           "locations": [], "ages": [], "types": []}
    query = urllib.parse.urlencode({"event_type": 0, "req": json.dumps(req, separators=(",", ":"))})
    return f"{parts.scheme}://{parts.netloc}/eeventcaldata?{query}"


def libnet_text(events: list) -> str:
    lines = []
    for ev in events:
        if not isinstance(ev, dict):
            continue
        ages = [a.strip() for a in str(ev.get("ages") or "").split(",") if a.strip()]
        if ages and all(ADULT_ONLY.search(a) for a in ages):
            continue
        ages = [next((f"{a} ({hint})" for pat, hint in AGE_HINTS if pat.search(a)), a) for a in ages]
        start, end = str(ev.get("event_start") or ""), str(ev.get("event_end") or "")
        fields = [f"{start[:16]}-{end[11:16]}" if start else "", str(ev.get("title") or "").strip(),
                  f"ages: {', '.join(ages)}" if ages else "", str(ev.get("sub_title") or "").strip(),
                  str(ev.get("location") or "").strip(),
                  "registration required" if str(ev.get("allow_reg")) == "1" else "",
                  str(ev.get("url") or "").strip()]
        lines.append(" | ".join(f for f in fields if f))
    return "\n".join(lines)


def read_source(src: dict, start: date, days: int, max_chars: int, fetch=http_get) -> dict:
    url = str(src.get("url") or "").strip()
    platform = src.get("platform") or platform_of(url)
    page = {"venue": src.get("venue") or "", "url": url, "platform": platform}
    try:
        if platform == "libnet":
            data = json.loads(fetch(libnet_feed_url(url, start, days)))
            text = libnet_text(data if isinstance(data, list) else [])
        else:
            text = html_to_text(fetch(url).decode("utf-8", "replace"))
    except urllib.error.HTTPError as exc:
        return {**page, "ok": False, "error": f"HTTP {exc.code}"}
    except (urllib.error.URLError, OSError, ValueError) as exc:
        return {**page, "ok": False, "error": type(exc).__name__}
    return {**page, "ok": True, "text": trim(text, max_chars)}


def parse_sources(raw: str) -> list[dict]:
    raw = raw.strip()
    if raw.startswith("["):
        data = json.loads(raw)
        return [s if isinstance(s, dict) else {"url": str(s)} for s in data]
    return [{"url": line.strip()} for line in raw.splitlines() if line.strip()]


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument("--date", type=date.fromisoformat, default=date.today())
    parser.add_argument("--days", type=int, default=8)
    parser.add_argument("--max-chars", type=int, default=6000)
    args = parser.parse_args(argv)
    try:
        sources = parse_sources(sys.stdin.read())
    except ValueError:
        print("event-pages: stdin is neither a JSON array nor URLs", file=sys.stderr)
        return 1
    pages = [read_source(s, args.date, args.days, args.max_chars) for s in sources if s.get("url")]
    json.dump({"version": FORMAT_VERSION, "pages": pages}, sys.stdout)
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
