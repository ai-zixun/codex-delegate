# codex-delegate

[![skills.sh](https://skills.sh/b/ai-zixun/codex-delegate)](https://skills.sh/ai-zixun/codex-delegate)

A [Claude Code](https://claude.com/claude-code) skill/plugin that lets Claude **auto-route
eligible coding work to [OpenAI Codex](https://github.com/openai/codex) (GPT-5)** — to
save cost and time — while Claude stays the orchestrator and quality gate.

Codex runs at roughly **half the cost** of a frontier Claude model on comparable
well-scoped work, is very token-efficient, and sustains long unattended runs. So if you
have Codex budget to spend, offloading rote, well-specified work there conserves your
Claude budget for what Claude is best at: judgment, interactive iteration, and final
quality.

## What it does

When Claude hits work that is **well-specified** *and* **bulk / mechanical / long-running
/ parallelizable** (codemods, migrations, boilerplate, wide refactors, test scaffolding,
dependency bumps) — or that benefits from an **independent second-model** review or
diagnosis — this skill has Claude:

1. **Decide** with a two-gate rubric whether the task is worth delegating at all.
2. **Delegate** it to the `codex` CLI with a tight, contract-style prompt.
3. **Verify** what comes back (read the diff, run the tests) — Claude owns the gate.
4. **Integrate & attribute** — reports what Codex did and what Claude checked.

It deliberately **keeps** interactive debugging, architecture/design judgment, nuanced or
high-stakes code, and context-heavy work on Claude, where quality wins.

### How it's different from the existing Codex tools

| Tool | Trigger | Role |
|---|---|---|
| gstack `/codex` | manual (`review` / `challenge` / `consult`) | user asks for a second opinion |
| OpenAI `codex-rescue` | reactive (Claude is stuck) | rescue a blocked task |
| **codex-delegate** | **proactive, cost-aware** | **route rote work off Claude to save budget** |

## Install

Requires the Codex CLI, installed and authenticated:

```bash
npm install -g @openai/codex   # or: brew install codex
codex login                    # or export OPENAI_API_KEY=sk-...
```

Then install the skill. Pick one:

**Via [skills.sh](https://www.skills.sh) (any agent — Claude Code, Codex, OpenClaw):**

```bash
npx skills add ai-zixun/codex-delegate
```

`npx skills add` auto-detects your installed agents and drops the skill into each one's
skills directory (e.g. `~/.claude/skills/codex-delegate/`, `~/.codex/skills/…`).

**As a Claude Code plugin (adds the `/codex-delegate` command too):**

```bash
/plugin marketplace add ai-zixun/codex-delegate
/plugin install codex-delegate@codex-delegate
```

Or drop the skill straight into a project or your home config:

```bash
cp -r skills/codex-delegate ~/.claude/skills/          # user-wide
# or
cp -r skills/codex-delegate <your-repo>/.claude/skills/ # per-project
```

See [`skills/codex-delegate/references/setup.md`](skills/codex-delegate/references/setup.md)
for details and troubleshooting.

## Usage

**Automatic** — Claude invokes the skill on its own when a task matches (e.g. "migrate
every call site of `oldApi` to `newApi` across the repo"). It runs the DELEGATE/KEEP
check, and if it delegates, verifies the result before reporting back.

**Manual** — force a delegation with the slash command:

```
/codex-delegate --write --effort high  Rename UserDTO to UserRecord everywhere and fix imports; keep tests green.
```

**Direct** — the wrapper is usable on its own:

```bash
skills/codex-delegate/scripts/codex-run.sh --write --effort high "…tight task spec…"
skills/codex-delegate/scripts/codex-run.sh "Review the working-tree diff for regressions"  # read-only
```

## When it delegates vs keeps

Delegate only when **both** gates pass:

1. **Specifiable** — a fresh agent with no chat context could finish it from a written spec.
2. **Worth it** — the work is bulk, mechanical, long-running, parallelizable, or wants a
   second model. (Small edits cost more to specify + verify than to just do.)

Full guide, worked examples, and the cost model:
[`skills/codex-delegate/references/routing-rubric.md`](skills/codex-delegate/references/routing-rubric.md).

## Layout

```
.claude-plugin/plugin.json         # plugin manifest (declares the skill)
.claude-plugin/marketplace.json    # single-plugin marketplace (for `/plugin marketplace add`)
.github/workflows/release.yml      # tags a GitHub Release when VERSION changes
commands/codex-delegate.md         # manual /codex-delegate slash command
skills/codex-delegate/
  SKILL.md                         # the router: DELEGATE/KEEP decision + mechanics
  scripts/codex-run.sh             # robust `codex exec` wrapper (read-only by default)
  references/
    routing-rubric.md              # full decision guide + cost model + examples
    prompt-recipes.md              # contract-style Codex prompt templates
    setup.md                       # install / auth / troubleshooting
CHANGELOG.md · VERSION             # release metadata (drives the release workflow)
```

## Safety

- Read-only is the default; `--write` is opt-in and always followed by Claude's review.
- The wrapper prepends a boundary keeping Codex out of `~/.claude/`, `~/.codex/`, and
  agent/skill definition files.
- Delegating sends repository code to OpenAI. Don't delegate work involving secrets or
  code that must not leave your environment.

## Credits

The contract-style prompt vocabulary (`<task>`, `<completeness_contract>`,
`<verification_loop>`, `<grounding_rules>`, …) is adapted from OpenAI's
[`codex` Claude Code plugin](https://github.com/openai/codex-plugin-cc)
(`gpt-5-4-prompting` skill). The routing framing draws on lessons from the gstack
`/codex` skill. This project is an independent, open-source complement to both.

## License

[MIT](LICENSE).
