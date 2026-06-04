# Implement a plan

Follow the `Instructions` to implement the `Plan`, then `Report` the completed work. The implementer's external contract is identical regardless of execution mode: a summary, the mode that actually ran, and `git diff --stat`.

## Arguments
`$ARGUMENTS` is the path to the plan file, optionally followed by execution flags:
- **(no flag)** — default. **Linear, single-agent execution.** Read the plan's `## Execution Strategy` for task ordering only; do not spawn a Workflow.
- `--linear` — force linear even if the plan recommends orchestration.
- `--ultracode` / `--workflow` (aliases) — opt this run into multi-agent orchestration via the Workflow tool, using the plan's `## Execution Strategy` as the blueprint.
- `--max-parallel N` — cap concurrent agents in orchestrated mode.

## Instructions
- Read the plan. THINK HARD about it. Read its `## Execution Strategy` — both axes: **Topology** and **Assurance**.
- **Select mode:**
  - Default to **linear** unless `--ultracode`/`--workflow` is present. Orchestration is token-expensive and must be an explicit, per-run opt-in.
  - `--linear` always wins → linear.
- **Linear mode:** implement the `Step by Step Tasks` in order, top to bottom. Then run the plan's `Validation Commands`.
- **Orchestrated mode (`--ultracode`/`--workflow`):**
  1. Confirm the **Workflow tool is available** in this environment. If it is not, log the fallback and implement linearly — never fail a run because orchestration is unavailable.
  2. Translate the plan's `## Execution Strategy` into a Workflow script by composing the two axes:
     - **Topology** → the structure of the work:
       - `single` — one builder agent.
       - `parallel` — fan out one agent per unit (use worktree isolation when units mutate files concurrently).
       - `pipeline` — each unit flows through implement → verify stages with no barrier between them.
     - **Assurance** → a quality structure layered on top of the topology:
       - `adversarial-verify` — after a unit is built, spawn N independent skeptics prompted to *refute* it (default to refuted when uncertain); accept only if the majority fail to refute.
       - `tournament` — generate N competing implementations of the unit from different angles, score them with judges, and synthesize from the winner (grafting the best ideas from runners-up).
       - `loop-until-dry` — keep finding and fixing failing cases until K consecutive rounds surface nothing new.
       - `completeness-critic` — a final agent asks "what did we miss?" (untested path, unhandled case, unmet acceptance criterion); its findings become follow-up work or another round.
     - Respect declared **Dependencies** and `--max-parallel`. Verify each unit per the plan's **Per-unit verification**.
  3. Collapse the Workflow's structured results into a single coherent change set in the working tree.
- After execution (either mode), run the plan's `Validation Commands` and ensure they pass.

## Plan
$ARGUMENTS

## Report
- Summarize the work in a concise bullet list.
- State the **execution mode that actually ran**: `linear`; or `orchestrated` (name the topology + assurance and how many agents); or "orchestration requested but fell back to linear — Workflow tool unavailable".
- Report the files and total lines changed with `git diff --stat`. Do not commit unless asked.
