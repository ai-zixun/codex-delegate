# Setup

`codex-delegate` shells out to the OpenAI **Codex CLI**. Install and authenticate it
once.

## Install the Codex CLI

```bash
npm install -g @openai/codex
# or
brew install codex
```

Verify: `codex --version` (this skill was built against `codex-cli` 0.143.x; the
`codex exec` flags it uses — `-s/--sandbox`, `-c model_reasoning_effort`, `-m/--model`,
`--cd`, `--skip-git-repo-check`, `--json` — are stable across recent versions).

## Authenticate

```bash
codex login          # opens a browser for ChatGPT / OpenAI auth
```

Or set an API key in the environment Claude Code runs in:

```bash
export OPENAI_API_KEY=sk-...
```

Confirm it works:

```bash
codex exec -s read-only "print the current working directory and stop" --skip-git-repo-check
```

## Cost note

Delegation spends **OpenAI/Codex** budget, not Claude budget — that's the point. Codex
runs at roughly half the cost of a frontier Claude model on comparable well-scoped work
and is token-lean, so routing bulk/mechanical work here conserves the Claude budget for
judgment and interactive work. Monitor spend on both sides via each provider's usage
dashboard.

## Troubleshooting

- **`codex: command not found`** — not installed or not on PATH. Re-run the install
  step. The wrapper prints this guidance and exits 127.
- **Auth / 401 errors** — run `codex login` again, or check `OPENAI_API_KEY` is present
  in the shell Claude Code spawns.
- **Timeouts (exit 124)** — the task is too big for one run. Lower `--effort`, raise
  `--timeout`, or split the task. See the escalation ladder in `routing-rubric.md`.
- **Codex edited the wrong files / went off-scope** — you ran with `--write` and a loose
  prompt. Tighten `<action_safety>` and `<task>` scope; reject the diff and re-run.
- **`400 ... tools cannot be used with reasoning.effort 'minimal'`** — your Codex config
  has `web_search`/`image_gen` enabled, which conflict with `--effort minimal`. Use
  `--effort low` (or higher) instead, or disable those tools in `~/.codex/config.toml`.
  The skill never selects `minimal` on its own; the default effort is `medium`.
