# Google Docs Output

Apply on top of `SKILL.md` and `writing-guide.md` when the output will be pasted into, or published to, Google Docs. Goal: a doc that reads as if an experienced tech lead wrote it by hand, and converts cleanly from Markdown.

## Shape

- Open with the answer: recommendation or decision in one sentence, then a one-line "why now", then scope if needed. A reader should get the outcome in five seconds.
- When metadata helps, add a short "At a glance" bullet list (3–6 items: owner, decision owner, status, timeline, links). Never a pipe-delimited header line.
- Match structure to the request. One paragraph answers a quick question. A status update is bullets. A design review gets sections. Do not force a template.
- Optional skeleton for longer docs, keeping only sections with real content:

```
Title

Short context paragraph.

## Key Points
## Details
## Risks / Notes
## Next Steps
```

## Formatting

- Plain paragraphs by default. `##`/`###` headings only when they help navigation, never over a single paragraph.
- Bullets for 1–6 short items (actions, risks, decisions). Tables only for many rows or multi-field comparisons, never for 2–3 items.
- Max two nesting levels. Bold at most 2–3 phrases per page. Avoid italics.
- No emoji, colored callouts, horizontal rules, or "Summary" sections that repeat the doc.
- Product, team, and file names in plain text. Monospace only where it is actually code.
- Turn pasted field dumps (PR/ticket text) into reader-first prose.

## Markdown-to-Docs conversion

These constructs convert badly. Avoid them:

- Tab-indented or deeply nested bullets: use flat `-` bullets, spaces only.
- Manually typed `1.` numbering outside a real Markdown list.
- Indented or `>`-quoted headings.
- Multiple consecutive blank lines, trailing spaces, stray tabs.
- Wiki links (`[[Page]]`) and raw URLs: use descriptive anchor text.
- Multi-line fenced code blocks and pipe tables where precision matters: attach the file, link a repo/gist, or insert native Docs tables/code via the Docs API.
- Inline base64 images: upload images as separate assets with alt text.

When publishing through a Docs tool, omit `tab_id` unless you intentionally target a tab; it lowers conversion fidelity.

For Google Docs API tooling (create/read/write), use a machine-local overlay skill if one is configured.
