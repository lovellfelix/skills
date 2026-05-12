---
name: diagnose
description: Use when debugging bugs or regressions with a disciplined loop: feedback signal, reproduce, hypothesize, instrument, fix, and lock with regression coverage.
metadata:
  version: 0.1.0
  portable: true
  tags: [debugging, diagnosis, regression, reliability, portable]
---

# Diagnose

A strict debugging loop for hard bugs and regressions.

## 1) Build a feedback loop first

Do not guess without a reproducible pass/fail signal.

Preferred order:
1. Failing test
2. Scripted API/CLI repro
3. Minimal harness / replay input
4. Property/fuzz loop for flaky issues
5. HITL scripted loop only as last resort

If no loop can be built, stop and report what was tried plus what access/artifacts are needed.

## 2) Reproduce

Confirm the loop reproduces the user-reported symptom (not a nearby failure).

## 3) Hypothesize

Create 3–5 ranked, falsifiable hypotheses before testing.

## 4) Instrument

Probe one variable at a time.
Use debugger first, then targeted logs. Tag temporary logs with a unique marker for cleanup.

## 5) Fix + regression

- Add regression test at the correct seam before applying fix (when feasible).
- Apply minimal fix.
- Re-run original repro loop and regression tests.

## 6) Cleanup + post-mortem

- Remove temporary instrumentation and throwaway debug artifacts.
- Record root cause and why the fix works.
- If no good seam exists, flag architecture debt and hand off to `improve-codebase-architecture`.
