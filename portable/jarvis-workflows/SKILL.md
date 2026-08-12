---
name: jarvis-workflows
description: Use when operating or coordinating the Jarvis fleet across the Mac orchestrator, remote Jarvis hosts, managed agents, or the jarvis-claude worker and you need the correct transport, queue, scheduler, or off-LAN access path.
metadata:
  version: 0.1.0
  portable: true
  tags:
    [
      jarvis,
      fleet,
      managed-agents,
      claude-worker,
      delegation,
      workflow,
      tailscale,
    ]
---

# Jarvis Workflows

Use one operating model for Jarvis work regardless of harness. The goal is to choose the right Jarvis execution surface first, then use the deterministic transport or access path for that surface.

## Use when

- Work involves the Jarvis fleet rather than only the current machine.
- You need to decide between local execution, A2A, managed agents, or the Claude worker.
- You need off-LAN operator access to the fleet.
- The task should survive the current harness or session.
- You need deterministic enqueue, replay, scheduling, or result lookup.

## Do not use when

- The work should be executed immediately in the current harness with no Jarvis routing.
- The task text contains secrets or untrusted external input.

## Authoritative files

- Fleet registry: `jarvis/schedules.json`
- Claude worker helper: `jarvis/scripts/claude-task.sh`
- Fleet board: `jarvis/scripts/fleet-status.sh`
- Fleet bootstrap entrypoint: `jarvis/scripts/bootstrap-fleet.sh`
- Tailscale rollout helper: `jarvis/scripts/fleet-tailscale.sh`
- Managed-agent seed: `jarvis/managed-agents.template.json`
- Managed-agent reconciler: `jarvis/scripts/sync-managed-agents.py`
- Tailscale runbook: `docs/ops/tailscale-runbook.md`

Read `jarvis/schedules.json` first when the question is about what exists, what runs where, or what should own recurring work.

## Choose the execution surface

| Need                                                                        | Surface                        | Canonical path                                            |
| --------------------------------------------------------------------------- | ------------------------------ | --------------------------------------------------------- |
| Immediate work on this machine                                              | Local Jarvis / current harness | execute inline                                            |
| One-off remote Jarvis question or action on `jarvis-infra` / `jarvis-synth` | A2A request                    | remote `:8010/a2a/tasks`                                  |
| Recurring remote operational job                                            | Managed agent                  | `managed-agents.template.json` + `sync-managed-agents.py` |
| Long-running planning, analysis, or detached Claude reasoning               | `jarvis-claude` worker         | `claude-task.sh` / `claude-tasks` queue                   |
| Off-LAN SSH or service reachability to the fleet                            | Tailscale access plane         | `bootstrap-fleet.sh tailscale` + `tailscale-runbook.md`   |

## Routing decision table

Use this table before choosing a Jarvis path.

| Situation                                                                                   | Use                                  | Why                                                              |
| ------------------------------------------------------------------------------------------- | ------------------------------------ | ---------------------------------------------------------------- |
| Private/local-only data, current machine context, or immediate operator work                | local Jarvis / current harness       | avoids unnecessary fleet hops                                    |
| Quick one-off check on `jarvis-infra` or `jarvis-synth`                                     | A2A                                  | direct remote execution without creating durable scheduler state |
| Repeating remote maintenance or monitoring                                                  | managed agent                        | gives schedule, drift control, and fleet visibility              |
| Detached repo planning, bounded analysis, or long-running reasoning                         | `jarvis-claude` queue                | durable queue plus asynchronous result pickup                    |
| Off-LAN operator access to `jarvis-hub`, `jarvis-infra`, `jarvis-synth`, or `jarvis-claude` | Tailscale                            | preserves LAN defaults while adding a second management plane    |
| "What is scheduled, live, or already running?"                                              | `fleet-status.sh` + `schedules.json` | avoids guessing                                                  |

## Core rules

1. Do not treat `jarvis-claude` like a normal A2A managed agent.
2. Do not create recurring work ad hoc; put it in `jarvis/schedules.json` and reconcile the managed-agent seed.
3. For Claude worker delegation, do not invent harness-specific transports when the queue helper is available.
4. Check the fleet board before claiming what is scheduled or live.
5. Treat Tailscale as an operator access path, not as a replacement for the current LAN hostnames or in-fleet routing.

## Bootstrap quick start

Use this sequence when standing up a new Mac or refreshing fleet access:

1. Local bootstrap: `bash ~/.dotfiles/hacks/bootstrap.sh`
2. Register Mac-to-fleet connectivity if needed: `bash ${AGENTIC_FLEET_ROOT:-~/projects/agentic-fleet}/jarvis/scripts/bootstrap-fleet.sh mac --register`
3. For off-LAN remote access, enroll the fleet in Tailscale:

