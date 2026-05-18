#!/bin/bash
# gstack SessionStart hook — bootstrap gstack skills in Claude Code on the web.
#
# Web sessions run in a fresh ephemeral container with no ~/.claude/skills, so
# none of the gstack slash-commands exist until something installs them. This
# hook runs ./setup against this checkout at session start, which links every
# gstack skill (/review, /ship, /office-hours, ...) into ~/.claude/skills/.
#
# Browser skills are intentionally skipped: the web network policy blocks the
# Playwright CDN (cdn.playwright.dev → 403 "Host not in allowlist"), so Chromium
# can't be fetched. GSTACK_SKIP_BROWSER=1 lets ./setup finish the non-browser
# install instead of hard-failing. Planning / review / ship skills work; /browse,
# /qa, /design-review stay unavailable until Chromium is present.
#
# Idempotent, non-interactive, network-failure-safe: never blocks session start.
set -uo pipefail

# Web/remote sessions only. Local sessions already have gstack installed
# globally (via bin/gstack-personal-init or ./setup) — re-running here would be
# redundant and slow.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

REPO_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$REPO_DIR" || exit 0

echo "[gstack] web session detected — bootstrapping skills..."

if ! command -v bun >/dev/null 2>&1; then
  echo "[gstack] bun not found; skipping bootstrap (skills unavailable this session)."
  exit 0
fi

# ./setup is idempotent: it rebuilds binaries only when stale and links every
# skill into ~/.claude/skills/. GSTACK_SKIP_BROWSER=1 skips the Chromium gate
# (web CDN is blocked). Quiet + flat skill names (/review, not /gstack-review),
# non-interactive (no TTY).
if GSTACK_SKIP_BROWSER=1 ./setup --no-prefix -q; then
  echo "[gstack] ready — gstack skills available (e.g. /office-hours, /review, /ship)."
else
  echo "[gstack] setup did not complete; gstack skills may be unavailable this session." >&2
fi

# Never fail session start on bootstrap problems.
exit 0
