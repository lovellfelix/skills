"""Render an automation's variables the way HA does, against live states. Run inside the HA container.

Usage: python3 ha-render.py AUTOMATIONS_FILE AUTOMATION_ID 'TRIGGER_JSON'
  e.g. python3 /config/.ha-render.py /config/.automations.new.yaml 1743074150045 '{"id": "sunset_trigger"}'

Renders the automation-level `variables`, then each top-level `- variables:` action step in order,
with HA's ScriptVariables/Template engine and a (not started) HomeAssistant loaded with the latest
recorder state of every entity. Prints the rendered step values or the error the automation would hit.
Repeat bodies and choose branches are not walked.
"""
import asyncio
import json
import sqlite3
import sys

import yaml
from homeassistant.core import HomeAssistant
from homeassistant.helpers.script_variables import ScriptVariables
from homeassistant.helpers.template import Template


class _Loader(yaml.SafeLoader):
    pass


for _tag in ("!secret", "!include", "!input", "!env_var"):
    _Loader.add_constructor(_tag, lambda loader, node: "x")

LATEST = ("SELECT m.entity_id, s.state FROM states_meta m JOIN states s ON s.state_id = "
          "(SELECT MAX(state_id) FROM states WHERE metadata_id = m.metadata_id)")


def _variables(hass, mapping):
    return ScriptVariables({k: Template(v, hass) if isinstance(v, str) and "{" in v else v
                            for k, v in mapping.items()})


async def main(path, aid, trigger):
    hass = HomeAssistant("/tmp")
    with open("/config/.storage/core.entity_registry") as fh:
        registry = {e["entity_id"]: e for e in json.load(fh)["data"]["entities"]}
    db = sqlite3.connect("file:/config/home-assistant_v2.db?mode=ro", uri=True)
    for eid, state in db.execute(LATEST):
        entry = registry.get(eid, {})
        name = entry.get("name") or entry.get("original_name")
        hass.states.async_set(eid, state, {"friendly_name": name} if name else {})
    with open(path) as fh:
        auto = next(a for a in yaml.load(fh, Loader=_Loader) if str(a.get("id")) == aid)
    base = {"trigger": trigger, "this": {"entity_id": "automation.x", "attributes": {}},
            "context": {"id": "render-test"}}
    try:
        values = _variables(hass, auto.get("variables", {})).async_render(hass, base)
        for step in auto.get("actions", auto.get("action", [])):
            if isinstance(step, dict) and "variables" in step:
                values = _variables(hass, step["variables"]).async_render(hass, dict(values))
        shown = {k: v for k, v in values.items()
                 if k not in base and k not in auto.get("variables", {})}
        print(aid, "OK", shown)
    except Exception as exc:  # report what the automation would raise
        print(aid, "FAIL", type(exc).__name__, str(exc)[:300])
    finally:
        await hass.async_stop(force=True)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    asyncio.run(main(sys.argv[1], sys.argv[2], json.loads(sys.argv[3])))
