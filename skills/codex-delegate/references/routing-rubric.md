# Routing Rubric

The full decision guide behind the DELEGATE / KEEP table in `SKILL.md`. Read this when
a routing call is non-obvious.

## Why route at all

The two agents have measurably different shapes:

**Codex (GPT-5) is strongest at:**
- **Long-horizon autonomy** — sustains multi-hour unattended runs, iterating and
  self-correcting against tests without handholding.
- **Cost & token efficiency** — roughly half the cost of a frontier Claude model for
  comparable output on well-scoped work; very token-lean.
- **Terminal / CLI work** — leads terminal-oriented benchmarks; strong at build fixes,
  tooling, dependency management, shell-driven chores.
- **Batch / parallel throughput** — good at grinding the same transformation across
  many files or running as an independent worker on a queue of well-defined tasks.

**Claude is strongest at:**
- **Code quality & cleanliness** — blind reviewers prefer Claude's output the majority
  of the time; better taste on naming, structure, and idiom.
- **Repo-level refactor judgment** and architecture/interface design.
- **Interactive, exploratory work** — real-time debugging, hypothesis-driven
  investigation, iterating with a human in the loop.
- **Context-rich work** — tasks that lean on everything established earlier in the
  conversation, which is expensive to serialize into a fresh Codex prompt.

Routing is about playing each to its strength while spending the cheaper token budget
first.

## The two-gate test

Delegate only when **both** gates pass:

**Gate 1 — Specifiability.** Could a competent agent with *zero* chat context finish
this from a written spec plus the repo? If you can write a crisp acceptance criterion
("all call sites migrated, tests green"), it passes. If "done" only exists in your head
or emerges through iteration, it fails.

**Gate 2 — Leverage.** Does delegating actually save? It does when the work is bulk,
mechanical, long-running, parallelizable, or benefits from an independent second model.
It does *not* when it's a small change you'd finish in a couple of tool calls — the
overhead of specifying + verifying exceeds the work itself.

## The cost model (why "when unsure, keep it")

Delegation is not free. Total cost of a delegation ≈

```
specify (Claude tokens) + Codex run (cheap) + verify/integrate (Claude tokens) + P(redo) × redo
```

It wins when the Codex-run portion would otherwise have been a **large** Claude cost
(many files, long run) and P(redo) is low (crisp spec, self-verifying task). It loses
on small tasks, fuzzy specs, or high-judgment work where P(redo) is high — there you
pay the specify+verify tax twice and get nothing.

Rule of thumb: **delegate work measured in "many files" or "many minutes," keep work
measured in "a few edits."**

## Worked examples

**DELEGATE:**
- "Rename `UserDTO` → `UserRecord` everywhere and update imports." → mechanical, wide,
  behavior-preserving, trivially verifiable. `--write`.
- "Generate table-driven unit tests for every exported function in `parser/`." →
  bulk scaffolding with a clear shape. `--write --effort high`.
- "Bump the framework major version and fix the resulting build/type errors until it
  compiles and tests pass." → long-horizon, self-verifying, terminal-heavy. `--write`.
- "Independently review this diff for correctness and regressions." → cross-model
  second opinion; read-only. Present as an independent view.
- "Diagnose why `test_checkout_flow` is flaky and report the root cause." → bounded
  read-only investigation you'll act on.

**KEEP:**
- "Something feels off in the auth flow, help me figure out what." → exploratory, no
  spec yet. Investigate interactively first; *then* maybe delegate a narrow fix.
- "Design the caching layer's public interface." → architecture judgment.
- "Fix this one off-by-one in the pagination cursor." → a few edits; specifying it
  costs more than doing it.
- "Refactor this module to be cleaner." → taste-dependent; "cleaner" isn't a spec.
- Any change threaded through decisions made across this conversation.

## Escalation ladder

Prefer tightening the delegation over throwing more compute at it:

1. Sharpen the prompt contract (clearer `<task>`, explicit `<completeness_contract>`).
2. Add a `<verification_loop>` so Codex checks its own work before returning.
3. Only then raise `--effort` (medium → high → xhigh).
4. If it still fails or times out, the task is too big or too fuzzy — **split it** into
   smaller delegations, or take it back to Claude.

## Delegating in parallel

Codex shines as a batch worker. For N independent, well-specified chunks, launch
several background `codex-run.sh` calls (each scoped to its own files to avoid write
conflicts) and collect results as they finish. Keep chunks non-overlapping on the
filesystem. This is where the cost/throughput advantage compounds — but only for
genuinely independent, crisply-specified work.
