# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/), and the project adheres to
[Semantic Versioning](https://semver.org/).

## [0.3.0] - 2026-07-09

### Added

- **Autonomous routing decision protocol** — in the default `decisionMode: auto`, Claude
  decides each task itself: resolve config → classify + category guardrail → two-gate
  test + cost model → risk assessment → act. Config categories are a hard guardrail
  (`keep` is never overridden); judgment fills the gaps.
- **Risk-aware autonomy** (`riskPolicy`): `autoDelegate` = `always` | `lowRisk` (default)
  | `confirm`. `lowRisk` auto-delegates confident low-risk work (read-only reviews,
  scoped writes) and asks first for high-risk work — writes over `maxAutoFiles`, anything
  under `protectedPaths`, or irreversible actions.
- **Learning from corrections** (`learning`): `scripts/codex-learn.sh` persists routing
  overrides as natural-language rules (`~/.claude/codex-delegate/learned-rules.json`,
  merged into `customRules` on the next resolve — hand-authored config is never
  rewritten), with `rules`/`forget` management and an optional `logDecisions` decision log.
- `decisionMode` (`auto` | `config` | `manual`) config field.

## [0.2.0] - 2026-07-09

### Added

- **Configurable routing** via an optional JSON config, merged
  defaults → user (`~/.claude/codex-delegate.config.json`) → project
  (`<repo>/codex-delegate.config.json`, project wins):
  - `routing.<category>` policy (`delegate` | `keep` | `ask`) per kind of work.
  - `customRules` — plain-English routing/presentation preferences.
  - `codexDefaults` — default effort, model, write mode, timeout.
  - `scripts/codex-config.sh` resolves the merged config (no `jq` dependency).
  - `codex-delegate.config.example.json` starter and `references/configuration.md`.
- **Computer use — present results in Mac apps.** Open finished work in the app you
  configure (Chrome for pages, Preview for PDFs, Pages for docs, …):
  - `computerUse` config: `execution` (hybrid/codex/inline), `autoPresent`
    (viewable/always/manual), `openers`, `allowAppleScript`.
  - `scripts/codex-present.sh` opens files/URLs and gates auto-present on viewable
    artifacts. Hybrid execution: Codex presents its own delegated output; standalone
    "show me" runs inline.

## [0.1.0] - 2026-07-09

Initial release.

### Added

- `codex-delegate` skill: a cost-aware router that hands well-specified,
  bulk/mechanical/long-running work from Claude Code to OpenAI Codex (GPT-5),
  keeping Claude as orchestrator and quality gate.
- Two-gate DELEGATE/KEEP decision rubric with worked examples and a cost model
  (`references/routing-rubric.md`).
- `scripts/codex-run.sh`: robust `codex exec` wrapper — read-only by default,
  `--write`/`--effort`/`--model`/`--timeout`/`--resume` options, timeout and
  error surfacing, and a filesystem-boundary preamble.
- Contract-style Codex prompt recipes (`references/prompt-recipes.md`) and setup
  guide (`references/setup.md`).
- `/codex-delegate` slash command for manual delegation.
- Claude Code plugin manifests (`.claude-plugin/plugin.json`,
  `marketplace.json`) and skills.sh compatibility (`npx skills add`).
