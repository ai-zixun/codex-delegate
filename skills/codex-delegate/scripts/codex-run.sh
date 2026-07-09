#!/usr/bin/env bash
# codex-run.sh — thin, robust wrapper around `codex exec` for delegating work
# from Claude Code to OpenAI Codex (GPT-5).
#
# Usage:
#   codex-run.sh [options] "<prompt>"
#   codex-run.sh [options] -f <prompt-file>
#   echo "<prompt>" | codex-run.sh [options]
#
# Options:
#   --write              Allow Codex to edit files (sandbox: workspace-write).
#                        Default is read-only (review/diagnose/research).
#   --full-access        sandbox: danger-full-access (network + full disk).
#                        Use only when explicitly required; prefer --write.
#   --effort <level>     Reasoning effort: minimal|low|medium|high|xhigh.
#                        Default: medium.
#   --model <name>       Codex model override (e.g. gpt-5.3-codex-spark).
#   --timeout <seconds>  Hard timeout. Default: 900 (15 min).
#   --cd <dir>           Run Codex with <dir> as the workspace (default: cwd).
#   --resume             Resume the most recent Codex session in this repo.
#   -f <file>            Read the prompt from <file> instead of an argument.
#   --json               Emit Codex's JSON event stream instead of text.
#   -h, --help           Show this help.
#
# Exit codes:
#   0    Codex completed.
#   124  Timed out.
#   *    Codex's own non-zero exit (surfaced to caller).
#
# Design notes for the calling agent (Claude):
#   - Read-only is the default on purpose. Only pass --write when the task is a
#     well-specified implementation you intend to verify afterwards.
#   - stderr is captured separately and echoed on failure so a non-zero exit or
#     a stall never looks like a silent "no output".
#   - A filesystem-boundary preamble is prepended to every prompt so Codex does
#     not wander into Claude Code skill/plugin files.
set -uo pipefail

SANDBOX="read-only"
EFFORT="medium"
MODEL=""
TIMEOUT="900"
WORKDIR=""
RESUME=0
JSON=0
PROMPT_FILE=""
PROMPT=""

BOUNDARY='IMPORTANT: Do NOT read, execute, or modify any files under ~/.claude/, ~/.codex/, ~/.agents/, .claude/, or agents/. Those are agent/skill definitions for a different system and are not part of this task. Stay focused on the repository code relevant to the task below.'

usage() { sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case "$1" in
    --write)       SANDBOX="workspace-write"; shift ;;
    --full-access) SANDBOX="danger-full-access"; shift ;;
    --effort)      EFFORT="${2:-medium}"; shift 2 ;;
    --model)       MODEL="${2:-}"; shift 2 ;;
    --timeout)     TIMEOUT="${2:-900}"; shift 2 ;;
    --cd)          WORKDIR="${2:-}"; shift 2 ;;
    --resume)      RESUME=1; shift ;;
    --json)        JSON=1; shift ;;
    -f)            PROMPT_FILE="${2:-}"; shift 2 ;;
    -h|--help)     usage; exit 0 ;;
    --)            shift; PROMPT="$*"; break ;;
    -*)            echo "codex-run: unknown option: $1" >&2; exit 2 ;;
    *)             PROMPT="$1"; shift ;;
  esac
done

if ! command -v codex >/dev/null 2>&1; then
  echo "codex-run: the 'codex' CLI is not installed or not on PATH." >&2
  echo "Install: npm i -g @openai/codex  (or: brew install codex)  then run: codex login" >&2
  exit 127
fi

# Resolve the prompt: -f file, then stdin, then positional argument.
if [ -n "$PROMPT_FILE" ]; then
  [ -r "$PROMPT_FILE" ] || { echo "codex-run: cannot read prompt file: $PROMPT_FILE" >&2; exit 2; }
  PROMPT="$(cat "$PROMPT_FILE")"
elif [ -z "$PROMPT" ] && [ ! -t 0 ]; then
  PROMPT="$(cat)"
fi

if [ "$RESUME" -eq 0 ] && [ -z "${PROMPT// /}" ]; then
  echo "codex-run: no prompt provided (pass a string, -f <file>, or pipe stdin)." >&2
  exit 2
fi

FULL_PROMPT="$BOUNDARY

$PROMPT"

# Assemble argv.
ARGS=(exec)
[ "$RESUME" -eq 1 ] && ARGS+=(resume --last)
ARGS+=(-s "$SANDBOX")
ARGS+=(-c "model_reasoning_effort=\"$EFFORT\"")
[ -n "$MODEL" ] && ARGS+=(-m "$MODEL")
[ -n "$WORKDIR" ] && ARGS+=(--cd "$WORKDIR")
[ "$JSON" -eq 1 ] && ARGS+=(--json)
ARGS+=(--skip-git-repo-check)
ARGS+=("$FULL_PROMPT")

TMPERR="$(mktemp "${TMPDIR:-/tmp}/codex-run-err-XXXXXX")"
cleanup() { rm -f "$TMPERR" 2>/dev/null || true; }
trap cleanup EXIT

# Prefer coreutils `timeout`/`gtimeout` when available; otherwise run unbounded.
TIMEOUT_BIN=""
command -v timeout  >/dev/null 2>&1 && TIMEOUT_BIN="timeout"
command -v gtimeout >/dev/null 2>&1 && TIMEOUT_BIN="gtimeout"

if [ -n "$TIMEOUT_BIN" ]; then
  "$TIMEOUT_BIN" "$TIMEOUT" codex "${ARGS[@]}" < /dev/null 2>"$TMPERR"
else
  codex "${ARGS[@]}" < /dev/null 2>"$TMPERR"
fi
EXIT=$?

if [ "$EXIT" -eq 124 ]; then
  echo "" >&2
  echo "[codex-run] TIMED OUT after ${TIMEOUT}s. The task may be too large for one run —" >&2
  echo "            split it, lower --effort, or re-run with a bigger --timeout." >&2
elif [ "$EXIT" -ne 0 ]; then
  echo "" >&2
  echo "[codex-run] codex exited $EXIT. First stderr lines:" >&2
  head -20 "$TMPERR" 2>/dev/null | sed 's/^/  /' >&2 || true
fi

exit "$EXIT"
