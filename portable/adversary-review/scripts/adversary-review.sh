#!/usr/bin/env bash
# adversary-review.sh — critique a plan/design/proposal/PR via a frontier
# reasoning model on the local Codex subscription (CLIProxyAPI).
#
# Claude Code's native Agent tool can only spawn Claude-model subagents
# (sonnet/opus/haiku/fable) -- it has no path to a non-Claude model
# directly. This script is that path: it calls the model over HTTP and
# prints the critique, so a Claude Code session (or the adversary-review
# skill) can shell out to it for a genuine second opinion from a different
# model family, rather than Claude critiquing its own plan.
#
# Transport history: this script originally called gpt-5.6-luna through the
# OpenCode Go subscription (https://opencode.ai/zen/go/v1/messages,
# Anthropic-native). That path broke: the Go endpoint now 500s for
# gpt-5.6-luna, rejects other models without an x-opencode-session header,
# and gates deepseek-v* behind a China-hosting opt-in. gpt-5.6-luna is a
# Codex-family model served by the local CLIProxyAPI instance (ChatGPT
# subscription, OpenAI-compatible), so the script now calls it there
# directly -- verified live 2026-09-14.
#
# Model: gpt-5.6-luna by default -- chosen 2026-08-06 by live-testing
# candidates on an actual critique-shaped prompt (not a coding task):
# deepseek-v4-pro returned an EMPTY response for this task shape despite
# HTTP 200; kimi-k2.6 rambled without reaching a final answer within
# budget; qwen3.7-max produced a correct critique but at 17x the token
# cost of gpt-5.6-luna for comparable quality. gpt-5.6-luna already has
# documented precedent here for "maximum quality, critical tasks" (see
# docs/agents/MODEL-SELECTION.md's `deep`/`ultra` interactive modes).
# Any other model served by the local CLIProxyAPI (see /v1/models) can be
# selected with --model.
#
# Usage:
#   adversary-review.sh [--perspective NAME] [--model MODEL] [--file PATH] [CONTENT]
#   cat plan.md | adversary-review.sh --perspective "security engineer"
#   adversary-review.sh --file docs/adr/003-migration.md --perspective competitor
#
# Environment variables:
#   CODEX_PROXY_BASE_URL — CLIProxyAPI base URL
#                          (default: http://127.0.0.1:8317/v1)
#   CODEX_PROXY_API_KEY  — shared secret for CLIProxyAPI. Falls back to
#                          ~/.config/llm-proxy/codex-token (or
#                          $CODEX_PROXY_API_KEY_FILE), matching
#                          hacks/llm-proxy.py's own fallback.
#   ADVERSARY_MODEL      — override the default model (gpt-5.6-luna).
#                          $CODEX_MODEL / $OPENCODE_GO_MODEL honored as
#                          fallbacks for back-compat.
set -euo pipefail


PERSPECTIVE="skeptical but fair domain expert"
MODEL="${ADVERSARY_MODEL:-${CODEX_MODEL:-${OPENCODE_GO_MODEL:-gpt-5.6-luna}}}"
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
  content="$(< "$FILE")"
elif [[ -n "$CONTENT_ARG" ]]; then
  content="$CONTENT_ARG"
else
  content="$(cat)"
fi
[[ -n "$content" ]] || { echo "[adversary-review] no content provided" >&2; exit 1; }

CODEX_BASE_URL="${CODEX_PROXY_BASE_URL:-http://127.0.0.1:8317/v1}"
CODEX_PROXY_API_KEY="${CODEX_PROXY_API_KEY:-}"
if [[ -z "$CODEX_PROXY_API_KEY" ]]; then
  KEY_FILE="${CODEX_PROXY_API_KEY_FILE:-$HOME/.config/llm-proxy/codex-token}"
  if [[ -f "$KEY_FILE" ]]; then
    CODEX_PROXY_API_KEY="$(< "$KEY_FILE")"
    # Token files may carry a trailing newline; strip whitespace.
    CODEX_PROXY_API_KEY="$(printf '%s' "$CODEX_PROXY_API_KEY" | tr -d '[:space:]')"
  fi
fi
if [[ -z "$CODEX_PROXY_API_KEY" ]]; then
  echo "[adversary-review] no CODEX_PROXY_API_KEY (env or ~/.config/llm-proxy/codex-token)" >&2
  echo "[adversary-review] is CLIProxyAPI configured? See hacks/llm-proxy.py 'codex/' backend." >&2
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
  messages: [
    {role: "system", content: $sys},
    {role: "user", content: $content}
  ]
}')" || { echo '[adversary-review] jq failed to build request payload' >&2; exit 1; }

response="$(curl -sS --max-time 180 -w '\n%{http_code}' \
  -H "Authorization: Bearer $CODEX_PROXY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$payload" \
  "$CODEX_BASE_URL/chat/completions" 2>&1)" || {
  rc=$?
  echo "[adversary-review] curl failed with exit $rc -- is CLIProxyAPI running at $CODEX_BASE_URL?" >&2
  exit 1
}

http_code="$(printf '%s' "$response" | tail -n1)"
body="$(printf '%s' "$response" | sed '$d')"

if [[ "$http_code" != "200" ]]; then
  error_msg="$(printf '%s' "$body" | jq -r '.error.message // .error // "unknown"' 2>/dev/null)" || error_msg="$body"
  echo "[adversary-review] API returned HTTP $http_code: $error_msg" >&2
  if [[ "$http_code" == "401" ]]; then
    echo "[adversary-review] check CODEX_PROXY_API_KEY matches CLIProxyAPI api-keys config" >&2
  fi
  exit 1
fi

if critique="$(printf '%s' "$body" | jq -r '.choices[0].message.content // empty' 2>/dev/null)" && [[ -n "$critique" ]]; then
  echo "$critique"
else
  echo "[adversary-review] model returned no critique text (model=$MODEL; check it is listed in $CODEX_BASE_URL/models)" >&2
  exit 1
fi
