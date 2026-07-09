#!/usr/bin/env bash
# codex-learn.sh — persist routing corrections and (optionally) log decisions, so
# Claude's autonomous routing improves over time.
#
# Learned rules are natural-language strings merged into `customRules` by
# codex-config.sh (defaults < user < project < learned). They live in a dedicated
# file so hand-authored config is never rewritten.
#
# Usage:
#   codex-learn.sh rule "Never delegate anything under src/payments/."   # persist a rule
#   codex-learn.sh rules                                                  # list learned rules
#   codex-learn.sh forget <index>                                        # remove rule N (1-based)
#   codex-learn.sh log '{"task":"...","decision":"delegate","reason":"..."}'  # append a decision
#
# Paths (override with env):
#   rules : ~/.claude/codex-delegate/learned-rules.json   ($CODEX_DELEGATE_LEARNED)
#   log   : ~/.claude/codex-delegate/decisions.jsonl      ($CODEX_DELEGATE_DECISION_LOG)
set -uo pipefail

RULES_FILE="${CODEX_DELEGATE_LEARNED:-$HOME/.claude/codex-delegate/learned-rules.json}"
LOG_FILE="${CODEX_DELEGATE_DECISION_LOG:-$HOME/.claude/codex-delegate/decisions.jsonl}"
CMD="${1:-}"; shift || true

case "$CMD" in
  rule)
    RULE="${1:-}"; [ -n "$RULE" ] || { echo "usage: codex-learn.sh rule \"<text>\"" >&2; exit 2; }
    RULES_FILE="$RULES_FILE" RULE="$RULE" python3 - <<'PY'
import json, os
p = os.path.expanduser(os.environ["RULES_FILE"]); rule = os.environ["RULE"].strip()
os.makedirs(os.path.dirname(p), exist_ok=True)
try:
    with open(p) as f: rules = json.load(f)
    if not isinstance(rules, list): rules = rules.get("rules", [])
except Exception:
    rules = []
if rule and rule not in rules:
    rules.append(rule)
    with open(p, "w") as f: json.dump(rules, f, indent=2)
    print(f"learned: {rule}")
else:
    print("already known; no change")
PY
    ;;
  rules)
    RULES_FILE="$RULES_FILE" python3 - <<'PY'
import json, os
p = os.path.expanduser(os.environ["RULES_FILE"])
try:
    with open(p) as f: rules = json.load(f)
    if not isinstance(rules, list): rules = rules.get("rules", [])
except Exception:
    rules = []
if not rules: print("(no learned rules)")
for i, r in enumerate(rules, 1): print(f"{i}. {r}")
PY
    ;;
  forget)
    IDX="${1:-}"; [ -n "$IDX" ] || { echo "usage: codex-learn.sh forget <index>" >&2; exit 2; }
    RULES_FILE="$RULES_FILE" IDX="$IDX" python3 - <<'PY'
import json, os, sys
p = os.path.expanduser(os.environ["RULES_FILE"])
try:
    with open(p) as f: rules = json.load(f)
    if not isinstance(rules, list): rules = rules.get("rules", [])
except Exception:
    rules = []
try:
    i = int(os.environ["IDX"])
except ValueError:
    sys.stderr.write("index must be a number\n"); sys.exit(2)
if 1 <= i <= len(rules):
    removed = rules.pop(i - 1)
    with open(p, "w") as f: json.dump(rules, f, indent=2)
    print(f"forgot: {removed}")
else:
    sys.stderr.write("index out of range\n"); sys.exit(1)
PY
    ;;
  log)
    ENTRY="${1:-}"; [ -n "$ENTRY" ] || { echo "usage: codex-learn.sh log '<json>'" >&2; exit 2; }
    mkdir -p "$(dirname "$LOG_FILE")"
    # Validate JSON and stamp nothing time-based here (caller may include ts).
    if printf '%s' "$ENTRY" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null; then
      printf '%s\n' "$ENTRY" >> "$LOG_FILE"
      echo "logged."
    else
      echo "codex-learn: log entry is not valid JSON; not written." >&2; exit 2
    fi
    ;;
  ""|-h|--help)
    sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//' ;;
  *)
    echo "codex-learn: unknown command '$CMD'" >&2; exit 2 ;;
esac
