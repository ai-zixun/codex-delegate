# CLAUDE.md

Project instructions for Claude Code when working in this repo. The **Skill routing**
block below is also a copy-paste template: drop it into your *own* project's `CLAUDE.md`
to make Claude auto-route eligible work to Codex there.

## Skill routing

When a task is **well-specified** *and* **bulk / mechanical / long-running /
parallelizable** — codemods, wide find-and-replace refactors, API migrations,
boilerplate, test/fixture scaffolding, dependency bumps, sweeping one change across many
files — or when an **independent second-model** review or diagnosis would add value,
invoke the **`codex-delegate`** skill and route the work to OpenAI Codex instead of doing
it inline. Codex runs at roughly half the cost and is token-lean, so this conserves the
Claude budget for judgment and interactive work.

Apply the skill's two-gate test first:

1. **Specifiable** — could a fresh agent with no chat context finish it from a written
   spec plus the repo?
2. **Worth it** — is it bulk / mechanical / long-running / parallelizable, or does it
   want a second model?

Delegate only when **both** pass. **Keep on Claude** (do not delegate): interactive
debugging, architecture/interface design, nuanced or high-stakes code, small edits, and
anything gated on rich in-conversation context. When unsure, keep it.

After a delegation, Claude owns the quality gate: review the `git diff`, run the tests,
and report what Codex did and what was verified. Never auto-apply fixes that came out of
a Codex *review* — surface them and let the user choose.

## Working conventions (this repo)

- `main` is protected (PR required, no force-push, no deletion). Do not commit or push to
  `main` directly — work on a branch (default working branch: `workspace-mini`) and open
  a PR.
- The skill lives in `skills/codex-delegate/`; the `codex exec` wrapper is
  `skills/codex-delegate/scripts/codex-run.sh` (read-only by default, `--write` opt-in).
- Keep `README.md`, `SKILL.md`, and the `references/` docs in sync when behavior changes.
