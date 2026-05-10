---
name: github
description: "Use when interacting with GitHub issues, PRs, CI runs, or repository data via the gh CLI."
metadata:
  version: 0.1.0
  portable: true
  tags: [github, gh, cli, pr, ci, issues]
---

# GitHub Skill

Use the `gh` CLI to interact with GitHub. Always specify `--repo owner/repo` when not in a git directory, or use URLs directly.

## Rules

- Authenticate first: `gh auth status` to check auth state.
- Rate limits: Authenticated requests have higher limits. Use `gh api rate_limit` to check.
- Fail gracefully: If `gh` isn't authenticated, prompt user to run `gh auth login`.

## Pull Requests

Check CI status on a PR:
```bash
gh pr checks 55 --repo owner/repo
```

List recent workflow runs:
```bash
gh run list --repo owner/repo --limit 10
```

View a run and see which steps failed:
```bash
gh run view <run-id> --repo owner/repo
```

View logs for failed steps only:
```bash
gh run view <run-id> --repo owner/repo --log-failed
```

## API for Advanced Queries

The `gh api` command is useful for accessing data not available through other subcommands.

Get PR with specific fields:
```bash
gh api repos/owner/repo/pulls/55 --jq '.title, .state, .user.login'
```

## JSON Output

Most commands support `--json` for structured output.  You can use `--jq` to filter:

```bash
gh issue list --repo owner/repo --json number,title --jq '.[] | "\(.number): \(.title)"'
```
