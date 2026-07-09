---
name: codex-delegate
description: >-
  Route eligible coding work to OpenAI Codex (GPT-5) to save cost and time while
  Claude stays orchestrator and quality gate. Use PROACTIVELY when a task is
  well-specified and bulk, mechanical, repetitive, parallelizable, or long-running
  — codemods, boilerplate, migrations, wide find-and-replace refactors, test
  scaffolding, dependency bumps, sweeping a change across many files — or when an
  independent second-model review, diagnosis, or research pass adds value. Also
  triggers on explicit asks to delegate to Codex, offload work, or use Codex for a
  task. Do NOT use for interactive debugging, architecture and design judgment,
  nuanced or high-stakes code, or work that depends on rich in-conversation context.
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Edit
  - Write
---

# Codex Delegate

Route work Claude *could* do but Codex does **as well and more cheaply** over to the
`codex` CLI, then verify and integrate the result. Codex (GPT-5) runs at roughly half
the cost of a frontier Claude model, is highly token-efficient, and sustains long
unattended runs — so offloading rote, well-specified work conserves the expensive
Claude budget for what Claude is uniquely good at: judgment, interactive iteration,
and final quality.

**Claude stays the orchestrator.** You decide what to delegate, write the spec, and
own the quality gate on what comes back. Codex is a fast, cheap worker — not the
decision-maker.

## The core decision: DELEGATE or KEEP

Ask two questions:

1. **Can I specify "done" crisply enough that a fresh agent with no chat context could finish it?**
2. **Is the work bulk, mechanical, long-running, parallelizable, or would it benefit from an independent second model?**

If **both** are yes → **DELEGATE**. Otherwise → **KEEP** and do it yourself.

| DELEGATE to Codex ✅ | KEEP on Claude 🧠 |
|---|---|
| Well-specified implementation with a clear acceptance test | Ambiguous work needing back-and-forth to pin down |
| Bulk/repetitive edits across many files (codemods, renames, API migrations) | A single subtle change needing deep judgment |
| Boilerplate, scaffolding, config, fixture/test generation | Architecture & interface design decisions |
| Mechanical refactors that preserve behavior | Refactors requiring taste and repo-wide judgment |
| Long-running self-verifying tasks (make tests green, wire a pipeline) | Real-time interactive debugging / exploration |
| Terminal/CLI-heavy chores (build fixes, dependency bumps, tooling) | Anything gated on rich in-conversation context |
| **Independent** second-opinion review / diagnosis (cross-model diversity) | Final quality gate, user-facing writing, risky/irreversible ops |

When unsure, **keep it**. A bad delegation costs more than it saves: you pay to
specify the task, pay Codex to run, then pay Claude to verify and often redo.

> Grounding for these splits: Codex leads on long-horizon autonomy, token/cost
> efficiency, and terminal benchmarks; Claude leads on code-quality/cleanliness and
> repo-level refactor judgment. See `references/routing-rubric.md` for the full
> decision guide, worked examples, and the cost model.

## How to delegate

All delegation goes through the wrapper (read-only by default, robust timeout and
error surfacing, and a built-in filesystem-boundary preamble):

```bash
"${CLAUDE_PLUGIN_ROOT:-.}/skills/codex-delegate/scripts/codex-run.sh" [options] "<prompt>"
```

Pick the mode by what you need back:

- **Implement (write):** `codex-run.sh --write --effort high "<spec>"` — Codex edits
  files. You then review `git diff` as the quality gate before anything ships.
- **Review / diagnose / research (read-only):** default sandbox. Codex reads the repo
  and reports; it does not touch files.
- **Big/long task:** raise `--timeout` (default 900s) and consider `--effort high`.
  If it still times out, the task is too big for one run — **split it**.
- **Follow-up on the same thread:** `codex-run.sh --resume "<delta instruction>"`.
- **Cheaper/faster tier:** `--model gpt-5.3-codex-spark` for simpler mechanical jobs.

Run the wrapper with the `Bash` tool. For long jobs, run it in the background so you
can keep working, and collect the result when it finishes.

## Writing the Codex prompt

Codex responds to **tight contracts, not conversation**. State the task, what "done"
looks like, and the small set of rules that matter — using XML-tagged blocks. Every
prompt should carry a `<task>` and an output/completion contract; add verification,
grounding, and scope blocks per task type.

Minimal implementation prompt:

```xml
<task>
Migrate every call site of `oldApi(x, y)` to `newApi({x, y})` across src/. Preserve behavior.
</task>
<completeness_contract>
Update ALL call sites, not just the first few. Update imports. Leave the tree building.
</completeness_contract>
<verification_loop>
Before finishing, run the test suite (or typecheck) and confirm it passes. Fix what you broke.
</verification_loop>
<action_safety>
Keep changes scoped to this migration. No unrelated refactors, renames, or reformatting.
</action_safety>
```

Copy the closest starting point from `references/prompt-recipes.md` (diagnosis, narrow
fix, bulk implementation, review, research) and trim. Anti-pattern to avoid: vague
"take a look and let me know" prompts with no output contract — they waste the run.

## Handling what comes back

- **Verify before you trust.** For write tasks, read the `git diff` yourself — this is
  the whole point of keeping Claude as the gate. Confirm scope, correctness, and that
  nothing unrelated changed. Run the tests.
- **You may reject or redo.** If Codex's output is wrong or off-scope, say so plainly
  and either `--resume` with a correction or take it over yourself. Do not launder a
  bad Codex result into a confident answer.
- **For review/diagnosis output**, preserve Codex's findings, severity ordering, and
  evidence. Keep any "this is an inference / unverified" markers Codex made. Present it
  as an *independent* second opinion, and compare against your own view when useful.
- **Attribution.** Tell the user when work was done by Codex and what you verified —
  e.g. "Codex applied the migration across 14 files; I reviewed the diff and ran the
  tests (green)."
- **Never auto-apply fixes from a review.** If Codex reviewed code and suggested
  changes, surface them and let the user choose — don't silently implement them.

## Safety

- Read-only is the default. Only pass `--write` for tasks you intend to verify.
- The wrapper prepends a boundary keeping Codex out of `~/.claude/`, `~/.codex/`, and
  agent/skill definition files. Keep it.
- Delegating sends repository code to OpenAI. Don't delegate work involving secrets or
  code the user has said must not leave the environment. When in doubt, ask.
- One task per run. Split unrelated asks into separate delegations.

## Prerequisites

Needs the `codex` CLI installed and authenticated (`codex login`, or `OPENAI_API_KEY`).
The wrapper prints install/auth guidance if it's missing. See `references/setup.md`.
