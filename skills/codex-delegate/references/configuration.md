# Configuration

`codex-delegate` reads an optional JSON config so you control **what gets routed to
Codex** and **how finished work is presented** (opening Chrome/Pages/etc.). Everything
has a sensible built-in default; a config only overrides what you set.

## Where config lives

Merged later-wins: **built-in defaults → user config → project config** (project wins).

| Layer | Path | Override env |
|---|---|---|
| User (global) | `~/.claude/codex-delegate.config.json` | `CODEX_DELEGATE_USER_CONFIG` |
| Project | `<git-root>/codex-delegate.config.json` (else `./codex-delegate.config.json`) | `CODEX_DELEGATE_CONFIG` |

Objects deep-merge; scalars and arrays are replaced wholesale by the higher layer.
Start from [`codex-delegate.config.example.json`](../../../codex-delegate.config.example.json).

Resolve it with the helper (used by the skill; handy for debugging too):

```bash
scripts/codex-config.sh            # print the effective merged config
scripts/codex-config.sh sources    # show which files were found
scripts/codex-config.sh get computerUse.autoPresent   # read one dotted key
```

## Fields

### Top level

- **`enabled`** (bool, default `true`) — master switch. `false` disables all routing;
  Claude does everything itself.
- **`autoRoute`** (bool, default `true`) — when `true`, Claude routes proactively per
  the rules below. When `false`, Claude only delegates when you explicitly ask.

### `codexDefaults`

Defaults applied to delegated Codex runs (map to `codex-run.sh` flags):

- **`effort`**: `minimal|low|medium|high|xhigh` (default `medium`).
- **`model`**: Codex model, or `null` for the CLI default.
- **`writeByDefault`** (bool, default `false`): if `true`, implementation delegations
  pass `--write`. Read-only tasks (review/diagnose/research) stay read-only regardless.
- **`timeoutSeconds`** (default `900`).

### `routing`

Per-category policy — one of `"delegate"`, `"keep"`, or `"ask"`:

| Category | Default | Meaning |
|---|---|---|
| `bulkMechanical` | delegate | codemods, wide renames, repetitive edits |
| `migrations` | delegate | API/framework/version migrations |
| `boilerplate` | delegate | scaffolding, config, fixtures |
| `tests` | delegate | test/fixture generation |
| `review` | delegate | independent second-model review (read-only) |
| `diagnosis` | delegate | root-cause investigation (read-only) |
| `research` | delegate | options/recommendation research (read-only) |
| `computerUse` | delegate | opening apps to present results (see below) |
| `architecture` | keep | design/interface judgment |
| `interactiveDebug` | keep | real-time exploratory debugging |
| `highStakes` | keep | nuanced or risky/irreversible code |

- `delegate` → route to Codex when the two-gate test passes.
- `keep` → Claude always handles it.
- `ask` → Claude asks you before delegating.

### `customRules`

A list of free-form natural-language rules Claude honors alongside the categories, e.g.:

```json
"customRules": [
  "When I finish building a web page or HTML artifact, open it in Chrome so I can see it.",
  "Never delegate anything under src/payments/."
]
```

These are read by Claude, so plain English is fine. They can express routing
preferences *and* presentation preferences.

### `computerUse`

Controls the "present results" capability — opening Chrome/Pages/other Mac apps to
show you finished work.

- **`execution`**: `hybrid` (default) | `codex` | `inline`.
  - `hybrid` — if the app-opening is part of a task already delegated to Codex, Codex
    does it (full-access sandbox). A standalone "just show me" runs inline via `open`.
  - `codex` — always delegate the open to Codex (`codex-run.sh --full-access`).
  - `inline` — always run `open` directly from the skill (fastest, most reliable).
- **`autoPresent`**: `viewable` (default) | `always` | `manual`.
  - `viewable` — auto-open only when the work produced a viewable artifact (an
    extension in `viewableExtensions`, or a served URL).
  - `always` — attempt to present after every completed delegation.
  - `manual` — never auto-open; only on explicit request.
- **`viewableExtensions`**: file types that count as "viewable" for `autoPresent`.
- **`openers`**: map of `url` / `.ext` → macOS app name. `default` (`null`) opens with
  the system default app via bare `open`. Examples: `".html": "Google Chrome"`,
  `".pdf": "Preview"`, `".docx": "Pages"`.
- **`allowAppleScript`** (bool, default `false`): gate for richer GUI control via
  `osascript` (clicking, typing, arranging windows). Bare `open -a` needs no special
  permission; AppleScript automation requires granting macOS **Automation/Accessibility**
  permission once. Leave `false` unless you want that.

## macOS permission note

`open -a "Google Chrome" file.html` and `open -a Pages doc.docx` just *launch* an app
and need no special permission. Only scripted control of an already-running app (via
`osascript`, gated behind `allowAppleScript`) triggers the one-time macOS Automation
prompt. This capability is macOS-only; on other platforms presenting is a no-op.
