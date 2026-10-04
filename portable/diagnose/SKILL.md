---
name: diagnose
description: "Use when debugging a bug, regression, crash, flaky test, or unexplained behavior, especially when the cause is not obvious or a first fix attempt already failed."
metadata:
  version: 0.1.1
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

Create 3–5 ranked, falsifiable hypotheses before testing. For a regression with a known-good version, `git bisect run <repro>` often beats hypothesizing.

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
