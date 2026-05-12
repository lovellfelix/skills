---
name: ucm-test
description: "Use when testing UCM module changes against remote hosts using the ucm test CLI for hiera, puppet, module code, package management, or catalog convergence validation."
metadata:
  version: 0.3.0
  portable: true
  tags: [ucm, puppet, hiera, linkedin, infrastructure, work]
---

# UCM Test — Remote Host Validation via the UCM CLI

One-line summary: Test and apply UCM Puppet/Hiera changes against a remote host to validate catalog convergence before merging to production.

## Work Machine Activation

- This is a work-machine-only skill.
- It is linked only when the local work-machine flag file exists: `~/.work-env-skills`.
- Override the flag path with: `SKILL_WORK_MACHINE_FLAG_FILE=/path/to/flag`.

## Subcommands: pick the right one

`ucm test` has two subcommands. Pick based on **what you changed**:

| Subcommand | Use when you changed... | Symlinks |
|-----------|--------------------------|----------|
| `ucm test hiera`  | YAML under a module's hieradata repo | hiera dir → puppet hiera path |
| `ucm test module` | Puppet manifests, templates, lib, files inside the module repo | module dir → puppet module path |

`ucm test module` is the right tool for changes to `manifests/*.pp`, `templates/`, `lib/facter/`, `lib/puppet/`, or `files/`. `ucm test hiera` is for data-only changes.

You can combine module + hiera in one `ucm test module` invocation via `--hiera-path`.

## `ucm test hiera` — data changes

```bash
ucm test hiera \
  --name <module-name> \
  <hostname> \
  --hiera-path <path-to-module-hiera-dir> \
  [--install] \
  [--apply]
```

| Flag | Purpose |
|------|---------|
| `--name` | The Puppet module name (e.g. `coreucm`) |
| `--hiera-path` | Path to the local Hiera data directory for the module |
| `--install` | Symlink the local Hiera data onto the remote host |
| `--apply` | Run `puppet apply` on the remote host after installing |

### Example

```bash
ucm test hiera --name coreucm lor1-0004429.int.linkedin.com \
  --hiera-path ~/workspace/ucm/hiera-repos/ucm-hieradata-pie-modules/modules/coreucm \
  --install --apply
```

> **Note:** The `--hiera-path` must end in the module name (e.g. `.../coreucm`). If it doesn't, the tool will warn but proceed.

## `ucm test module` — module code changes

```bash
ucm test module <hostname> \
  [--name <module-name>] \
  [--module-path <path-to-module-root>] \
  [--hiera-path <path-to-hiera-dir>] \
  [--install] [--apply] \
  [--pause-agent [--pause-agent-duration <dur>]] \
  [--puppet-debug] \
  [--dry-run | --remote-dry-run] \
  [--cleanup]
```

Defaults: if run from inside the module repo, `--name` is guessed from the directory and `--module-path` defaults to cwd. Otherwise pass both explicitly.

| Flag | Purpose |
|------|---------|
| `--name` | Module name (auto-guessed from cwd if omitted) |
| `--module-path` | Path to the module root (the dir containing `manifests/`, `templates/`, etc.) |
| `--hiera-path` | Optional: also symlink this hiera dir alongside the module |
| `--install` | Create symlinks on the remote host so `puppet apply` picks up your copy |
| `--apply` | Run `puppet apply` after installing |
| `--pause-agent` | Attempt to pause `ucm-agent` for the duration of the test |
| `--pause-agent-duration` | Pause length (e.g. `1h`, `30m`) |
| `--puppet-debug` | Adds `--debug` to puppet apply (verbose) |
| `--dry-run` | Print what would happen locally — does not contact the host |
| `--remote-dry-run` | Copies the module but skips install/apply on the remote |
| `--cleanup` | Remove the test module dir and re-run ucm-agent to restore production state |

### Typical flow

```bash
# From inside the module repo
cd ~/workspace/.../ucm-pie-core-sysctl
ucm test module ltx1-app3383.stg.linkedin.com \
  --name coresysctl \
  --module-path "$PWD/coresysctl" \
  --install --apply
```

Output lines to read:
- `Notice: /Stage[main]/<Class>/<Resource>/ensure: defined content as '{sha256}...'` — file created
- `Notice: /Stage[main]/<Class>/<Resource>/ensure: removed` — file removed (e.g. via `purge => true`)
- `Notice: /Stage[main]/<Class>/Exec[...]: Triggered 'refresh' from N events` — a notify edge fired. `N > 1` means multiple upstream resources notified the same exec in one run; this is expected and idempotent (refreshonly execs collapse to one run).
- `Notice: Applied catalog in Xs` with no other notices → steady state (idempotent)

### Combining module + hiera in one apply (`--hiera-path`)

Use `--hiera-path` when the change spans both module code and hiera data, or to test hiera changes against an in-flight module branch. Important rules:

