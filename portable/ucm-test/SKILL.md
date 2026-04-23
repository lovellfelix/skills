---
name: ucm-test
description: Test UCM module changes against remote hosts using the `ucm test` CLI (hiera, puppet, etc). Use when iterating on Puppet/Hiera data for UCM modules, testing package management changes (installs, removals, downgrades), or validating catalog convergence before merging.
version: 0.1.0
portable: true
tags: [ucm, puppet, hiera, linkedin, infrastructure, work]
---

# UCM Test — Remote Host Validation via the UCM CLI

One-line summary: Test and apply UCM Puppet/Hiera changes against a remote host to validate catalog convergence before merging to production.

## Work Machine Activation

- This is a work-machine-only skill.
- It is linked only when the local work-machine flag file exists: `~/.work-env-skills`.
- Override the flag path with: `SKILL_WORK_MACHINE_FLAG_FILE=/path/to/flag`.

## When to Use

- Iterating on Puppet Hiera data for a UCM module (e.g. `coreucm`).
- Validating package install, removal, or downgrade changes before merging.
- Debugging first-run Puppet apply errors (DNF upgrade/downgrade race conditions).
- Testing resource ordering via Puppet metaparameters (`before`, `require`) in Hiera.
- Confirming idempotency — verifying a second puppet apply results in no changes.

## Command Syntax

```bash
ucm test hiera \
  --name <module-name> \
  <hostname> \
  --hiera-path <path-to-module-hiera-dir> \
  [--install] \
  [--apply]
```

### Flags

| Flag | Purpose |
|------|---------|
| `--name` | The Puppet module name (e.g. `coreucm`) |
| `--hiera-path` | Path to the local Hiera data directory for the module |
| `--install` | Symlink the local Hiera data onto the remote host |
| `--apply` | Run `puppet apply` on the remote host after installing |

### Typical Example

```bash
ucm test hiera --name coreucm lor1-0004429.int.linkedin.com \
  --hiera-path ~/workspace/ucm/hiera-repos/ucm-hieradata-pie-modules/modules/coreucm \
  --install --apply
```

> **Note:** The `--hiera-path` must end in the module name (e.g. `.../coreucm`). If it doesn't, the tool will warn but proceed.

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

```
Error: Could not update: Execution of '/bin/dnf -e 1 -y upgrade LNKD-ucm-reportclient-1.0.216-1.cm2' returned 1
No match for argument: LNKD-ucm-reportclient-1.0.216-1.cm2
```

**Cause:** Puppet ran DNF upgrade on a package that is at a lower/incompatible version (e.g. a stub `0.0.3` left by a previous package swap). DNF can only upgrade, not downgrade.

**Fix:** Set `before: 'Package[<other>]'` on the blocking package's removal entry so it is removed first, then the target is installed fresh.

### rsync error on install

```
rsync error: unexpected end of file
Error: Failed to install remotely.
```

**Cause:** Network interruption or remote host connectivity issue.

**Fix:** Re-run the command. If it persists, verify SSH connectivity to the host.

### Warning: hiera path doesn't end in module name

```
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
