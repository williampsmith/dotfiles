# Feature Planning

Create a new plan in `specs/*.md` to implement the `Feature` using the exact specified markdown `Plan Format`. Follow the `Instructions`, and use the `Relevant Files` to focus on the right files.

## Instructions

- You're writing a plan to implement a net new feature that will add value to the application.
- Create the plan in a `specs/*.md` file. Name it appropriately based on the `Feature`.
- Use the `Plan Format` below to create the plan.
- Research the codebase to understand existing patterns, architecture, and conventions before planning the feature.
- IMPORTANT: Replace every <placeholder> in the `Plan Format` with the requested value. Add as much detail as needed to implement the feature successfully.
- Use your reasoning model: THINK HARD about the feature requirements, design, and implementation approach.
- Follow existing patterns and conventions in the codebase. Don't reinvent the wheel.
- Design for extensibility and maintainability.
- Analyze how the work should be executed and fill the `Execution Strategy` section on two axes — **topology** (how it decomposes) and **assurance** (what multi-agent structure, if any, raises confidence: e.g. adversarial verification of a risky change, or a tournament among competing approaches). Default to the cheapest shape (`single` topology, `none` assurance) and escalate only with a concrete payoff, justified in the rationale.
- If you need a new dependency, add it with the project's package manager and report it in the `Notes` section.
- Respect requested files in the `Relevant Files` section.
- Start your research by reading `README.md` and `CLAUDE.md`.

## Relevant Files

Focus on the files and directories most relevant to the feature. Start from the entry points and the modules they touch; ignore generated output, dependencies, and unrelated areas.

## Plan Format

```md
# Feature: <feature name>

## Feature Description
<describe the feature in detail, including its purpose and value to users>

## User Story
As a <type of user>
I want to <action/goal>
So that <benefit/value>

## Problem Statement
<clearly define the specific problem or opportunity this feature addresses>

## Solution Statement
<describe the proposed solution approach and how it solves the problem>

## Relevant Files
Use these files to implement the feature:

<find and list the files that are relevant to the feature, describing why they are relevant in bullet points. If there are new files that need to be created, list them in an h3 'New Files' section.>

## Implementation Plan
### Phase 1: Foundation
<describe the foundational work needed before implementing the main feature>

### Phase 2: Core Implementation
<describe the main implementation work for the feature>

### Phase 3: Integration
<describe how the feature will integrate with existing functionality>

## Step by Step Tasks
IMPORTANT: Execute every step in order, top to bottom.

<list step by step tasks as h3 headers plus bullet points. Order matters: start with the foundational shared changes, then move on to the specific implementation. Include creating tests throughout. Your last step should be running the `Validation Commands` to validate the feature works correctly with zero regressions.>

## Execution Strategy
> Tool-agnostic guidance for how `/implement` should run the tasks above, on two orthogonal axes: **Topology** (how the work decomposes) and **Assurance** (what multi-agent structure, if any, raises confidence in the result). `/implement` runs this linearly by default and only orchestrates a Workflow when a run opts in (`--ultracode`/`--workflow`). Prefer the cheapest shape that fits — most changes are `single` + `none`. Escalate only with a concrete payoff, and justify it.

- **Topology:** <single | parallel | pipeline>
  - **Units:** <the natural unit of independent work, e.g. "per affected module"; omit for `single`>
  - **Dependencies:** <which units must complete before others; what is strictly sequential>
- **Assurance:** <none | adversarial-verify | tournament | loop-until-dry | completeness-critic>
  - <if not `none`, one line: what gets verified/judged/iterated and the pass bar — e.g. "3 skeptics try to refute the auth change; ship only if fewer than 2 succeed">
- **Per-unit verification:** <the test/lint to run on each unit or change as it completes>
- **Rationale:** <why this topology + assurance; why cheaper shapes were rejected>

## Testing Strategy
### Unit Tests
<describe unit tests needed for the feature>

### Integration Tests
<describe integration tests needed for the feature>

### Edge Cases
<list edge cases that need to be tested>

## Acceptance Criteria
<list specific, measurable criteria that must be met for the feature to be considered complete>

## Validation Commands
Execute every command to validate the feature works correctly with zero regressions. This is a dotfiles repo with no build/test/run — validation means scripts parse and configs are valid. Adjust to the files your feature touches:

- `bash -n install.sh sync.sh` — both shell scripts parse with no syntax errors.
- `for f in claude/settings.json config/ccstatusline/settings.json vscode/*.json cursor/*.json; do python3 -m json.tool "$f" >/dev/null || echo "BAD: $f"; done` — all tracked JSON is valid.
- `./sync.sh --stage-only && git restore --staged .` — capture runs end-to-end without committing.
- If you added shell logic, dry-run the relevant path (e.g. `./install.sh --help`, or run the new function with safe inputs) and confirm idempotency by running it twice.

## Notes
<optionally list any additional notes, future considerations, or context that will be helpful to the developer>
```

## Feature
$ARGUMENTS
