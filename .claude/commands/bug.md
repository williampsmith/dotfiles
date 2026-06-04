# Bug Planning

Create a new plan in `specs/*.md` to resolve the `Bug` using the exact specified markdown `Plan Format`. Follow the `Instructions`, and use the `Relevant Files` to focus on the right files.

## Instructions

- You're writing a plan to resolve a bug. It should be thorough and precise so we fix the root cause and prevent regressions.
- Create the plan in a `specs/*.md` file. Name it appropriately based on the `Bug`.
- Use the `Plan Format` below to create the plan.
- Research the codebase to understand the bug, reproduce it, and put together a plan to fix it.
- IMPORTANT: Replace every <placeholder> in the `Plan Format` with the requested value. Add as much detail as needed to fix the bug.
- Use your reasoning model: THINK HARD about the bug, its root cause, and the steps to fix it properly.
- IMPORTANT: Be surgical. Solve the bug at hand and don't fall off track. We want the minimal number of changes that will fix and address the bug.
- If you need a new dependency, add it with the project's package manager and report it in the `Notes` section.
- Respect requested files in the `Relevant Files` section.
- Start your research by reading `README.md` and `CLAUDE.md`.

## Relevant Files

Focus on the files most relevant to the bug — the code paths involved in reproducing and fixing it. Ignore generated output, dependencies, and unrelated areas.

## Plan Format

```md
# Bug: <bug name>

## Bug Description
<describe the bug in detail, including symptoms and expected vs actual behavior>

## Problem Statement
<clearly define the specific problem that needs to be solved>

## Solution Statement
<describe the proposed solution approach to fix the bug>

## Steps to Reproduce
<list exact steps to reproduce the bug>

## Root Cause Analysis
<analyze and explain the root cause of the bug>

## Relevant Files
Use these files to fix the bug:

<find and list the files that are relevant to the bug, describing why they are relevant in bullet points. If new files are needed, list them in an h3 'New Files' section.>

## Step by Step Tasks
IMPORTANT: Execute every step in order, top to bottom.

<list step by step tasks as h3 headers plus bullet points. Order matters: start with the foundational shared changes, then the specific fix. Include tests that validate the bug is fixed with zero regressions. Your last step should be running the `Validation Commands`.>

## Execution Strategy
> Tool-agnostic guidance for how `/implement` should run the tasks above, on two orthogonal axes: **Topology** (how the work decomposes) and **Assurance** (what multi-agent structure, if any, raises confidence in the result). `/implement` runs this linearly by default and only orchestrates a Workflow when a run opts in (`--ultracode`/`--workflow`). Bug fixes are usually `single` topology; consider `adversarial-verify` assurance for risky or hard-to-reproduce fixes. Prefer the cheapest shape that fits and justify any escalation.

- **Topology:** <single | parallel | pipeline>
  - **Units:** <omit for `single`>
  - **Dependencies:** <what is strictly sequential>
- **Assurance:** <none | adversarial-verify | tournament | loop-until-dry | completeness-critic>
  - <if not `none`, one line: what gets verified/iterated and the pass bar — e.g. "spawn 3 skeptics to refute that the root cause is fixed and no regression is introduced">
- **Per-unit verification:** <the test/lint to run on each change>
- **Rationale:** <why this topology + assurance; why cheaper shapes were rejected>

## Validation Commands
Execute every command to validate the bug is fixed with zero regressions. This is a dotfiles repo with no test runner — reproduce the bug before the fix and confirm it's gone after, plus the standard checks:

- Reproduce: <the exact command/steps that trigger the bug before the fix; confirm it fails/misbehaves>
- `bash -n install.sh sync.sh` — both shell scripts parse with no syntax errors.
- `for f in claude/settings.json config/ccstatusline/settings.json vscode/*.json cursor/*.json; do python3 -m json.tool "$f" >/dev/null || echo "BAD: $f"; done` — all tracked JSON is valid.
- Confirm fixed: re-run the reproduction; it now behaves correctly. Run the affected path twice to confirm idempotency.

## Notes
<optionally list any additional notes or context that will be helpful to the developer>
```

## Bug
$ARGUMENTS
