# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/), and the project adheres to
[Semantic Versioning](https://semver.org/).

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
