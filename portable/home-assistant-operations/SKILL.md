---
name: home-assistant-operations
description: Use when operating, debugging, or changing the homelab Home Assistant (jarvis-home LXC, CT 244): writing or fixing automations and scripts, deploying config changes, checking why an automation didn't run, reading entity state or history without an API token, restarting or upgrading HA, HA backups, the Miracle home facade routines, or filing HA follow-up issues.
metadata:
  version: 0.1.0
  portable: true
  personal_machine_only: true
  tags: [homelab, home-assistant, automations, lxc, podman, troubleshooting]
---

# Home Assistant Operations (homelab)

Home Assistant runs on its own Proxmox LXC, **not** in Kubernetes (moved 2026-11-16). For the cluster side that remains (ingress, Prometheus scrape, rollback PVC) see `homelab-gitops-flux-operations`.

## Where things are

| What | Where |
| --- | --- |
| Host | `jarvis-home`, CT 244 on pve22 (`ssh root@10.0.10.22`), `ssh root@10.0.10.44` |
| Service | `jarvis-home-assistant.service`: podman, host network, image pinned by digest, root inside the container |
| Config | `/srv/home-assistant/config` on the host = `/config` in the container |
| Config repo | `lovellfelix/home-assistant-config`. **`main` is production**: HA pulls it into `/config` nightly (`scripts/gitpush.sh`) |
| Unit, provisioning, facade | `lovellfelix/agentic-fleet`: `agent-loops/packages/home-assistant`, `jarvis/scripts/provision-home-lxc.sh`, `jarvis/home-facade/`, runbook `docs/ops/home-assistant-lxc.md` |
| Remote access | `ha.<domain>` on the cluster's nginx-external ingress → Service/Endpoints to `10.0.10.44:8123` (gitops-homelab) |
| Backups | HA built-in daily backup, 4 kept, in `/config/backups` = Synology NFS bind-mounted from pve22 `/mnt/ha-bkup` |
| Logs | `journalctl -u jarvis-home-assistant` and `/config/home-assistant.log` (level **warning**; timestamps in the container `TZ`) |

## Hard rules

- Never read, print or edit `secrets.yaml` or `/etc/jarvis/home-assistant.env`; guards block it. Pass secrets with the `pass-secrets-management` scripts.
- Change config through the repo: branch → PR → CI `check_config` → merge → pull → restart (see `reference/runbook.md`). Don't hand-edit `/config` except for an emergency, then commit the same change.
- Never edit `/config/.storage/*` while HA runs. Stop the unit, copy the file aside, edit, start.
- A restart is a house event: it fires every `homeassistant: start` trigger and kills running automations (e.g. the 30-minute sunrise lamp ramp). Check `sun.sun` timing before restarting near sunrise or sunset.
- Owner decisions (re-auth, enabling integrations, behaviour changes that never ran before) go to an issue, not a silent change.

## Workflow: fix or add an automation

1. **Evidence first.** Without an API token, read state from the recorder (read-only SQLite) and the registries in `.storage`: `scripts/ha-audit.py` (per-automation last run and missing or disabled refs) and `scripts/ha-history.py` (who changed an entity, when). See `reference/runbook.md` for how to run them in the container.
2. **Check the pitfalls** in `reference/automation-pitfalls.md`; most "never runs" bugs here were one of them.
3. **Edit as text, not by re-dumping YAML.** `scripts/splice-automation.py` replaces one automation by id and leaves the rest byte-identical. Re-dumping with a YAML library re-sorts keys and breaks `variables` order.
4. **Validate three ways**:
   - `scripts/var-order.py automations.yaml` (no forward references in `variables`)
   - the repo's `.github/scripts/check-config.sh` (schema, with the pinned image)
   - `scripts/ha-render.py` in the container (renders the variables chain with HA's own template engine against live states)
5. **Ship** via PR; after merge, pull, restart, then grep the journal for `automation|template|could not be validated` errors. Prove behaviour from recorder history at the next real trigger, not from `system_log.write` info lines (they're filtered at warning level).

## Miracle routines

`script.miracle_*` in `scripts.yaml` are what the home facade lets Miracle run. Every call re-audits the script; denied: unlock, alarm disarm, cover open, camera disable, `shell_command`, `script.*`, `automation.*`, templated action names; `notify.*` only in the confirm tier except `notify.mobile_app_*`. If you remove or rename an entity, also update `scripts.yaml` and `agentic-fleet/jarvis/home-facade/home-facade.jarvis-home.json` (the status mapping), then reinstall the facade config.

## Tracking work

home-assistant-config issues: label `owner-action` for things only the owner can do, `recommendation` for proposed behaviour changes (need a yes). In agentic-fleet, gitops-homelab and miracle, owner items carry `user-input-needed` / `blocked` / `owner-verify`, which the agent issue pipeline skips.

## References

- `reference/runbook.md`: access, deploy, restart, diagnostics commands, backups, upgrade, rollback.
- `reference/automation-pitfalls.md`: the failure patterns found in the 2026-11 audit, with fixes.
- `scripts/`: the audit, history, render, variable-order and splice tools.

## Personal Machine Activation

- This is a personal-machine-only skill.
- Linked automatically when `~/.overlay/local/.enabled` is absent (no allowlist to maintain).
