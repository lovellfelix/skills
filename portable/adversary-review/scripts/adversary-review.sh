#!/usr/bin/env bash
# adversary-review.sh — critique a plan/design/proposal/PR via a frontier
# reasoning model on the OpenCode Go subscription.
#
# Claude Code's native Agent tool can only spawn Claude-model subagents
# (sonnet/opus/haiku/fable) -- it has no path to an opencode-go model
# directly. This script is that path: it calls the model over HTTP and
# prints the critique, so a Claude Code session (or the adversary-review
# skill) can shell out to it for a genuine second opinion from a different
# model family, rather than Claude critiquing its own plan.
#
# Model: gpt-5.6-luna by default -- chosen 2026-08-06 by live-testing
# candidates on an actual critique-shaped prompt (not a coding task):
# deepseek-v4-pro (jarvis's own tool-agent.sh default) returned an EMPTY
# response for this task shape despite HTTP 200 and a full token budget
# spent -- good at short deterministic tool-calls, unreliable for open-
# ended critique generation via this endpoint. kimi-k2.6 rambled through
# its entire visible reasoning without ever reaching a final answer within
# budget (same failure mode observed on tool-calling tests earlier the
# same day). qwen3.7-max produced a correct critique but at 17x the token
# cost of gpt-5.6-luna for comparable quality. minimax-m3 was comparably
# good and cheaper per-token but has no coding/reasoning benchmark
# anywhere in this repo's research; gpt-5.6-luna already has documented
# precedent here for "maximum quality, critical tasks" (see
# docs/agents/MODEL-SELECTION.md's `deep`/`ultra` interactive modes).
#
# Usage:
#   adversary-review.sh [--perspective NAME] [--model MODEL] [--file PATH] [CONTENT]
#   cat plan.md | adversary-review.sh --perspective "security engineer"
#   adversary-review.sh --file docs/adr/003-migration.md --perspective competitor
#
# Environment variables:
#   OPENCODE_GO_API_KEY — the account's Go API key. Falls back to
#                          ~/.local/share/opencode/auth.json (the opencode
#                          CLI's own credential store) if unset, matching
#                          hacks/llm-proxy.py's own fallback.
#   OPENCODE_GO_MODEL    — override the default model (gpt-5.6-luna)
set -euo pipefail


PERSPECTIVE="skeptical but fair domain expert"
MODEL="${OPENCODE_GO_MODEL:-gpt-5.6-luna}"
FILE=""
CONTENT_ARG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --perspective) PERSPECTIVE="$2"; shift 2 ;;
    --model) MODEL="$2"; shift 2 ;;
    --file) FILE="$2"; shift 2 ;;
    *) CONTENT_ARG="$1"; shift ;;
  esac
done

if [[ -n "$FILE" ]]; then
  [[ -f "$FILE" ]] || { echo "[adversary-review] file not found: $FILE" >&2; exit 1; }
  content="$(cat "$FILE")"
elif [[ -n "$CONTENT_ARG" ]]; then
  content="$CONTENT_ARG"
else
  content="$(cat)"
fi
[[ -n "$content" ]] || { echo "[adversary-review] no content provided" >&2; exit 1; }

OPENCODE_GO_API_KEY="${OPENCODE_GO_API_KEY:-}"
if [[ -z "$OPENCODE_GO_API_KEY" ]]; then
  AUTH_FILE="$HOME/.local/share/opencode/auth.json"
  if [[ -f "$AUTH_FILE" ]]; then
    OPENCODE_GO_API_KEY="$(jq -r '.["opencode-go"].key // empty' "$AUTH_FILE" 2>/dev/null)"
  fi
fi
if [[ -z "$OPENCODE_GO_API_KEY" ]]; then
  echo "[adversary-review] no OPENCODE_GO_API_KEY (env or ~/.local/share/opencode/auth.json)" >&2
  exit 1
fi

read -r -d '' SYSTEM_PROMPT <<- PROMPT_EOF || true
You are a senior adversary agent. Critique the given content with the depth
and thoroughness of a senior domain expert looking for weaknesses. Content
may be a plan, design doc, RFC, proposal, incident analysis, or code diff.

Adopt this perspective while critiquing: ${PERSPECTIVE}

Structure your critique exactly as follows:

## Summary
One paragraph: overall quality and fitness for purpose from the requested
perspective. State the single biggest issue and the single strongest point.

## Findings by Severity
**Critical** — blocks use unless fixed: the issue, why it matters, what's at stake.
**Major** — should be addressed before proceeding: the issue, suggested direction.
**Minor** — polish items.

## Blind Spots
- What perspective is missing? Who would disagree and why?
- What risk or edge case is unaddressed?
- What would someone with 2x more context notice that this misses?

## Probing Questions
3-5 sharp questions someone playing this perspective would ask — questions
that would materially improve the content if answered.

## Recommendations
Top 3 concrete improvements, ordered by impact.

Rules: critique only, do not rewrite the content. Be specific -- "unclear"
is not useful; say what is unclear, where, and why. Be fair -- acknowledge
what's done well before criticizing. If the content is genuinely strong,
say so plainly rather than manufacturing issues.
PROMPT_EOF

payload="$(jq -nc --arg model "$MODEL" --arg sys "$SYSTEM_PROMPT" --arg content "$content" '{
  model: $model,
  max_tokens: 4096,
  system: [{type: "text", text: $sys}],
  messages: [{role: "user", content: [{type: "text", text: $content}]}]
}')" || { echo '{"error":"jq failed"}' >&2; exit 1; }

response="$(curl -sS --max-time 120 -w '\n%{http_code}' \
  -H "x-api-key: $OPENCODE_GO_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "Content-Type: application/json" \
  -d "$payload" \
  "https://opencode.ai/zen/go/v1/messages" 2>/dev/null)" || {
  rc=$?
  echo "[adversary-review] curl failed with exit $rc" >&2
  exit 1
}

http_code="$(echo "$response" | tail -n1)"
body="$(echo "$response" | sed '$d')"

if [[ "$http_code" != "200" ]]; then
  error_msg="$(echo "$body" | jq -r '.error.message // "unknown"' 2>/dev/null)" || error_msg="$body"
  echo "[adversary-review] API returned HTTP $http_code: $error_msg" >&2
  exit 1
fi

if critique="$(echo "$body" | jq -r '[.content[]? | select(.type == "text")][0].text // empty' 2>/dev/null)" && [[ -n "$critique" ]]; then
  echo "$critique"
else
  echo "[adversary-review] model returned no critique text (model=$MODEL may need a higher max_tokens for this content length, or try --model minimax-m3)" >&2
  exit 1
fi