```bash
TAILSCALE_AUTH_KEY=tskey-... \
  bash ${AGENTIC_FLEET_ROOT:-~/projects/agentic-fleet}/jarvis/scripts/bootstrap-fleet.sh tailscale --apply 245 246 247 248
```

4. Verify access:

```bash
tailscale status
tailscale ssh dev@jarvis-infra 'hostname && systemctl is-active tailscaled'
```

`hacks/bootstrap.sh` can run step 3 automatically only when `BOOTSTRAP_JARVIS_TAILSCALE=true` and `TAILSCALE_AUTH_KEY` are set in the environment.

## Drift reconciliation policy

Treat the Jarvis control files and live state as distinct layers with clear roles:

| Layer                                 | Role                          | Rule                                                                                  |
| ------------------------------------- | ----------------------------- | ------------------------------------------------------------------------------------- |
| `jarvis/schedules.json`               | intent and ownership registry | source of truth for which host should own recurring work                              |
| `jarvis/managed-agents.template.json` | managed-agent projection      | source of truth for the subset of recurring jobs implemented as remote managed agents |
| live `/v1/managed-agents` state       | runtime reality               | must converge to the template after sync                                              |

Apply this order when reconciling drift:

1. Fix `schedules.json` if ownership or cadence is wrong.
2. Fix `managed-agents.template.json` if the managed-agent projection is wrong or incomplete.
3. Run `sync-managed-agents.py` to converge live state.
4. Use `fleet-status.sh` and `check-proxmox-agents.sh` to verify the result.

Do not patch live managed agents by hand first and then treat that as the new source of truth.

## Managed-agent workflow

Use this for recurring remote work on `jarvis-infra` or `jarvis-synth`.

1. Update `jarvis/schedules.json` if ownership or cadence changes.
2. Update `jarvis/managed-agents.template.json` to match the intended remote agents.
3. Dry-run reconciliation:

```bash
python3 ${AGENTIC_FLEET_ROOT:-~/projects/agentic-fleet}/jarvis/scripts/sync-managed-agents.py
```

4. Apply when ready:

```bash
python3 ${AGENTIC_FLEET_ROOT:-~/projects/agentic-fleet}/jarvis/scripts/sync-managed-agents.py --apply --prune
```

5. Validate fleet health:

```bash
bash ${AGENTIC_FLEET_ROOT:-~/projects/agentic-fleet}/jarvis/scripts/check-proxmox-agents.sh
bash ${AGENTIC_FLEET_ROOT:-~/projects/agentic-fleet}/jarvis/scripts/fleet-status.sh
```

## Claude worker delegation

Use this for detached planning or analysis that should run on `jarvis-claude` and return through the hub queue.

For Jarvis Claude worker delegation, the canonical transport is the lean-ctx hub knowledge queue:

- pending queue: `claude-tasks`
- results queue: `claude-results`
- preferred helper: `jarvis/scripts/claude-task.sh`

## Deterministic task contract

Every queued task should include all of these in the prompt text:

1. Objective: one sentence
2. Scope: repo, host, or target system
3. Constraints: what not to do
4. Output format: exact expected shape
5. Done condition: how completion is judged

Use a stable key when the task may be retried or inspected later.

Good key patterns:

- `repo-plan-20260623-dotfiles`
- `incident-20260623-flux-check`
- `handoff-auth-refactor-01`

## Preferred enqueue path

From any harness with shell access, prefer the helper:

```bash
bash ${AGENTIC_FLEET_ROOT:-~/projects/agentic-fleet}/jarvis/scripts/claude-task.sh add --key <task-id> "<prompt>"
```

Inspect state with:

```bash
bash ${AGENTIC_FLEET_ROOT:-~/projects/agentic-fleet}/jarvis/scripts/claude-task.sh list
bash ${AGENTIC_FLEET_ROOT:-~/projects/agentic-fleet}/jarvis/scripts/claude-task.sh results
```

Remove a stuck queued item with:

```bash
bash ${AGENTIC_FLEET_ROOT:-~/projects/agentic-fleet}/jarvis/scripts/claude-task.sh rm <task-id>
```

## Fallback enqueue path

If the helper is unavailable but the harness can call lean-ctx tools directly, enqueue with `ctx_knowledge remember`:

```text
category = claude-tasks
key      = <task-id>
value    = <full prompt text>
```

Read results from `claude-results` with the same key.

## Prompt template

```text
Objective: <single outcome>

Context:
- Target: <repo/host/system>
- Why now: <reason>

Constraints:
- <constraint 1>
- <constraint 2>

Deliverable:
- <exact output shape>

Done when:
- <completion test>
```

