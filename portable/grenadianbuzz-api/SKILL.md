---
name: grenadianbuzz-api
description: Compatibility shim for the legacy GrenadianBuzz API skill. Canonical package is grenadianbuzz.
version: 0.1.1
portable: true
tags: [api, openapi, prd, product, grenadianbuzz, compatibility]
---

# GrenadianBuzz API (Compatibility)

This package is a thin compatibility shim.

Canonical skill package: `skills/portable/grenadianbuzz/`

## Migration

- Prefer loading `grenadianbuzz` for all new usage.
- Existing references to `grenadianbuzz-api` remain functional and should redirect to the canonical package context.

## Canonical references

- `../grenadianbuzz/SKILL.md`
- `../grenadianbuzz/INDEX.md`
- `../grenadianbuzz/reference/grenadianbuzz-api-patterns.md`
- `../grenadianbuzz/reference/grenadianbuzz-domain-checklist.md`
- `../grenadianbuzz/reference/grenadianbuzz-cli-guide.md`
- `../grenadianbuzz/reference/grenadianbuzz-dashboard-guide.md`
- `../grenadianbuzz/reference/grenadianbuzz-website-guide.md`
- `../grenadianbuzz/templates/quick-reference.md`
- `../grenadianbuzz/templates/api-prd-template.md`
