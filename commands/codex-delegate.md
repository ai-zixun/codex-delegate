---
description: Delegate a well-specified coding task to OpenAI Codex (GPT-5) to save cost, then verify and integrate the result
argument-hint: "[--write] [--effort low|medium|high|xhigh] [--model <name>] <what Codex should do>"
allowed-tools: Bash, Read, Grep, Glob, Edit, Write, Skill
---

Load and follow the `codex-delegate` skill to handle this request.

Apply the skill's DELEGATE / KEEP decision first:
- If the task passes both gates (specifiable + worth delegating), delegate it to Codex
  via `scripts/codex-run.sh`, then verify the result (read the diff, run tests) and
  report what Codex did and what you checked.
- If it does not pass — e.g. it's ambiguous, small, or judgment-heavy — say so briefly
  and either do it yourself or ask a clarifying question, rather than forcing a
  delegation.

Honor any flags the user passed (`--write`, `--effort`, `--model`) when building the
`codex-run.sh` invocation.

Request:
$ARGUMENTS