- The hiera path you pass **replaces** the production hiera dir for that module via symlinks. Anything missing from your copy will not be merged in.
- Best practice: copy the **entire** production hiera dir to a workspace location, edit the file(s) you need to test, point `--hiera-path` at the copy. Don't pass a hand-built minimal hiera dir unless you intend to override everything.
- `ucm test module` invokes `ucm-hiera-retrieve --now` after symlinking and prints one `Symlinked …` line per file. Production runs have hundreds of these — pipe through `grep -v "^Symlinked"` to find the apply notices.
- `--hiera-path` works in both `ucm test module` and `ucm test hiera`. For pure data changes, `ucm test hiera` is lighter (skips module rsync).

Example: validate that adding a hiera sysctl_d entry creates the file and fires reload.

```bash
cp -r ~/workspace/ucm/hiera-repos/ucm-hieradata-pie-modules/modules/coresysctl /tmp/test-hiera/coresysctl
# edit /tmp/test-hiera/coresysctl/common/default.yaml — append the new entry
ucm test module <host> --name coresysctl \
  --module-path "$PWD/coresysctl" \
  --hiera-path /tmp/test-hiera/coresysctl \
  --install --apply
```

Expect: `…/File[<new-file>]/ensure: defined content as '{sha256}…'` and `Exec[reload_sysctl]: Triggered 'refresh' from N events`.

### Don't pipe `ucm test module` through `head` (or anything that closes the pipe)

Piping the apply output through `head`/`less -F` etc. **kills the remote ssh mid-apply** via SIGPIPE. The remote puppet run is terminated partway through, leaving the host in an inconsistent state and you see a truncated log with no apply notices.

Always redirect to a file and grep afterwards:

```bash
ucm test module <host> --name <mod> --module-path "$PWD/<mod>" --install --apply > /tmp/run.log 2>&1
grep -v "^Symlinked" /tmp/run.log | sed 's/\x1b\[[0-9;]*m//g' | grep -E "Notice|Error|Triggered"
```

The `sed` strips ANSI color codes; the puppet output is heavily colorized and plain `grep` for `Notice:` sometimes misses lines starting with `\x1b[m`.

### Catalog converged → no notices on re-apply (this is correct, but a gotcha)

After a successful apply, the next `--apply` produces only `Compiled catalog…` + `Applied catalog…` with no resource lines. If you're re-running to **capture** evidence of a create/change/reload notice you missed (e.g. from a truncated log), perturb on-host first (`ssh <host> "sudo rm /etc/sysctl.d/<file>"`) then re-apply. Otherwise Puppet correctly does nothing and there's nothing to log.

### Pause/unpause caveats

- `--pause-agent` printed a "ucm-agent is currently running on this host" notice and **did not actually pause** in observed runs. If you need a real pause, ssh to the host and run `sudo ucm pause --duration 30m --reason '<ticket>'` before testing.
- During a real pause, you may still see `ucm-agent lock exists, waiting for it to finish... (60s remaining)` if an agent run was in flight when you started — that's the in-flight run completing, not a fresh one.
- `--cleanup` runs `ucm-agent --now` which restores the production module state; the post-cleanup agent run effectively un-pauses.

### Cleanup is interactive — auto-answer it

`ucm test module --cleanup` prompts `Remove directory? [y/N]:` (one prompt for module, one for hiera if you used `--hiera-path`) and `Aborted!` if no TTY is attached. Pipe `yes`:

```bash
yes y | ucm test module <hostname> --name <module> --cleanup
```

Without that, the cleanup exits with code 2 and leaves the test dirs on the host.

### Validating notify/refresh graphs

To prove that a `notify` edge (`~>`, `notify =>`) fires only when intended:

1. **Steady state**: run `--apply`; expect `Applied catalog in Xs` with **no** `Triggered 'refresh'` lines.
2. **Trigger path — add/change**: introduce a hiera entry (with `--hiera-path` pointing at a modified copy of production hiera); re-apply; expect `…/ensure: defined content as '{sha256}…'` and `Triggered 'refresh' from N events`.
3. **Trigger path — purge**: plant an orphan file in a `purge => true` directory (`ssh <host> "echo … | sudo tee /etc/<dir>/<orphan>.conf"`); re-apply; expect `…/ensure: removed` and `Triggered 'refresh' from 1 event`.
4. **Idempotence**: run `--apply` once more; expect a clean catalog.

This is the cheapest way to validate a Puppet relationship change without waiting for natural drift.

### Verifying real-world effect, not just Puppet noise

A "Triggered 'refresh'" notice proves the exec was invoked. To prove the **intended effect** also happened, check the runtime state directly:

```bash
ssh <host> "cat /proc/sys/vm/swappiness"   # for sysctl reloads
ssh <host> "systemctl is-active <service>" # for service notifies
```

Compare against the baseline you captured before the test.

