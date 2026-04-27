---
name: kb-maintenance
description: "Structured workflow for knowledgebase health checks, inbox processing, oncall note management, metadata cleanup, and archive operations. Use when user asks to clean up KB, run a health check, process inbox, organize notes, or archive old content."
version: 0.1.0
portable: true
tags: [knowledgebase, maintenance, workflow, documentation, notes]
---

# KB Maintenance Skill

> Structured workflow for knowledgebase health checks, inbox processing, metadata cleanup, and archiving.

## Trigger Conditions

Use this skill when the user asks to:
- Clean up or organize the knowledgebase
- Run a KB health check
- Process inbox notes
- Archive old oncall notes
- Fix metadata or broken links

## Work Machine Activation

This skill is work-machine only.

- Enable work context with the `~/.work-env-skills` flag.
- Do not expect bootstrap/runtime sync to surface this skill on personal context without that flag.

## KB Location

`~/knowledgebase` — emoji-based directory structure. See `AGENTS.md` for full layout.

## Phase 1: Health Check

Always start here unless the user specifies a narrower task.

```bash
# Validate metadata coverage
cd ~/knowledgebase && node .mcp/validate-metadata.js 2>&1 | tail -20

# Count inbox backlog
ls "📝 Notes/Inbox/" | wc -l

# Check for broken links (should be 0 in active content)
grep -r "broken-link" --include="*.md" . | grep -v ".trash\|.git\|Archive\|node_modules" | wc -l

# Check oncall folder for duplicates/archiveable notes
ls "📝 Notes/⚙️ Operations/oncall/"
```

Report findings before proceeding.

## Phase 2: Inbox Processing

Inbox location: `📝 Notes/Inbox/`

For each file:
1. Read it: `work_knowledgebase action=read identifier="📝 Notes/Inbox/<file>"`
2. Classify:
   - Operations procedure → `📝 Notes/⚙️ Operations/`
   - Monitoring guide → `📝 Notes/📊 Monitoring/`
   - Reference/cheatsheet → `📚 Reference/🔧 Cheatsheets/`
   - Project material → `🚀 Projects/<area>/`
   - Duplicate of existing note → delete
   - JIRA/copy-paste artifact → `📦 Archive/`
3. Fix frontmatter (add missing description, keywords, type, modified date)
4. Move the file using bash `mv`
5. After all files are processed: `work_knowledgebase action=commit commitType=inbox`

## Phase 3: Oncall Archive

Archive convention:
- `📦 Archive/oncall/YYYY-QX/` (Q1=Jan-Mar, Q2=Apr-Jun, Q3=Jul-Sep, Q4=Oct-Dec)
- Keep only the current quarter's notes in active oncall folder
- Duplicates for the same week: keep the canonical `Oncall Notes - Week Ending <Date> - X.md` form, archive the rest

```bash
# Create archive dirs
mkdir -p "📦 Archive/oncall/2026-Q1"
# Move old notes
mv "📝 Notes/⚙️ Operations/oncall/Oncall Notes - Week Ending Feb*" "📦 Archive/oncall/2026-Q1/"
# After archiving
work_knowledgebase action=commit commitType=update message="archive oncall Q1 2026"
```

## Phase 4: Metadata Repair

Priority order for metadata fixes:
1. Files with missing frontmatter entirely → add minimal block
2. Active files missing `description` → derive from title + first paragraph
3. Active files missing `keywords` → derive from title + tags
4. YAML parse errors → fix manually

```bash
# Validate after fixes
cd ~/knowledgebase && node .mcp/validate-metadata.js 2>&1 | grep -E "title:|description:|keywords:|FAILED|PASSED"
```

Target coverage: description ≥ 80%, keywords ≥ 80%.
Archive files are exempt from coverage targets.

## Phase 5: Broken Links

Active content should have zero `#broken-link-*` anchors.

```bash
grep -r "broken-link" --include="*.md" ~/knowledgebase | grep -v ".trash\|.git\|Archive\|node_modules"
```

If any are found: for each broken link either find the target file and update to a relative path, or convert to plain text.

## Phase 6: Index Rebuild

After any structural changes (moved files, new files, frontmatter fixes):

```bash
cd ~/knowledgebase/.mcp && node generate-index.js
```

## Phase 7: Final Commit

```bash
work_knowledgebase action=commit commitType=update message="KB maintenance $(date +%Y-%m-%d)"
```

## Quick Reference

| Task | Command |
|------|---------|
| Validate metadata | `cd ~/knowledgebase && node .mcp/validate-metadata.js` |
| Rebuild search index | `cd ~/knowledgebase/.mcp && node generate-index.js` |
| Find broken links | `grep -r "broken-link" --include="*.md" ~/knowledgebase \| grep -v ".git\|Archive\|node_modules"` |
| List inbox | `ls ~/knowledgebase/📝\ Notes/Inbox/` |
| Query notes by tag | `work_knowledgebase action=query_tag tag=<tag>` |
| Query notes by type | `work_knowledgebase action=query_type queryType=runbook` |
| Commit changes | `work_knowledgebase action=commit commitType=<inbox\|oncall\|notes\|update>` |

## Notes

- Never commit unless the user asked for it OR the workflow explicitly opts in (inbox, oncall)
- Skip Archive/, scratch/, and node_modules/ for metadata coverage targets
- Prefer `work_knowledgebase action=write` for creating new notes (handles frontmatter + folder creation)
- The KB has no build system — validation tools are `node .mcp/validate-metadata.js` and `node .mcp/generate-index.js`
