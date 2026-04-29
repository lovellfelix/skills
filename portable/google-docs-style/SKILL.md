---
name: google-docs-style
description: Use when writing content for Google Docs — internal docs, design summaries, proposals, updates, reviews — to produce clean, lightly formatted, professional output that looks natural when pasted into Google Docs.
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
- Don't use tables for 2-3 items (use bullets)
- Don't add background/context sections the reader already knows
- Don't use headings for single-paragraph content
- Don't nest bullets more than 2 levels deep
- Don't add "Summary" sections that repeat the content above
- Don't use inline code formatting for non-code references (project names, team names, product names)
- Don't add disclaimers, caveats, or "feel free to" language

## Complexity Matching

Match document complexity to the request. A quick decision needs one paragraph and a recommendation. A design review needs structured sections; a status update needs bullets. More content is not better content.

## Related Skills

This skill controls writing style and formatting for Google Docs content. For Google Docs MCP API tooling (creating, reading, writing documents), see the `google-docs` runtime skill or the `writing-google-docs` LinkedIn plugin skill.