## Common task shapes

### Planning

Use for bounded repo or system planning on `jarvis-claude`:

```text
Objective: Produce one implementation plan for <target>.
Context:
- Target: <repo or system>
- Why now: need a queueable plan from jarvis-claude.
Constraints:
- Do not write code.
- Keep to at most 5 actionable tasks.
Deliverable:
- GitHub-flavored Markdown plan with likely files, validation, and dependency notes.
Done when:
- The plan is concrete enough that another agent can execute it without rediscovery.
```

### Investigation

```text
Objective: Investigate <issue> and summarize the most likely cause.
Context:
- Target: <service/repo/host>
- Why now: detached analysis is acceptable.
Constraints:
- Read-only analysis only.
- Call out uncertainty explicitly.
Deliverable:
- Short diagnosis with evidence, risks, and next steps.
Done when:
- A human can decide the next action from the summary alone.
```

## Safety checks

- Never queue secrets, tokens, or private raw data that should not leave the current machine.
- Never assume immediate execution; the worker polls on an interval.
- Treat queue text as executable instructions for Claude. Keep it explicit and bounded.
- If the task must be idempotent, say so in the prompt.

## Verification

### For managed agents

1. Confirm the intended job exists in `jarvis/schedules.json`.
2. Confirm the live host inventory matches the seed with `sync-managed-agents.py` dry-run.
3. Confirm health with `check-proxmox-agents.sh`.

### For Tailscale access

1. Confirm the node is visible in `tailscale status`.
2. Confirm remote shell access with `tailscale ssh`.
3. Fall back to the LAN or Proxmox `pct exec` path if Tailscale is degraded.

### For Claude worker tasks

After enqueue:

1. Confirm the task appears in `claude-task.sh list`.
2. Later, confirm a matching result appears in `claude-task.sh results`.
3. If no result appears, check whether the worker is disabled or proxy/auth is broken before re-enqueueing.

## Failure triage

Use this first-pass table before deeper debugging.

| Symptom                                             | Most likely cause                                | First check                                                                    |
| --------------------------------------------------- | ------------------------------------------------ | ------------------------------------------------------------------------------ |
| A2A request returns 401 or unauthorized             | wrong A2A token                                  | validate `JARVIS_A2A_AUTH_TOKEN` source and rerun `check-proxmox-agents.sh`    |
| `/v1/managed-agents` returns 401 or invalid API key | wrong `OPENJARVIS_API_KEY`                       | inspect remote `jarvis.service` env and rerun `check-proxmox-agents.sh`        |
| Claude task stays pending                           | worker disabled or cannot reach hub              | check `CLAUDE_WORKER_ENABLED`, worker timer/service, and hub token             |
| Claude task retries and never completes             | Claude auth/proxy path broken                    | inspect `jarvis-claude` worker logs and current Claude/proxy env               |
| Dry-run sync keeps showing UPDATE                   | live config drift (model, instruction, schedule) | compare template vs live `/v1/managed-agents` JSON                             |
| Dry-run sync shows EXTRA                            | stale live managed agent                         | rerun with `--apply --prune` after confirming template intent                  |
| Fleet board disagrees with expected jobs            | registry/template/live mismatch                  | reconcile in the order defined in Drift reconciliation policy                  |
| Managed agents sit in `error`                       | stale model or broken remote command path        | inspect live config, model name, and recent summary/error fields               |
| Off-LAN SSH fails but LAN access still works        | Tailscale enrollment or policy issue             | check `tailscale status`, `tailscale ip -4`, and `systemctl status tailscaled` |

## Red flags

- Using ad hoc harness-native task APIs for the same Jarvis Claude worker.
- Queueing vague prompts without done criteria.
- Re-enqueueing with a new random key when the original task is still pending.
- Treating `jarvis-claude` like a normal A2A managed agent.
- Creating recurring remote jobs without updating the registry and managed-agent seed.

## Backlog

High-value follow-ups for this skill:

- Add canonical task templates for A2A asks, managed-agent instructions, and Claude worker planning/investigation tasks.
- Add result-handling rules per execution surface so post-run behavior is standardized.
- Add deterministic naming conventions for queue task IDs, managed-agent names, and ledger/report job IDs.
- Add lightweight state-machine diagrams for A2A, managed agents, and Claude queue flows.
- Add stronger guardrails around locality classes (`local-only`, `private-ok`, `cloud-ok`).
- Add a concise operational command quick reference for the most common Jarvis workflows.
- Add worked end-to-end examples for recurring jobs, detached planning, and one-off remote asks.
