# Chore Planning

Create a new plan in `specs/*.md` to resolve the `Chore` using the exact specified markdown `Plan Format`. Follow the `Instructions`, and use the `Relevant Files` to focus on the right files.

## Instructions

- You're writing a plan to resolve a chore. It should be simple, but thorough and precise so we don't miss anything or waste time with a second round of changes.
- Create the plan in a `specs/*.md` file. Name it appropriately based on the `Chore`.
- Use the `Plan Format` below to create the plan.
- Research the codebase and put together a plan to accomplish the chore.
- IMPORTANT: Replace every <placeholder> in the `Plan Format` with the requested value. Add as much detail as needed to accomplish the chore.
- Use your reasoning model: THINK HARD about the plan and the steps to accomplish the chore.
- Respect requested files in the `Relevant Files` section.
- Start your research by reading `README.md` and `CLAUDE.md`.

## Relevant Files

Focus on the files most relevant to the chore. Ignore generated output, dependencies, and unrelated areas.

## Plan Format

```md
# Chore: <chore name>

## Chore Description
<describe the chore in detail>

## Relevant Files
Use these files to resolve the chore:

<find and list the files that are relevant to the chore, describing why they are relevant in bullet points. If new files are needed, list them in an h3 'New Files' section.>

## Step by Step Tasks
IMPORTANT: Execute every step in order, top to bottom.

<list step by step tasks as h3 headers plus bullet points. Order matters: start with the foundational shared changes, then the specific changes. Your last step should be running the `Validation Commands`.>

## Execution Strategy
> Tool-agnostic guidance for how `/implement` should run the tasks above, on two orthogonal axes: **Topology** (how the work decomposes) and **Assurance** (what multi-agent structure, if any, raises confidence in the result). `/implement` runs this linearly by default and only orchestrates a Workflow when a run opts in (`--ultracode`/`--workflow`). Chores that touch many independent files (renames, bumps, codemods) suit `parallel` topology; otherwise `single`. Prefer the cheapest shape that fits and justify any escalation.

- **Topology:** <single | parallel | pipeline>
  - **Units:** <the natural unit of independent work, e.g. "per file/package"; omit for `single`>
  - **Dependencies:** <what is strictly sequential>
- **Assurance:** <none | adversarial-verify | tournament | loop-until-dry | completeness-critic>
  - <if not `none`, one line: what gets verified/iterated and the pass bar>
- **Per-unit verification:** <the test/lint to run on each unit or change>
- **Rationale:** <why this topology + assurance; why cheaper shapes were rejected>

## Validation Commands
Execute every command to validate the chore is complete with zero regressions. This is a dotfiles repo with no build/test/run — validation means scripts parse and configs are valid:

- `bash -n install.sh sync.sh` — both shell scripts parse with no syntax errors.
- `for f in claude/settings.json config/ccstatusline/settings.json vscode/*.json cursor/*.json; do python3 -m json.tool "$f" >/dev/null || echo "BAD: $f"; done` — all tracked JSON is valid.
- `./sync.sh --stage-only && git restore --staged .` — capture runs end-to-end without committing.
- If the chore touched `install.sh`/`sync.sh` behavior, run the affected path twice to confirm idempotency.

## Notes
<optionally list any additional notes or context that will be helpful to the developer>
```

## Chore
$ARGUMENTS
