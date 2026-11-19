# Automation pitfalls (found in the 2026-11 audit)

Each of these silently stopped real automations. Check new and changed automations against all of them.

## 1. `variables` forward references (file re-sorted)

HA renders a `variables:` mapping top to bottom. At some point `automations.yaml` was rewritten with alphabetically sorted keys, so `step_interval: '{{ transition_minutes * 60 / steps }}'` rendered before `steps` existed: `UndefinedError` at trigger time, before `last_triggered` is set. The automation looks enabled and simply never runs (236 days for the sunrise lamps).

- Fix: put a value that depends on another in a **later `- variables:` action step**. List order survives any re-sort; key order doesn't.
- Detect: `scripts/var-order.py automations.yaml scripts.yaml`.
- Never re-dump the file with a YAML library (default `sort_keys=True`); edit as text (`scripts/splice-automation.py`).

## 2. Single-brace "templates"

`value_template: '{ states("x") not in [...] }'` is a literal string, not a template, and a template condition on it is always false. Use `{{ }}`, or better a `numeric_state` / `state` condition.

## 3. `to: 'on'` also fires on `unavailable -> on`

A state trigger with only `to:` fires when an entity reconnects. The Android TV Remote entity drops to `unavailable` for ~200 ms when an app is launched, so a "TV turned on → launch app" automation re-triggered itself 17,235 times in 48 minutes. For "Disarm alarm when the kitchen light turns on", a Wi-Fi switch reconnect would have disarmed the alarm.

- Fix: `from: 'off'` + `to: 'on'` on any trigger that acts; for app launches also a once-per-day guard (`this.attributes.last_triggered` date) and `mode: single`.

## 4. "Changed by an automation" can't be detected from the parent context

Sun- and time-triggered automations run with no `context.parent_id`, so their changes look like a physical button press. The reliable signal is the opposite: `context.user_id` is set only when a **person** acts through the app or UI.

- e.g. "turn the lamps off unless someone turned them on": `selectattr('context.user_id', 'eq', none)`.

## 5. Entities, devices and helpers that don't exist

- Device triggers reference **entity registry ids** (32-hex); they break when an entity is re-created ("Unknown device", automation disabled at setup). Prefer `trigger: state` on the entity id.
- `area_id` targets with deleted areas, `light.*` groups that became `switch.*` plugs, `timer.*` / `input_boolean.*` helpers that were never defined. The audit script lists refs missing from the registry.
- A plug is `switch.turn_on`, not `light.turn_on` with `brightness_pct`.

## 6. Wrong entity model or units

- `androidtv_remote` media players report `on`/`off`, never `playing`.
- Cast entities for Google TV may not support `volume_set`: check before calling (it errors every run).
- Unit system is US customary: temperatures are °F (the NAS alert compared 111 °F to a threshold of 50).

## 7. Invalid step syntax

`- action: delay` with `delay: 00:05:00` is invalid (the automation is rejected and disabled). It's `- delay: '00:05:00'`. `check_config` reports these.

## 8. Things that look like errors but aren't

- `system_log.write` at `info` never reaches the log (default level warning): verify from recorder history.
- Log timestamps are in the container `TZ`, HA's own time zone (America/Chicago) may differ; recorder times are UTC.
- `check_config` on 2026.4.1 needs the repo's wrapper (`.github/scripts/check_config_wrapper.py`), or every automation fails with `KeyError: 'triggers'`.

## 9. Restarts are automation triggers

`systemctl restart jarvis-home-assistant` fires `homeassistant: start` triggers. The front-door "recovery after restart at night" branch used to re-light the porch at 02:00 after Goodnight turned it off. Restarts also cancel running automations (a sunrise ramp mid-way). Schedule restarts away from sunrise/sunset and check what `start` triggers exist.