## Key Directories

| Path | Purpose |
|------|---------|
| `~/workspace/ucm/hiera-repos/ucm-hieradata-pie-modules/modules/coreucm/` | Hiera data root for `coreucm` module |
| `modules/coreucm/fabric/` | Per-fabric Hiera overrides (e.g. `ei4.yaml`, `grid3.yaml`) |
| `modules/coreucm/common/common.yaml` | Baseline defaults merged into all hosts (deep merge) |
| `modules/coreucm/nodes/` | Per-node Hiera overrides |
| `modules/coreucm/role/` | Per-role Hiera overrides |

## Hiera Deep Merge

The `coreucm` module uses `strategy: deep` for `coreucm::declare_resources`. This means:
- All layers (`common`, `fabric`, `role`, `node`) are **deep-merged**.
- More-specific layers (node > role > fabric > common) override keys in less-specific layers.
- Package resources defined at the `common` level apply to ALL hosts unless overridden.

## Package Management Patterns

### Install/pin a specific version

```yaml
coreucm::declare_resources::azl3:
  package:
    'LNKD-ucm-reportclient':
      ensure: '1.0.216-1.cm2'
```

Always use the **full** `version-release.dist` format (e.g. `1.0.216-1.cm2`, `1.0.216-1.el8`) for DNF to pin correctly.

### Remove a package

```yaml
coreucm::declare_resources::azl3:
  package:
    'LNKD-go-ucm-report-client':
      ensure: absent
```

### Remove a package BEFORE installing another (ordering fix)

When swapping packages (e.g. removing a go-client and installing a legacy client), DNF will fail to "upgrade" if the installed version is incompatible. Use `before` to enforce sequencing in a single Puppet run:

```yaml
coreucm::declare_resources::azl3:
  package:
    'LNKD-go-ucm-report-client':
      ensure: absent
      before: 'Package[LNKD-ucm-reportclient]'
    'LNKD-ucm-reportclient':
      ensure: '1.0.216-1.cm2'
```

> `before` is a valid Puppet metaparameter and is passed through `create_resources()`. This forces the go-client removal to complete before the legacy package is managed — preventing the first-run DNF upgrade failure.

### Suppress management (noop)

```yaml
'LNKD-ucm-reportclient':
  ensure: '1.0.216'
  noop: true
```

> `noop: true` makes Puppet simulate but not apply the change. Use only temporarily; it does NOT prevent the resource from being evaluated — Puppet will still report drift.

## OS-Specific Sections

`coreucm` resolves the OS at runtime and looks up `coreucm::declare_resources::<osver>`:

| OS | Key suffix | Dist tag |
|----|-----------|----------|
| AzureLinux 3 | `azl3` | `.cm2` |
| Mariner 2 | `mariner2` | `.cm2` |
| RHEL 8 | `rhel8` | `.el8` |
| RHEL 7 | `rhel7` | `.el7` |

Always define changes in **all relevant OS sections** to ensure consistent rollout.

## Iterative Testing Workflow

1. Edit Hiera YAML locally.
2. Run `ucm test hiera ... --install --apply` against a test host.
3. Check output for errors or unexpected changes.
4. If converged: run again to verify idempotency (second run should produce **no changes**).
5. Restore original via `git checkout -- <file>` and re-test to confirm baseline.

## Common Errors and Fixes

### `No packages marked for upgrade`

```text
Error: Could not update: Execution of '/bin/dnf -e 1 -y upgrade LNKD-ucm-reportclient-1.0.216-1.cm2' returned 1
No match for argument: LNKD-ucm-reportclient-1.0.216-1.cm2
```

**Cause:** Puppet ran DNF upgrade on a package that is at a lower/incompatible version (e.g. a stub `0.0.3` left by a previous package swap). DNF can only upgrade, not downgrade.

**Fix:** Set `before: 'Package[<other>]'` on the blocking package's removal entry so it is removed first, then the target is installed fresh.

### rsync error on install

```text
rsync error: unexpected end of file
Error: Failed to install remotely.
```

**Cause:** Network interruption or remote host connectivity issue.

**Fix:** Re-run the command. If it persists, verify SSH connectivity to the host.

### Warning: hiera path doesn't end in module name

```text
Warning: Your supplied hiera path doesn't end in coreucm. This is possibly wrong.
```

**Cause:** The `--hiera-path` argument does not end with the module name.

**Fix:** Ensure the path ends with the module name, e.g. `.../modules/coreucm`.

## Validation Checklist

- [ ] No `Error:` lines in the puppet apply output.
- [ ] Expected package changes appear as `Notice: ... ensure: created` or `removed`.
- [ ] Second run produces `Applied catalog in Xs` with no resource change notices.
- [ ] All relevant OS sections (`azl3`, `mariner2`, `rhel8`) updated consistently.
- [ ] Version strings use full `version-release.dist` format.
