#!/usr/bin/env bash
set -euo pipefail

# install.sh — clone or update the lovellfelix/skills repo.
#
#   curl -fsSL https://raw.githubusercontent.com/lovellfelix/skills/main/install.sh | bash
#
# This repo is currently private, so the one-liner above only works with
# git credentials already configured (SSH key or `gh auth login`) — it is
# not anonymously fetchable like a public curl-|-bash installer.
#
# This script only clones/updates the repo at SKILLS_ROOT. It does not
# materialize runtime-specific skill links (Claude Code, OpenCode, Pi);
# for that, run dotfiles' hacks/sync-skill-runtime-links.sh afterward.

SKILLS_ROOT="${SKILLS_ROOT:-$HOME/.skills}"
SKILLS_REMOTE="${SKILLS_REMOTE:-git@github.com:lovellfelix/skills.git}"

if [[ -d "$SKILLS_ROOT/.git" ]]; then
  echo "skills repo already present at $SKILLS_ROOT, pulling..."
  git -C "$SKILLS_ROOT" pull --ff-only origin main
elif [[ -d "$SKILLS_ROOT" ]]; then
  echo "ERROR: $SKILLS_ROOT exists but is not a git repo; refusing to overwrite" >&2
  exit 1
else
  mkdir -p "$(dirname "$SKILLS_ROOT")"
  echo "cloning skills repo from $SKILLS_REMOTE..."
  git clone "$SKILLS_REMOTE" "$SKILLS_ROOT"
fi

echo
echo "skills repo ready at: $SKILLS_ROOT"
echo "next: run dotfiles' hacks/sync-skill-runtime-links.sh to link skills into each harness's runtime skill directory."
