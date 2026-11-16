"""Offline tests for portable/location-search/scripts/event-sources.py and
event-pages.py. No network: every fetch is a fake.

    python3 -m unittest hacks/tests/test_location_event_sources.py
"""
import importlib.util
import json
import unittest
import urllib.error
from datetime import date
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parents[2] / "portable/location-search/scripts"


def _load(name):
    spec = importlib.util.spec_from_file_location(name.replace("-", "_"), SCRIPTS / f"{name}.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


sources = _load("event-sources")
pages = _load("event-pages")

OVERPASS = {"elements": [
    {"type": "way", "center": {"lat": 33.04, "lon": -97.02},
     "tags": {"amenity": "library", "name": "Town Library", "website": "https://lib.example/"}},
    {"type": "node", "lat": 33.03, "lon": -97.07,
     "tags": {"amenity": "library", "name": "Branch Library", "website": "https://branch.libnet.info/"}},
    {"type": "node", "lat": 33.10, "lon": -97.30,
     "tags": {"tourism": "museum", "name": "Far Museum", "website": "museum.example"}},
    {"type": "node", "lat": 33.04, "lon": -97.02,
     "tags": {"amenity": "library", "name": "Duplicate", "website": "https://lib.example"}},
    {"type": "node", "lat": 33.05, "lon": -97.05, "tags": {"amenity": "library", "name": "No site"}},
    {"type": "node", "lat": 33.05, "lon": -97.05, "tags": {"tourism": "zoo", "name": "Blocked Zoo",
                                                          "website": "https://zoo.example"}},
]}

TOWN_HTML = """<html><body><nav><a href="/about">About</a><a href="/rentals/events-room">Rent
the events room</a></nav><a href="/kids">Kids</a> <a href="/calendar.aspx?CID=26">View All Events</a>
<a href="/Calendar.aspx?EID=4490">Pajama Storytime</a><a href="https://facebook.com/events">FB</a>
<a href="https://other.example/events">Other site</a></body></html>"""
MUSEUM_HTML = '<a href="/visit">Visit</a><a href="/whats-on/events/">Events</a>'


class FakeWeb:
    def __init__(self):
        self.calls = []

    def __call__(self, url, ua=None, timeout=20, data=None):
        self.calls.append(url)
        if "interpreter" in url:
            return json.dumps(OVERPASS).encode()
        if url.startswith("https://lib.example"):
            return TOWN_HTML.encode()
        if url.startswith("https://museum.example"):
            return MUSEUM_HTML.encode()
        if url.startswith("https://zoo.example"):
            raise urllib.error.HTTPError(url, 403, "Forbidden", {}, None)
        raise AssertionError(f"unexpected fetch {url}")


class EventSourcesTest(unittest.TestCase):
    def test_venues_nearest_first_deduped_named_with_site(self):
        venues = sources.venues_from_overpass(OVERPASS, 33.04, -97.03)
        self.assertEqual([v["venue"] for v in venues],
                         ["Town Library", "Blocked Zoo", "Branch Library", "Far Museum"])
        self.assertEqual(venues[-1]["website"], "https://museum.example")

    def test_event_links_prefer_calendars_and_skip_noise(self):
        links = sources.event_links(TOWN_HTML, "https://lib.example/", limit=5)
        self.assertEqual(links, ["https://lib.example/calendar.aspx?CID=26"])

    def test_platforms(self):
        self.assertEqual(sources.platform_of("https://x.libnet.info/event/1"), "libnet")
        self.assertEqual(sources.platform_of("https://city.example/Calendar.aspx?CID=3"), "civicplus")
        self.assertEqual(sources.platform_of("https://museum.example/events"), "html")
        self.assertEqual(sources.normalize_source("https://x.libnet.info/event/123"),
                         "https://x.libnet.info/events")

    def test_discover(self):
        web = FakeWeb()
        out = sources.discover(33.04, -97.03, 20000, 10, fetch=web)
        self.assertEqual(out["version"], 1)
        self.assertEqual([(s["venue"], s["platform"], s["url"]) for s in out["sources"]], [
            ("Town Library", "civicplus", "https://lib.example/calendar.aspx?CID=26"),
            ("Branch Library", "libnet", "https://branch.libnet.info/events"),
            ("Far Museum", "html", "https://museum.example/whats-on/events/"),
        ])
        self.assertEqual(out["skipped"], [{"venue": "Blocked Zoo", "reason": "website returned HTTP 403"}])
        self.assertNotIn("https://branch.libnet.info/", web.calls)  # platform known: no page read

    def test_overpass_falls_back_to_mirror(self):
        calls = []

        def flaky(url, ua=None, timeout=20, data=None):
            calls.append(url)
            if url == sources.OVERPASS_URLS[0]:
                raise urllib.error.HTTPError(url, 502, "Bad Gateway", {}, None)
            return b'{"elements": []}'

        self.assertEqual(sources.query_overpass("q", fetch=flaky), {"elements": []})
        self.assertEqual(calls, list(sources.OVERPASS_URLS))

    def test_zip_validation(self):
        with self.assertRaises(ValueError):
            sources.zip_to_coords("75O77")


LIBNET = [
    {"title": "Preschool Storytime", "sub_title": "ages 3-5", "event_start": "2026-11-16 11:00:00",
     "event_end": "2026-11-16 11:30:00", "ages": "Preschool", "location": "Branch Library",
     "allow_reg": "0", "url": "https://branch.libnet.info/event/1"},
    {"title": "Book Club", "event_start": "2026-11-16 18:00:00", "event_end": "2026-11-16 19:00:00",
     "ages": "Adults", "location": "Branch Library"},
    {"title": "Armchair Travel", "event_start": "2026-11-16 19:00:00", "event_end": "2026-11-16 20:00:00",
     "ages": "Teens, Teen and Adult, Adult", "location": "Branch Library"},
    {"title": "Family LEGO", "event_start": "2026-11-17 16:00:00", "event_end": "2026-11-17 17:00:00",
     "ages": "Adults, Elementary School", "allow_reg": "1", "url": "https://branch.libnet.info/event/2"},
]


class EventPagesTest(unittest.TestCase):
    def test_html_to_text_drops_scripts_styles_and_markup(self):
        html = ("<html><head><title>T</title><style>\n.a{color:red}\n</style></head><body>"
                "<script>\nvar x=1;\n</script><p>Storytime</p><div>Tue&nbsp;10am</div></body></html>")
        self.assertEqual(pages.html_to_text(html), "Storytime\nTue 10am")

    def test_libnet_feed_lines_without_adult_only_events(self):
        text = pages.libnet_text(LIBNET)
        self.assertEqual(text.splitlines(), [
            "2026-11-16 11:00-11:30 | Preschool Storytime | ages: Preschool | ages 3-5 | Branch Library"
            " | https://branch.libnet.info/event/1",
            "2026-11-17 16:00-17:00 | Family LEGO | ages: Adults, Elementary School (about 5-11 years)"
            " | registration required | https://branch.libnet.info/event/2",
        ])

    def test_libnet_feed_url(self):
        url = pages.libnet_feed_url("https://branch.libnet.info/events", date(2026, 11, 16), 8)
        self.assertTrue(url.startswith("https://branch.libnet.info/eeventcaldata?event_type=0&req="))
        self.assertIn("%222026-11-16%22", url)

    def test_trim_starts_near_the_first_date(self):
        text = "Menu " * 400 + "Nov 18 Storytime 10am " + "x" * 50
        out = pages.trim(text, 300)
        self.assertIn("Nov 18 Storytime", out)
        self.assertEqual(pages.trim("short", 300), "short")

    def test_read_source_by_platform_and_failures(self):
        def fetch(url, timeout=20):
            if "eeventcaldata" in url:
                return json.dumps(LIBNET).encode()
            if "blocked" in url:
                raise urllib.error.HTTPError(url, 403, "Forbidden", {}, None)
            return b"<p>Nov 20 Family Day</p>"

        start = date(2026, 11, 16)
        lib = pages.read_source({"url": "https://branch.libnet.info/events", "venue": "B"}, start, 8, 6000, fetch)
        self.assertTrue(lib["ok"] and lib["platform"] == "libnet" and "Preschool Storytime" in lib["text"])
        html = pages.read_source({"url": "https://museum.example/events"}, start, 8, 6000, fetch)
        self.assertEqual((html["ok"], html["text"]), (True, "Nov 20 Family Day"))
        bad = pages.read_source({"url": "https://blocked.example/"}, start, 8, 6000, fetch)
        self.assertEqual((bad["ok"], bad["error"]), (False, "HTTP 403"))

    def test_parse_sources(self):
        self.assertEqual(pages.parse_sources('[{"url": "https://a"}, "https://b"]'),
                         [{"url": "https://a"}, {"url": "https://b"}])
        self.assertEqual(pages.parse_sources("https://a\n\nhttps://b\n"),
                         [{"url": "https://a"}, {"url": "https://b"}])


if __name__ == "__main__":
    unittest.main()
