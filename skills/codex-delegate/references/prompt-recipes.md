# Codex Prompt Recipes

Starting templates for Codex delegation prompts. Copy the closest one, fill the
`<task>`, and trim any block you don't need. Codex responds to **tight contracts, not
conversation** — state the job, what "done" means, and the few rules that matter, using
stable XML tags.

> Prompt-block vocabulary (`<task>`, `<completeness_contract>`, `<verification_loop>`,
> `<grounding_rules>`, `<action_safety>`, `<research_mode>`, …) is adapted from OpenAI's
> `codex` plugin `gpt-5-4-prompting` skill. See CREDITS in the repo README.

## Bulk / mechanical implementation (`--write`)

```xml
<task>
<!-- The concrete transformation and its scope, e.g.: -->
Migrate every call site of `oldApi(x, y)` to `newApi({ x, y })` across src/. Preserve behavior.
</task>

<completeness_contract>
Update ALL matching call sites, not just the first few, and their imports.
Do not stop at a partial pass. Leave the tree building.
</completeness_contract>

<verification_loop>
Before finishing, run the test suite (or typecheck) and confirm it passes.
If a check fails, fix it and re-run instead of reporting a broken draft.
</verification_loop>

<action_safety>
Keep changes scoped strictly to this task. No unrelated refactors, renames, reformatting, or cleanup.
</action_safety>

<structured_output_contract>
Return: 1) summary of what changed  2) files touched  3) verification run and its result  4) anything you could not do.
</structured_output_contract>
```

## Narrow fix (`--write`)

```xml
<task>
Implement the smallest safe fix for <the identified issue> in this repository. Preserve behavior elsewhere.
</task>

<completeness_contract>
Resolve the task fully. Do not stop after diagnosing without applying the fix.
</completeness_contract>

<verification_loop>
Verify the fix meets the requirement and the changed code is coherent. Run the relevant test if one exists.
</verification_loop>

<action_safety>
Tightly scoped changes only. Avoid unrelated edits.
</action_safety>
```

## Diagnosis (read-only)

```xml
<task>
Diagnose why <failing test/command/behavior> is breaking in this repository. Identify the most likely root cause.
</task>

<compact_output_contract>
Return: 1) most likely root cause  2) the evidence for it  3) the smallest safe next step.
</compact_output_contract>

<default_follow_through_policy>
Keep investigating until you can name the root cause confidently. Only stop for missing detail that changes the answer materially.
</default_follow_through_policy>

<grounding_rules>
Ground every claim in repo context or tool output. Label inferences as inferences, not facts.
</grounding_rules>

<missing_context_gating>
Do not guess missing repository facts. If required context is absent, state exactly what remains unknown.
</missing_context_gating>
```

## Independent review (read-only)

```xml
<task>
Review <this diff / these files> for the most likely correctness and regression issues. Use the provided repository context only.
</task>

<structured_output_contract>
Return findings ordered by severity, each with: the specific location, the evidence, and a brief suggested next step.
</structured_output_contract>

<grounding_rules>
Ground every finding in the code or tool output. Label inferences clearly. Do not invent issues to seem thorough.
</grounding_rules>

<dig_deeper_nudge>
After the first issue, check second-order failures: empty states, retries, stale state, rollback paths, concurrency.
</dig_deeper_nudge>
```

> After a review, present findings and STOP. Do not auto-apply fixes — let the user
> choose what to change.

## Research / recommendation (read-only)

```xml
<task>
Research the available options for <question> and recommend the best path.
</task>

<structured_output_contract>
Return: 1) observed facts  2) reasoned recommendation  3) tradeoffs  4) open questions.
</structured_output_contract>

<research_mode>
Separate observed facts, reasoned inferences, and open questions. Breadth first, then go deep only where evidence changes the recommendation.
</research_mode>

<citation_rules>
Back important claims with explicit references to the sources you inspected. Prefer primary sources.
</citation_rules>
```

## Anti-patterns

- **No output contract:** "Investigate and report back." → say exactly what shape to return.
- **Vague framing:** "Take a look and tell me what you think." → name the job and the done-state.
- **Mixing jobs:** "Migrate this, fix the bug, update docs, suggest a roadmap." → one task per run; split the rest.
- **Asking for more thinking instead of a better contract:** "Think harder." → add a `<verification_loop>` instead.
- **Unsupported certainty:** "Tell me exactly why prod failed." → add `<grounding_rules>` so inferences are labeled.
