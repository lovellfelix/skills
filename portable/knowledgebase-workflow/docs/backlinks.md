Backlinks and how to use them

This repository includes a backlinks generator (scripts/generate-backlinks.js) that scans Markdown files and builds a simple backlinks index.

What it produces

- ./backlinks/index.json — machine-readable map of target -> [sources]
- ./backlinks/BACKLINKS.md — human-readable summary grouped by target

How it finds links

- Wikilinks: [[Document Title]] — matched case-insensitively to frontmatter `title` fields
- Relative markdown links: [text](../path/to/doc.md) — resolved relative to the source file

Usage

- Generate locally: node scripts/generate-backlinks.js
- In CI / pre-commit the generation runs automatically via scripts/kb-change-summary.sh

How to use backlinks in notes

- Place a small "Backlinks" section near the top of canonical notes that are frequently referenced. The generator will not edit your files; it only writes the index into ./backlinks/.
- Use backlinks/index.json programmatically to surface related notes in dashboards or site builds.

Keeping backlinks up-to-date

- Run the script after moving or renaming files.
- Include backlinks generation in PR review if the change reorganizes many files.
