---
name: google-docs-style
description: Use when writing content for Google Docs — internal docs, design summaries, proposals, updates, reviews — to produce clean, lightly formatted, professional output that looks natural when pasted into Google Docs.
metadata:
  version: 0.1.0
  portable: true
  tags: [writing, google-docs, formatting, style, portable]
---

# Google Docs Style

Write as if an experienced technical lead drafted the doc by hand: clean, natural, and immediately useful when pasted into Google Docs. No AI-sounding phrasing. No heavy, decorative formatting.

## Writing Defaults

- Clear, concise, practical language
- Natural human tone — smart but not stiff
- Direct without sounding harsh
- Professional but modern
- Leadership-readable
- Minimal fluff
- Slightly polished, not corporate buzzword heavy
- Concise by default unless depth is explicitly requested
- Preserve technical accuracy
- Rewrite awkward prompts into clean business writing automatically

## Formatting Rules

- Prefer plain paragraphs over excessive formatting
- Use short sections with simple headers (## level) only when they help navigation
- Use bullets for lists, actions, risks, decisions, next steps
- Avoid tables unless clearly beneficial (prefer bullets)
- Avoid excessive nesting (max 2 levels)
- Bold only for rare, high-value emphasis — never bold every keyword
- Avoid italics unless genuinely necessary
- No decorative formatting (no emoji, no colored callouts, no unnecessary separators, no horizontal rules)
- File names, commands, and code references should be plain text unless clarity specifically requires monospace
- Keep whitespace clean and readable — one blank line between sections, no double-blanks

## Markdown-to-Google Docs Conversion Rules

When converting Markdown into Google Docs, prefer approaches that preserve semantics and avoid fragile Markdown constructs. Follow these rules to improve conversion fidelity and reduce post-conversion cleanup:

- Use simple hyphen (-) bullets for lists and avoid tabs for indentation; limit nesting to one level when possible.
- Prefer descriptive anchor text for links rather than pasting raw URLs.
- Avoid complex Markdown tables, multi-line fenced code blocks, and raw HTML blocks — use Docs APIs or attachments for precision.
- Use explicit, left-aligned headings (##/###) without indenting or quoting.
- Keep short paragraphs and remove trailing spaces or stray tab characters that commonly break conversion.
- For non-text elements (images, tables, code), prefer the Docs API or dedicated upload tools so elements become native Docs objects with alt text, captions, and proper formatting.

Conversion checklist (quick):

- Remove stray tabs and trailing spaces.
- Convert inline images to attachments and insert via Docs tooling.
- Use Markdown ordered/list syntax, not manual numbered prefixes.
- Replace wiki-style [[Page]] links with descriptive anchor text and URLs.

These rules reduce common conversion errors and produce Docs-native artifacts whenever possible.


## Structure Defaults

When the document needs structure, use this template. Do not force it on every response — match the complexity of the content.

```
Title

Short context paragraph.

## Key Points
- bullet list

## Details
Short paragraphs and bullets as needed.

## Risks / Notes
- if relevant

## Next Steps
- if relevant
```

If one paragraph answers the question, use one paragraph. If two bullets cover the risks, use two bullets. Do not pad.

## Anti-patterns

- Don't over-template every response
- Don't add sections that have no content worth stating
- Don't bold more than 2-3 words per page
- Don't use tables for 2-3 simple items (use bullets)
- Don't add background/context sections the reader already knows
- Don't use headings for single-paragraph content
- Don't nest bullets more than 2 levels deep
- Don't add "Summary" sections that repeat the content above
- Don't use inline code formatting for non-code references (project names, team names, product names)
- Don't add disclaimers, caveats, or "feel free to" language

## Complexity Matching

Match document complexity to the request. A quick decision needs one paragraph and a recommendation. A design review needs structured sections; a status update needs bullets. More content is not better content.

## Strong Opening (reader-first)

Start with the answer. Put the decision or recommendation (one sentence) first, then add a one-line "why now" and a single-sentence context line if needed. Readers should be able to understand the outcome and its urgency in 5 seconds.

Example opening:

Title

- Recommendation: Accept the proposal to X (one clear sentence)
- Why now: Short reason (one line)
- Scope: Short scope line (who/what/when)

Follow immediately with an "At a glance" block for concise metadata — use a short bullet list, not a pipe-delimited line.

## At-a-glance metadata (concise)

When metadata is useful, prefer a small bullet list labeled "At a glance" rather than cramming fields into a single header line. Keep this to 3–6 items: owner, decision owner, status, timeline, relevant IDs or links.

Example:

## At a glance
- Owner: team/name
- Decision owner: Alice
- Status: Proposed
- ETA: 2026-05-01
- Doc: link-to-doc (use anchor text)

## Bullets vs Tables vs Prose

- Bullets: Use for short enumerations, actions, decisions, risks, and next steps. Ideal for 1–6 items. Bullets are the most readable format for quick scanning.
- Tables: Use when you have many rows or multiple aligned fields per row (for example: a tracker with >4 rows or a comparison matrix with multiple columns). Avoid tables for 2–3 simple items — they add visual weight and reduce skimmability.
- Prose: Use when you need to explain reasoning, trade-offs, or context that doesn't fit a short list. One idea per short paragraph.

## Tooling / Markdown guidance

- Use Markdown as the primary authoring source for Google Docs content. When publishing, call the document tools to create and append content. Prefer not to pass a tab_id by default — this preserves conversion fidelity and reduces accidental nested-list artifacts. Supply tab_id only when you intentionally target a specific tab and accept lower formatting fidelity.
- Avoid pipe-delimited metadata lines at the top of a document — they often convert poorly to Google Docs and look machine-generated.
- Prefer descriptive anchor text for links (e.g., "Design doc" → link) rather than pasting raw URLs when the tooling supports it.
- Watch for stray tab characters or trailing spaces: these commonly cause unwanted list behavior. Use plain hyphen bullets (-) and do not indent list items with tabs.

### Non-text content (common cases)

- Code blocks / preformatted text: Avoid fenced code blocks (```lang) — they often convert poorly and can cause nested list/formatting issues in Docs. For short snippets use inline monospace (`code`) or single-line backtick examples; for longer code samples attach the file (or link to a Gist/Repo) and/or use the Docs API/tooling to insert native, syntax-highlighted code blocks when precise rendering is required.
- Images: provide images as separate assets and use the Docs API or the dedicated upload tool to insert them with alt text and captions. Do not rely on large inline base64 blobs in Markdown.
- Tables: avoid relying on Markdown pipe tables for high-precision tabular data. For exact column widths, cell formatting, or complex tables, use the Docs-specific APIs/tools to create native Tables rather than pasting raw Markdown tables.

When precision matters for non-text elements (nested lists, tables with formatting, captions, or images with positioning), prefer the dedicated Docs APIs/tools instead of relying on conversion from Markdown.

## Anti-patterns (concrete)

Based on the provided bad-example, call out these avoidable mistakes explicitly:
- Pipe-delimited header/compressed metadata lines at the top of the doc.
- Every paragraph styled as a list or indented block — this makes the doc feel mechanically generated and hard to read.
- Excessive small key/value tables when bullets would suffice (especially for 2–3 items).
- Long sequences of weak, generic sentences instead of a clear recommendation up front.
- Raw links and inline references without anchor text or context.
- Overuse of headings with single-paragraph content underneath.
- Mechanical phrasing that sounds like an extraction rather than editorialized writing.
- Deeply nested or tab-indented bullets — prefer flat hyphen bullets (-) and avoid tabs for indentation.
- Relying on fenced multi-line code blocks for long examples instead of attachments or Docs-native code insertion.
- Indented or block-quoted headings (e.g., using > or extra indentation before a heading) — these convert poorly; use regular heading lines.
- Multiple consecutive blank lines (double or triple blanks) — they create large gaps in Docs; use a single blank line between sections.
- Manual numbered prefixes typed outside of Markdown ordered lists (manual '1. 2. 3.' in plain text) — prefer Markdown ordered lists to preserve automatic numbering.
- Wiki-style links ([[PageName]]) — they do not convert to Doc hyperlinks; use descriptive anchor text with the full URL.

## Tone & Editing

- Edit for brevity and the reader's attention span: prefer shorter paragraphs and shorter sentences.
- Eliminate "AI-style" hedging ("may", "could", "might") when a clear recommendation is expected — use a recommendation + risks pattern instead.
- When you reuse text from other sources (PR, issues, tickets), convert it into reader-first prose rather than pasting field dumps.

## Related Skills

This skill controls writing style and formatting for Google Docs content. For Google Docs API tooling (creating, reading, writing documents), use a machine-local overlay skill if one is configured.
