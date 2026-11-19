"""State-change history from the recorder, read-only. Run inside the HA container.

Usage: python3 ha-history.py HOURS ENTITY_ID [ENTITY_ID ...]

Prints each state change (UTC) with who caused it:
  user   - a person via the app/UI (context user id set)
  auto   - an automation/script run with a parent context (state/event-triggered)
  device - anything else: the device itself, or a sun/time-triggered automation
"""
import sqlite3
import sys
import time

QUERY = """
SELECT datetime(s.last_updated_ts, 'unixepoch'), s.state,
       s.context_parent_id_bin IS NOT NULL, s.context_user_id_bin IS NOT NULL
FROM states s JOIN states_meta m ON m.metadata_id = s.metadata_id
WHERE m.entity_id = ? AND s.last_updated_ts > ?
ORDER BY s.state_id
"""


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    db = sqlite3.connect("file:/config/home-assistant_v2.db?mode=ro", uri=True)
    since = time.time() - float(sys.argv[1]) * 3600
    for eid in sys.argv[2:]:
        out, prev = [], None
        for ts, state, by_auto, by_user in db.execute(QUERY, (eid, since)):
            if state != prev:
                who = "user" if by_user else ("auto" if by_auto else "device")
                out.append(f"{ts[5:16]}={state}({who})")
            prev = state
        print(f"{eid}: {' '.join(out[-40:]) or '(no changes in window)'}")


if __name__ == "__main__":
    main()
