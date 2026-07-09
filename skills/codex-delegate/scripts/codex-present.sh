#!/usr/bin/env bash
# codex-present.sh — open a finished artifact (file or URL) in the app configured
# under `computerUse.openers`, for the "present results" / computer-use capability.
#
# Usage:
#   codex-present.sh <path-or-url>        # open it in the configured app
#   codex-present.sh --is-viewable <path> # exit 0 if the artifact is auto-presentable, else 1
#   codex-present.sh --app "<AppName>" <path-or-url>   # force a specific app
#
# Resolution: an http(s) URL uses the `url` opener; a file uses the opener for its
# extension, else `openers.default` (null => macOS default app via bare `open`).
# macOS only (uses `open`). No AppleScript here — bare `open -a` needs no special
# permission; enable richer control yourself only if `computerUse.allowAppleScript`.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$HERE/codex-config.sh"

is_url() { case "$1" in http://*|https://*) return 0;; *) return 1;; esac; }
lc_ext() { local n="${1##*/}"; case "$n" in *.*) printf '.%s' "$(printf '%s' "${n##*.}" | tr '[:upper:]' '[:lower:]')";; *) printf '';; esac; }

# --is-viewable: is this artifact in computerUse.viewableExtensions (or a URL)?
if [ "${1:-}" = "--is-viewable" ]; then
  target="${2:-}"; [ -n "$target" ] || { echo "usage: codex-present.sh --is-viewable <path>" >&2; exit 2; }
  is_url "$target" && exit 0
  ext="$(lc_ext "$target")"; [ -n "$ext" ] || exit 1
  exts_json="$("$CONFIG" get computerUse.viewableExtensions 2>/dev/null || echo '[]')"
  printf '%s' "$exts_json" | python3 -c "import json,sys; sys.exit(0 if '$ext' in json.load(sys.stdin) else 1)"
  exit $?
fi

FORCE_APP=""
if [ "${1:-}" = "--app" ]; then FORCE_APP="${2:-}"; shift 2; fi

TARGET="${1:-}"
[ -n "$TARGET" ] || { echo "usage: codex-present.sh [--app <AppName>] <path-or-url>" >&2; exit 2; }
command -v open >/dev/null 2>&1 || { echo "codex-present: 'open' not found (macOS only)." >&2; exit 127; }

# Resolve the app to use.
if [ -n "$FORCE_APP" ]; then
  APP="$FORCE_APP"
else
  if is_url "$TARGET"; then key="url"; else key="$(lc_ext "$TARGET")"; fi
  # Resolve via object lookup (extension keys contain a dot, so a dotted `get`
  # path can't address them). Fall back to openers.default; null => bare `open`.
  openers_json="$("$CONFIG" get computerUse.openers 2>/dev/null || echo '{}')"
  APP="$(KEY="$key" printf '%s' "$openers_json" | KEY="$key" python3 -c \
    "import json,os,sys; d=json.load(sys.stdin); k=os.environ['KEY']; v=d.get(k); v=v if isinstance(v,str) else d.get('default'); print(v if isinstance(v,str) else '')")"
fi

# For files, make sure it exists and resolve to an absolute path.
if ! is_url "$TARGET"; then
  [ -e "$TARGET" ] || { echo "codex-present: no such file: $TARGET" >&2; exit 1; }
  case "$TARGET" in /*) ;; *) TARGET="$(cd "$(dirname "$TARGET")" && pwd)/$(basename "$TARGET")";; esac
fi

if [ -n "$APP" ]; then
  echo "codex-present: opening in $APP -> $TARGET"
  open -a "$APP" "$TARGET"
else
  echo "codex-present: opening with default app -> $TARGET"
  open "$TARGET"
fi
