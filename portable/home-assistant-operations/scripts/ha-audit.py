"""Per-automation health from /config, read-only. Run inside the HA container.

Usage: python3 ha-audit.py [ALIAS_SUBSTRING]

For each automation: entity id, state and last run (from core.restore_state), mode, and
references that are missing from or disabled in the entity registry, plus unknown device ids.
Action names (switch.turn_on, ...) are excluded from the entity check.
"""
import json
import re
import sys
from datetime import datetime, timezone

import yaml


class _Loader(yaml.SafeLoader):
    pass


for _tag in ("!secret", "!include", "!input", "!env_var", "!include_dir_merge_named"):
    _Loader.add_constructor(_tag, lambda loader, node: f"<{node.tag}>")

STORAGE = "/config/.storage/"
ENTITY_RE = re.compile(
    r"\b(?:light|switch|binary_sensor|sensor|media_player|camera|person|alarm_control_panel|fan|climate|"
    r"cover|lock|input_boolean|input_number|input_select|timer|weather|script|scene|device_tracker|button|"
    r"select|number|remote|calendar|update)\.[a-z0-9_]+\b")
ACTION_RE = re.compile(r'"(?:action|service)": "([a-z_]+\.[a-z0-9_]+)"')
DEVICE_RE = re.compile(r'"([0-9a-f]{32})"')


def load(name):
    with open(STORAGE + name) as fh:
        return json.load(fh)["data"]


def main():
    only = sys.argv[1].lower() if len(sys.argv) > 1 else None
    with open("/config/automations.yaml") as fh:
        autos = yaml.load(fh, Loader=_Loader) or []
    entities = load("core.entity_registry")["entities"]
    registry = {e["entity_id"]: e for e in entities}
    registry_ids = {e["id"] for e in entities}
    devices = {d["id"] for d in load("core.device_registry")["devices"]}
    restore = {r["state"]["entity_id"]: r["state"] for r in load("core.restore_state")}
    by_unique = {e["unique_id"]: e["entity_id"] for e in entities if e["platform"] == "automation"}
    now = datetime.now(timezone.utc)

    for auto in autos:
        alias = auto.get("alias", "?")
        if only and only not in alias.lower():
            continue
        blob = json.dumps(auto)
        eid = by_unique.get(str(auto.get("id")))
        reg = registry.get(eid, {})
        state = restore.get(eid, {})
        last = (state.get("attributes") or {}).get("last_triggered")
        age = f"{(now - datetime.fromisoformat(last)).days}d ago" if last else "never"
        disabled = f" DISABLED_BY={reg['disabled_by']}" if reg.get("disabled_by") else ""
        print(f"### {alias}  [{eid} state={state.get('state')} last={age} "
              f"mode={auto.get('mode', 'single')}{disabled}]")
        actions = set(ACTION_RE.findall(blob))
        problems = []
        for ref in sorted(set(ENTITY_RE.findall(blob)) - actions):
            entry = registry.get(ref)
            if entry is None:
                problems.append(f"{ref}=NOT_IN_REGISTRY")
            elif entry.get("disabled_by"):
                problems.append(f"{ref}=DISABLED({entry['disabled_by']})")
        for dev in sorted(set(DEVICE_RE.findall(blob))):
            if dev not in devices and dev not in registry_ids:
                problems.append(f"id:{dev[:8]}=UNKNOWN")
        if problems:
            print("  PROBLEMS:", ", ".join(problems))


if __name__ == "__main__":
    main()
