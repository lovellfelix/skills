# Home Assistant runbook (jarvis-home)

Canonical deploy/rollback detail lives in agentic-fleet `docs/ops/home-assistant-lxc.md`; this is the day-to-day operator view.

## Access and health

```bash
ssh root@10.0.10.44 'systemctl status jarvis-home-assistant --no-pager | head -5'
ssh root@10.0.10.44 'curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8123/manifest.json'   # 200
curl -s -o /dev/null -w "%{http_code}\n" https://ha.lovellfelix.com/manifest.json                     # via ingress
ssh root@10.0.10.44 'journalctl -u jarvis-home-assistant --since -1h -o cat | grep -E "ERROR|WARNING" | sort | uniq -c | sort -rn | head'
```

## Running the diagnostic scripts

The container has PyYAML and HA's own libraries; the host doesn't. Copy a script into `/config` under a dot-name, run it in the container, delete it:

```bash
S=~/projects/skills/portable/home-assistant-operations/scripts
scp -q $S/ha-audit.py root@10.0.10.44:/srv/home-assistant/config/.ha-audit.py
ssh root@10.0.10.44 'podman exec home-assistant python3 /config/.ha-audit.py; rm -f /srv/home-assistant/config/.ha-audit.py'
```

- `ha-audit.py [alias-substring]`: per automation: state, last triggered, refs missing from or disabled in the registry, unknown device ids.
- `ha-history.py HOURS entity_id...`: state changes with who caused them (`user` = a person via app/UI, `auto` = automation with a parent context, `device` = everything else, incl. sun/time automations).
- `ha-render.py FILE AUTOMATION_ID 'TRIGGER_JSON'`: renders automation-level and step `variables` in order with HA's engine against the latest recorded states. Upload the candidate `automations.yaml` as `/config/.automations.new.yaml` first.
- Local (Mac, `uv run --with pyyaml python`): `var-order.py`, `splice-automation.py`.

All of them open the recorder read-only (`mode=ro`). Recorder rows keep few attributes (no brightness), so prove lamp behaviour by on/off timing.

## Deploying a config change

```bash
gh repo clone lovellfelix/home-assistant-config hac && cd hac && git switch -c fix/<topic>
# edit (text edits / splice-automation.py), then:
bash .github/scripts/check-config.sh                       # pinned image, fake secrets
gh pr create ... && gh run watch <run> --exit-status        # CI runs the same check
gh pr merge <n> --squash
ssh root@10.0.10.44 'podman exec home-assistant bash /config/scripts/gitpush.sh | tail -1; \
  podman exec home-assistant sh -c "cd /config && git log --oneline -1"; \
  systemctl restart jarvis-home-assistant'
```

Then check the journal for `automation|template|could not be validated|failed to setup` since the restart. `gitpush.sh` pulls (rebase) and pushes local changes; it has a known bad conflict path (home-assistant-config #14), so look at its output.

Editing `.storage` (e.g. repointing a config entry URL): `systemctl stop jarvis-home-assistant`, copy the file to `/root/<name>.bak`, edit with Python `json` (keep 2-space indent), `chown root:root`, `chmod 600`, start.

## The unit, upgrades, provisioning

- Image digest: agentic-fleet `agent-loops/packages/home-assistant/systemd/jarvis-home-assistant.service`; the CI image pin in home-assistant-config must move with it (issue #13).
- Deploy the unit: `uv run agent-loops/bin/agent-loop.py deploy home-assistant --dry-run`, then `--apply` (enable + restart + verification; the first curl "connection refused" line is a retry, check the exit code).
- Root inside the container is required: HA sees podman's `/run/.containerenv` and installs integration requirements into the image (uid 1027 can't write there; `google_home` broke).
- `--log-driver none`: the unit's journal gets each line once.
- New CT from scratch: `jarvis/scripts/provision-home-lxc.sh plan` / `apply --approve`.

## Backups and rollback

- Built-in automatic backup: daily, 4 copies, `/config/backups` (NFS). The 3 AM automation only purges old manual backups now.
- Proxmox: CT 244 on `local-zfs`; the NFS mount is `backup=0`.
- Rollback to k8s (until the PVC is removed, gitops-homelab #5161): stop the unit, revert gitops-homelab #5156.

## Facade and tokens

- `jarvis-home-facade.service` (loopback `:8775`) needs an HA admin token in `/etc/jarvis/home-facade-ha.token`; it fails closed without one (agentic-fleet #662). Reader token: pass `agent/home-facade-reader`.
- Install config: `scp jarvis/home-facade/home-facade.jarvis-home.json root@10.0.10.44:/tmp/` then `install -m 0644 -o root -g root ... /etc/jarvis/home-facade.json`.
- Debian 13 sshd is socket-activated: no `systemctl reload ssh`; validate with `install -d /run/sshd && sshd -t`.
