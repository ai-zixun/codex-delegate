#!/usr/bin/env bash
# codex-config.sh — resolve the effective codex-delegate config.
#
# Merge order (later wins): built-in defaults < user config < project config.
#   user    : ~/.claude/codex-delegate.config.json   (override: $CODEX_DELEGATE_USER_CONFIG)
#   project : <git-root>/codex-delegate.config.json  (fallback: ./codex-delegate.config.json;
#             override: $CODEX_DELEGATE_CONFIG)
#
# Usage:
#   codex-config.sh                 # print the merged config as JSON
#   codex-config.sh get <dotted.key># print one value (empty + exit 1 if unset/null)
#   codex-config.sh sources         # list which config files were found
#
# Deep-merges objects; scalars and arrays are replaced wholesale by the higher layer.
# Pure Python 3 (stdlib) — no jq required.
set -uo pipefail

USER_CFG="${CODEX_DELEGATE_USER_CONFIG:-$HOME/.claude/codex-delegate.config.json}"
if [ -n "${CODEX_DELEGATE_CONFIG:-}" ]; then
  PROJ_CFG="$CODEX_DELEGATE_CONFIG"
else
  _root="$(git rev-parse --show-toplevel 2>/dev/null)"
  if [ -n "$_root" ] && [ -f "$_root/codex-delegate.config.json" ]; then
    PROJ_CFG="$_root/codex-delegate.config.json"
  else
    PROJ_CFG="./codex-delegate.config.json"
  fi
fi

CMD="${1:-print}"
KEY="${2:-}"

USER_CFG="$USER_CFG" PROJ_CFG="$PROJ_CFG" CMD="$CMD" KEY="$KEY" python3 - <<'PY'
import json, os, sys

DEFAULTS = {
    "enabled": True,
    "autoRoute": True,
    "codexDefaults": {
        "effort": "medium",
        "model": None,
        "writeByDefault": False,
        "timeoutSeconds": 900,
    },
    # Per-category policy: "delegate" | "keep" | "ask"
    "routing": {
        "bulkMechanical": "delegate",
        "migrations": "delegate",
        "boilerplate": "delegate",
        "tests": "delegate",
        "review": "delegate",
        "diagnosis": "delegate",
        "research": "delegate",
        "computerUse": "delegate",
        "architecture": "keep",
        "interactiveDebug": "keep",
        "highStakes": "keep",
    },
    # Free-form natural-language rules the agent should honor when routing.
    "customRules": [],
    "computerUse": {
        "execution": "hybrid",        # hybrid | codex | inline
        "autoPresent": "viewable",    # viewable | always | manual
        "viewableExtensions": [
            ".html", ".htm", ".pdf", ".md", ".png", ".jpg", ".jpeg",
            ".gif", ".svg", ".docx", ".pages", ".key", ".numbers", ".csv",
        ],
        "openers": {
            "url": "Google Chrome",
            ".html": "Google Chrome",
            ".htm": "Google Chrome",
            ".svg": "Google Chrome",
            ".pdf": "Preview",
            ".png": "Preview",
            ".jpg": "Preview",
            ".jpeg": "Preview",
            ".gif": "Preview",
            ".docx": "Pages",
            ".pages": "Pages",
            "default": None,          # None => macOS default app via `open`
        },
        "allowAppleScript": False,    # richer osascript control (needs macOS Automation perm)
    },
}

def deep_merge(base, over):
    if not isinstance(base, dict) or not isinstance(over, dict):
        return over
    out = dict(base)
    for k, v in over.items():
        out[k] = deep_merge(base[k], v) if (k in base and isinstance(base[k], dict) and isinstance(v, dict)) else v
    return out

def load(path):
    try:
        with open(os.path.expanduser(path)) as f:
            return json.load(f), None
    except FileNotFoundError:
        return {}, None
    except Exception as e:
        return {}, f"{path}: {e}"

user_path, proj_path = os.environ["USER_CFG"], os.environ["PROJ_CFG"]
user_cfg, uerr = load(user_path)
proj_cfg, perr = load(proj_path)
for err in (uerr, perr):
    if err:
        sys.stderr.write(f"codex-config: ignoring invalid config {err}\n")

merged = deep_merge(deep_merge(DEFAULTS, user_cfg), proj_cfg)

cmd, key = os.environ["CMD"], os.environ["KEY"]
if cmd == "print":
    print(json.dumps(merged, indent=2))
elif cmd == "sources":
    print(f"defaults: (built-in)")
    print(f"user:     {os.path.expanduser(user_path)} {'[found]' if os.path.exists(os.path.expanduser(user_path)) else '[none]'}")
    print(f"project:  {os.path.expanduser(proj_path)} {'[found]' if os.path.exists(os.path.expanduser(proj_path)) else '[none]'}")
elif cmd == "get":
    if not key:
        sys.stderr.write("codex-config get: missing key\n"); sys.exit(2)
    cur = merged
    for part in key.split("."):
        if isinstance(cur, dict) and part in cur:
            cur = cur[part]
        else:
            sys.exit(1)
    if cur is None:
        sys.exit(1)
    print(cur if isinstance(cur, str) else json.dumps(cur))
else:
    sys.stderr.write(f"codex-config: unknown command '{cmd}'\n"); sys.exit(2)
PY
