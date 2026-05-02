---
name: mtask
description: Orchestrate investigation and implementation tasks across multiple sub-agents working in parallel. Use this skill whenever the user runs `/mtask inv`, `/mtask dev`, or mentions multitasking, agentifying, delegating, parallelizing, or orchestrating a coding task across multiple agents. Also use when the user wants a deep multi-angle investigation of a bug, feature, or codebase area, or when a task is large enough that splitting it across parallel workers would be faster than doing it serially. Default to suggesting this skill for any task that touches more than 3-4 files or has clearly separable components.
---

# mtask (multitask)

Orchestrate work across parallel sub-agents. Two subcommands.

```
/mtask <subcommand> [--N | --auto | --del] <task description>
```

## Subcommands

| Subcommand | Purpose                                                            |
| ---------- | ------------------------------------------------------------------ |
| `inv`      | Research a bug, feature, or area of the codebase. No code changes. |
| `dev`      | Implement a change. May include tests, refactors, docs.            |

## Flags

### Orchestration flags

Pick **one** orchestration flag per call. Mutually exclusive.

| Flag      | Meaning                                                                      |
| --------- | ---------------------------------------------------------------------------- |
| `--2`     | Exactly 2 dev agents under one boss.                                         |
| `--3`     | Exactly 3 dev agents under one boss.                                         |
| `--4`     | Exactly 4 dev agents under one boss.                                         |
| `--auto`  | Boss picks the count (capped at 4). Default if no flag given.                |
| `--del`   | Delegate mode. Boss spawns sub-bosses recursively; each level auto-decides.  |

### Modifiers

Combine with any orchestration flag.

| Flag       | Meaning                                                                                              |
| ---------- | ---------------------------------------------------------------------------------------------------- |
| `--opus`   | Upgrade leaf agents to Opus 4.7. Boss roles are always Opus regardless.                              |
| `--low`    | Set leaf agent effort to low. Boss stays at default (high).                                          |
| `--medium` | Set leaf agent effort to medium. (This is the default — flag exists for explicitness.)               |
| `--high`   | Set leaf agent effort to high. Boss stays at default (high).                                         |
| `--xhigh`  | Set leaf agent effort to xhigh. **Boss auto-upgrades to xhigh.**                                     |
| `--max`    | Set leaf agent effort to max. **Boss auto-upgrades to max.**                                         |
| `--mauto`  | **Adaptive model**: boss may upgrade specific leaf agents' model mid-run based on observed signal.   |
| `--eauto`  | **Adaptive effort**: boss may upgrade specific leaf agents' effort mid-run based on observed signal. |
| `--fauto`  | **Full adaptive**: equivalent to `--mauto --eauto` plus boss may spawn additional agents mid-run.    |

Effort flags (`--low/medium/high/xhigh/max`) are mutually exclusive. Adaptive flags (`--mauto/eauto/fauto`) compose with everything else but `--fauto` subsumes `--mauto` and `--eauto`.

`--pass=N` is `inv`-only and documented in the [`inv` section](#inv--interactive).

### Default behavior: uniform run

By default, every agent of a tier gets the same model and effort for the entire run. Boss does not vary settings per-agent. This keeps cost predictable and forces good decomposition (if one slice is dramatically harder than the others, that's a planning problem to fix at decomposition time, not paper over with model upgrades).

The adaptive flags are an **explicit opt-in** to let the boss override this rule. Without them, boss authority is limited to monitoring, verification, merging, and re-planning — never tuning individual agents.

### Default effort

| Role          | Default effort | Why                                                          |
| ------------- | -------------- | ------------------------------------------------------------ |
| Boss roles    | high           | Judgment work — planning, monitoring, SSOT verification, merging. |
| Leaf agents   | medium         | Execution within a tightly-scoped slice.                     |

### Effort auto-upgrade rule

`--xhigh` and `--max` set leaf effort to that level **and** automatically upgrade the boss to match. The reasoning: if you're paying for max-level execution, you need max-level supervision. A high-effort boss reviewing max-effort leaf output is the wrong asymmetry — boss judgment becomes the bottleneck on quality. `--low`, `--medium`, and `--high` for leaves don't affect the boss, since high-effort boss supervising lower-effort execution is the *intended* asymmetry.

### Examples

```
/mtask dev --4 build a 3d version of pong with ascii assets on webgl and nextjs
/mtask dev --auto refactor the auth module to use JWT
/mtask dev --del migrate the entire backend from express to fastify
/mtask dev --4 --opus rewrite the type checker with proper inference
/mtask dev --del --opus migrate the entire backend from express to fastify
/mtask dev --4 --low scaffold a CRUD API for these 4 entities          # cheap, mechanical
/mtask dev --del --opus --xhigh build a real-time collaborative editor # boss auto-upgrades
/mtask dev --del --max audit and refactor the auth subsystem           # full firepower
/mtask dev --del --mauto migrate the entire backend from express to fastify     # boss tunes model per slice
/mtask dev --del --eauto rewrite the parser with proper error recovery          # boss tunes effort per slice
/mtask dev --del --fauto build a real-time collab editor with CRDT sync         # full adaptive: model, effort, count
/mtask inv --3 why is the checkout flow dropping conversions
/mtask inv --pass=2 --3 why is the checkout flow dropping conversions
/mtask inv --pass=4 --del --opus audit the entire codebase for security issues
/mtask inv why is the checkout flow dropping conversions     # implied --auto, --pass=1, sonnet, medium
```

### Flag resolution rules

- **No flag given**: treat as `--auto`. State the agent count chosen and proceed.
- **`--N` for N ≥ 5**: auto-promote to `--del` and tell the user.
- **`--N` for N > 16**: reject with an error.
- **`--auto` decides on <2 slices**: this isn't an mtask task. Tell the user and exit — they should just make a normal request.
- **`--del` decides on ≤4 clean slices**: don't actually delegate; run flat with that many dev agents and tell the user delegation wasn't needed.
- **`--opus`**: leaf agents default to Opus 4.7 instead of Sonnet 4.6. Boss roles are always Opus regardless. Tell the user the cost implication briefly when starting an `--opus` run with `--del` or `--4`, since the cost multiplier is meaningful.
- **`--xhigh` / `--max`**: leaf agents and boss both run at that effort. Tell the user the boss is auto-upgrading. Cost callout same as above.
- **Multiple effort flags**: reject with an error listing the conflict.
- **`--low` with `--opus`**: legal but unusual — Opus running at low effort is rarely the right tradeoff. Confirm with the user before proceeding.
- **`--max` on Sonnet leaves**: legal but Sonnet 4.6 doesn't support `xhigh`/`max` the same way Opus does. Tell the user that effort caps at Sonnet's actual ceiling regardless of flag.
- **`--fauto` with `--mauto` or `--eauto`**: redundant — `--fauto` subsumes both. Accept the call but tell the user the flags are redundant.
- **Adaptive with no `--del`**: legal — boss can adapt flat-mode dev agents too. Sub-bosses don't exist to delegate to, but the top boss still has authority to upgrade or spawn.
- **Adaptive in `inv` mode**: legal but rare. Investigations usually finish too quickly for adaptive upgrades to pay off; cross-pass handoffs are the normal way to drill deeper. Tell the user this if they pair adaptive flags with `inv`.

> **No solo mode.** A single agent doing a single task is just a normal request. mtask exists for orchestration value, not to wrap solo work in ceremony.

---

## Model and effort assignments

Roles map to specific models and effort levels. Boss models are fixed; everything else is configurable at the run level via flags.

| Role          | Model (default → with `--opus`) | Effort (default)              |
| ------------- | ------------------------------- | ----------------------------- |
| Boss roles    | Opus 4.7 → Opus 4.7             | high (auto-upgrades to xhigh/max if `--xhigh`/`--max` is set) |
| Leaf agents   | Sonnet 4.6 → Opus 4.7           | medium (or whatever effort flag is set) |

When spawning, the boss sets `model:` and `effort:` (or equivalent provider parameter) on each agent based on the run's flags:

- **Sub-bosses**: always `claude-opus-4-7`. Effort matches the boss-level effort for the run.
- **Dev / investigation agents**: `claude-sonnet-4-6` by default, `claude-opus-4-7` if `--opus`. Effort matches the leaf-level effort for the run.

### Run-level only

Model and effort are **run-level settings, not per-agent settings**. Once the user picks them via flags, they apply uniformly to every agent in the matching role tier for the entire run. The boss does not upgrade or downgrade individual agents.

This is intentional: per-agent model/effort overrides add complexity without much real benefit, since well-decomposed slices have similar judgment requirements. If one slice is dramatically harder than others, that's a decomposition problem — re-plan, don't paper over it with model upgrades.

### The plan records the settings

The plan's **Run settings** section (added at the top, after operator vision) records the resolved model and effort for both tiers, so cost is transparent and reviewable. Example:

```
Run settings (immutable):
  Boss: Opus 4.7, effort=high
  Leaves: Sonnet 4.6, effort=medium
  Flags resolved from: --del (no --opus, no effort flag)
```

### Fallback

If Opus is unavailable, fall back to the strongest available model and tell the user — never silently downgrade a boss to a Sonnet-tier model, since the entire orchestration hinges on the boss catching scope drift. For leaf agents under `--opus`, fall back to Sonnet and warn that the cost-quality tradeoff has shifted. If the requested effort level is unavailable for the chosen model (e.g. `--xhigh` on Sonnet), cap at the model's ceiling and tell the user.

---

## Adaptive auto modes

By default, run settings are uniform and immutable mid-flight. The adaptive flags opt into letting the boss override that.

| Flag      | What boss can do mid-run                                                  |
| --------- | ------------------------------------------------------------------------- |
| `--mauto` | Upgrade a specific agent's model (e.g. Sonnet → Opus)                     |
| `--eauto` | Upgrade a specific agent's effort (e.g. medium → high)                    |
| `--fauto` | All of the above, plus spawn additional agents for slices running long    |

Adaptive authority is **upgrades only**. Boss never downgrades a running agent — if the work turns out easier than expected, the agent finishes faster and that's the win. Downgrades waste the partial work already done.

In `--del` mode, sub-bosses have the same adaptive authority over their own dev agents that the top boss has over its direct reports. They don't need top-boss approval to upgrade an agent in their slice. Spawning additional agents under `--fauto` is also a sub-boss authority — they manage their own slice's agent count.

### Trigger conditions

The boss watches for specific signals during execution. Adaptive action requires a clear signal — not a hunch:

- **Agent stuck on the same problem for >3 turns without progress** → upgrade (model or effort, depending on flag)
- **Agent producing output that fails verification repeatedly** → upgrade once; if it fails again post-upgrade, kill and re-plan instead
- **Agent self-reports it's hitting capability limits** ("I'm not sure how to handle this case", "this requires deeper analysis") → upgrade
- **Slice running >2x the elapsed time of peer slices, with no clear blocker** → spawn additional agent (`--fauto` only) to help split the work
- **Discovered complexity not visible at planning time** (e.g. agent finds the auth module is way bigger than expected) → upgrade or spawn, depending on flag

The boss does **not** upgrade preemptively or speculatively. Upgrades happen *after* observed signal, not based on the boss thinking "this slice looks gnarly." Preemptive upgrades belong at planning time via `--opus` or `--xhigh/max`, not adaptive auto.

### Mid-run upgrade procedure

When the boss decides to upgrade an agent:

1. **Pause the agent.** Send it a signal to stop where it is — don't let it complete the current task half-cooked.
2. **Current agent writes a handoff prompt.** Findings-only, same constraint as `inv` cross-pass handoffs: what was observed, what files were touched, what decisions were made, what's left to do. **No reasoning chain, no hypotheses, no apologies, no speculation.** Just facts.
3. **Discharge the current agent.** Its worktree stays; it won't be touched again. The handoff prompt is the only thing carried forward.
4. **Spawn a new agent at the upgraded tier.** Same task assignment, same worktree, same file ownership. Give it the handoff prompt as part of its context, alongside the standard plan + context bundle + rules.
5. **Log the upgrade in Live state.** Format: `[timestamp] Agent A2 upgraded: Sonnet medium → Opus high. Reason: stuck on type inference for 4 turns. Handoff: <one-line summary>.`

The handoff mechanism is what makes mid-run upgrades safe. Without it, you'd either lose progress (start the upgraded agent from scratch) or carry over the previous agent's confusion (give the new agent the full chat history). Findings-only handoffs preserve work without polluting context.

### Mid-run agent spawning (`--fauto` only)

When a slice is running long with no clear blocker, the boss can spawn an additional agent to help. Constraints:

- **The new agent gets a fresh slice carved out of the existing one.** Boss must split the original agent's task list, redraw file ownership so the two agents don't collide, and update the plan.
- **Agent count cap still applies.** `--fauto` doesn't lift the 4-agent ceiling on flat mode or the soft caps in `--del`. If the run is already at cap, boss can't spawn more — has to upgrade or wait instead.
- **Splitting takes priority over spawning.** If the boss can re-decompose the slice into two parallel chunks, do that. Spawning a helper that works on the same files as the original agent is a recipe for collisions.

### What adaptive does *not* do

- **No per-agent user pinning.** The user can't say "give Agent A2 Opus" at planning time. That's still off the table — it would let users paper over bad decomposition.
- **No effort auto-upgrade triggering boss upgrade.** The xhigh/max → boss upgrade rule only applies to user-set flags, not boss-triggered mid-run upgrades. If `--eauto` upgrades a leaf to xhigh, the boss does *not* auto-upgrade alongside; one agent at higher effort doesn't justify the whole run going up a tier.
- **No silent upgrades.** Every adaptive action is logged in Live state with timestamp, reason, and old/new settings. Audit trail.
- **No rolling back.** Once upgraded, an agent stays at the upgraded tier for the rest of the run. No re-downgrade mid-flight.

---

## `inv` — Interactive

Investigation is **interactive**. Do not produce a report on the first pass.

`inv` accepts an additional flag beyond the orchestration ones:

| Flag         | Behavior                                                                       |
| ------------ | ------------------------------------------------------------------------------ |
| `--pass=N`   | Run N sequential investigation passes (1–4). Default: 1.                       |

Passes are sequential and additive: pass 1 is reconnaissance, pass 2+ each drill into findings from the previous pass. Each pass uses fresh agents that read **only a findings-only handoff** from the previous pass, never the previous agents' raw chains-of-thought. This prevents cumulative interpretation drift.

`--pass` composes with `--N`/`--auto`/`--del`:
- `--pass=2 --3` → 2 passes, each with 3 investigators
- `--pass=4 --del` → 4 passes, each with delegated hierarchy

### Step 1: Clarify

Before launching any agents, ask the user 2–4 targeted questions covering:

- **Scope**: which files, modules, or systems are in/out of bounds
- **Goal**: are they trying to fix a bug, plan a refactor, scope a feature, or just understand something
- **Depth**: skim-level overview vs. deep dive with line-level references
- **Constraints**: anything they already know, have ruled out, or want excluded

Use `ask_user_input_v0` if available; otherwise ask in prose with numbered questions.

**Clarification guard.** After answers, if the ask is still too vague to parameterize 2+ investigators (e.g. "look at the codebase and tell me what's wrong"), this isn't an mtask task. Tell the user and exit — they should either narrow the ask or do a normal exploratory chat first.

### Step 2: Plan and gather context

Produce `.mtask/investigation.md` with:

- **Operator vision** — verbatim user ask plus 2–4 sentence boss interpretation of what answering well looks like. **Immutable** — same rules as `dev`'s operator vision. Anchors all passes.
- **Run settings** — resolved model and effort for both boss and leaf tiers, plus the flags they came from. Immutable.
- **Investigation areas** — numbered list of areas to cover (see decomposition below)
- **Agent assignments** — which agent covers which area (per pass). All leaf agents share the run's leaf model and effort.
- **Pass plan** — what each pass is for (e.g. "pass 1: map the data flow; pass 2: deep-dive on the bottlenecks pass 1 found")
- **Findings log** — empty at planning time, append-only by agents
- **Boss attention** — empty at planning time, for blockers and conflicting findings
- **Cross-pass handoffs** — empty at planning time, populated between passes

Also produce `.mtask/context.md` (same as `dev` — repo overview, tech stack, conventions, how to run/test, existing patterns, landmines).

### Step 3: Decompose

Pick the decomposition axis that best matches the operator's goal. Priority order:

1. **By subsystem** — auth, db, api, frontend, etc. Best when the question spans modules and you want coverage.
2. **By question type** — correctness, performance, security, architecture. Best when the user asks "is X good" rather than "how does X work."
3. **By data flow** — entry points → business logic → persistence. Best for tracing bugs or understanding behavior end-to-end.
4. **By time** — current state vs. git log history vs. recent changes. Best for "when did this break" or "why is this here."

Pick **one** axis per pass. Mixing axes inside a single pass produces overlapping investigations and noisy synthesis. Different passes can use different axes (pass 1 by subsystem to map, pass 2 by data flow to trace).

Same collision-avoidance rule as `dev`: no two investigators read the same files as their primary focus, to keep findings independent and reduce groupthink.

### Step 4: Run pass 1

Spawn investigators per the plan. Each investigator gets:

- The context bundle (`.mtask/context.md`)
- The investigation plan (`.mtask/investigation.md`)
- The [Rules for all agents](#rules-for-all-agents) section
- Its specific area and any file/path scope
- Model and effort: per the plan's **Run settings** section

Investigators read files, trace logic, write findings to **Findings log** in `.mtask/investigation.md` as append-only entries. Each finding includes: investigator ID, pass number, file:line references, the observation, and confidence (high/medium/low).

For `--del`, sub-bosses spawn and supervise their own investigators per the [Delegate mode](#delegate-mode) rules.

### Step 5: Verify

Boss reviews the findings log against the actual files cited. For each finding:

- **Open the cited file at the cited line** and confirm the finding accurately describes what's there
- **Reject hallucinated findings** (file/line doesn't match observation, function doesn't exist as described, etc.) and respawn the investigator with a tightened brief
- **Flag low-confidence findings** for either deeper investigation in the next pass or explicit "uncertain" framing in the report

Verification is mandatory. An unverified finding in a synthesized report becomes "what the user knows" — getting this wrong is worse than missing the finding entirely.

### Step 6: Handle conflicts

If two investigators reach contradictory conclusions about the same code path:

1. Boss reads both findings and the cited code directly
2. If one is clearly wrong → reject that finding, keep the other
3. If both have partial truth → synthesize into a single finding noting the tension
4. If genuinely ambiguous → log under **Boss attention** and flag for next pass or explicit "open question" in the report

Don't paper over conflicts by averaging or picking the more confident-sounding one.

### Step 7: Cross-pass handoff (if `--pass>1`)

For each pass after the first, the previous pass's investigators must produce **handoff prompts** for the next pass. Critical constraint: handoffs contain **findings only**, nothing else.

Each handoff includes:
- The verified finding (what was observed, where)
- The cited file:line references
- Confidence level

Handoffs do **not** include:
- Investigator's reasoning chain
- Hypotheses about why
- Suggested next steps or recommendations
- Speculation

The next pass's investigators read the handoffs as ground truth observations, then form their own interpretations. This prevents pass-to-pass drift where each interpretation builds on the previous one until the original observations are buried.

Boss writes handoffs to **Cross-pass handoffs** in `.mtask/investigation.md`, one entry per finding to be carried forward. Boss also writes a **pass plan** for the next pass: which findings to drill into, which questions to answer, which areas to ignore now.

Then loop back to Step 4 with fresh agents and the new pass plan.

### Step 8: Synthesize and verify

After the final pass, boss synthesizes the findings log into a coherent report. Re-verify any finding that's load-bearing in the synthesis — synthesis can change which findings matter, and a finding that was peripheral in pass 1 might become central by pass 4.

### Step 9: Choose output mode

**Always ask the operator** — even for trivial investigations — which output they want. Use `ask_user_input_v0`:

- **Findings report** — markdown report with summary, findings (file:line refs), open questions, confidence levels. No recommendations or implementation plan. Best when the operator wants to think for themselves.
- **Execution plan** — findings report plus a fully-built `dev` plan (task list, agent assignments, file ownership, locks, dependencies, merge order). Operator can review and run `/mtask dev` later, or invoke directly. Best when the operator wants the boss to do the synthesis-to-action work.
- **Hand off to `/mtask dev`** — boss writes the execution plan, then immediately invokes `dev` on it. Best when the operator trusts the investigation and wants to keep moving.

Don't pick for the operator. The choice often reveals what they actually wanted from the investigation in the first place.

### Step 10: Deliver

Produce the chosen output. Format:

- **Findings report**: markdown with `Summary` / `Findings (by area)` / `Open questions` / `Confidence notes` sections. File:line citations everywhere.
- **Execution plan**: findings report + appended `dev`-style plan section. Save as `.mtask/proposed-plan.md`.
- **Hand off**: write the plan, then start `/mtask dev` with operator vision pulled from the investigation's vision.

End by asking if the operator wants any follow-up investigation or to invoke `/mtask dev` (if they chose findings-only or execution-plan modes).

---

## `dev` — Execute

You are the **boss agent**. Dev agents (and sub-bosses, if `--del`) are sub-agents you spawn.

### Step 1: Plan and gather context

Produce a written plan at `.mtask/plan.md` (create the directory). The plan must include, in this order:

- **Operator vision** — the user's original task description, verbatim, plus a 2–4 sentence boss interpretation of what success looks like. **This is the anchor.** It is written once at planning time and is **immutable** — never edited, never paraphrased, never "cleaned up". Every agent reads this first, before anything else, every time they touch the plan. It exists to prevent cumulative drift: agents reading the plan mid-execution should always be able to recover the user's actual intent, not just the most recent state.
- **Run settings** — resolved model and effort for both boss and leaf tiers, plus the flags they came from. Immutable. See [Model and effort assignments](#model-and-effort-assignments).
- **Task list** — every discrete unit of work, numbered
- **Agent assignments** — which agent owns which tasks (and which sub-boss owns which agents, if `--del`). All leaf agents share the run's leaf model and effort; sub-bosses share the boss's. Example: `Agent A1: tasks 1,2 — files: src/auth/*` and the model is implicit from Run settings.
- **File ownership** — which files each agent may write to
- **Locked files** — files no agent may modify (boss merges only)
- **Dependencies** — which tasks block which
- **Merge order** — the sequence the top boss will use to integrate work
- **Live state** — empty at planning time, populated by agents as they work. Each entry includes: task ID, status (in-progress / done / blocked), files actually touched, key decisions made, deviations from the plan. This is the single source of truth for project state — agents sift every change up here.
- **Boss attention** — empty at planning time. Agents log here when they hit a locked file, need a new dependency, encounter out-of-scope work, or get blocked.

**How agents record changes**: updates go in **Live state** as append-only entries with task ID and timestamp. They do **not** edit earlier sections of the plan. If a deviation contradicts an earlier section (e.g. an agent realized the task list was wrong), they flag it in **Boss attention** — the boss decides whether to amend the plan or accept the deviation. Agents never rewrite the task list, agent assignments, or operator vision themselves. This keeps the plan auditable: every change is a comment on the original, not a replacement of it.

Also produce a **context bundle** at `.mtask/context.md`. Every agent at every level reads this before doing anything. It contains:

- **Repo overview** — what the project is, what it does, who it's for (1–3 sentences)
- **Tech stack** — languages, frameworks, package manager, build tool, test runner
- **Project conventions** — directory structure, naming patterns, code style notes (link to existing config files like `.eslintrc`, `pyproject.toml`, etc. rather than restating)
- **How to run/test** — exact commands for build, test, lint, dev server
- **Existing patterns to follow** — pointers to 1–2 representative files agents should use as style reference
- **Known landmines** — anything brittle, deprecated, or in-flight that agents should avoid

The boss assembles `context.md` by inspecting the repo (reading README, package files, a sample of source files) before spawning anyone. **No agent is spawned without it.**

Both `.mtask/plan.md` and `.mtask/context.md` are visible to every agent at every level. They read both before starting and re-read the plan whenever they finish a task — other agents may have updated it.

### Step 2: Decompose

Resolve the agent count first per the flag rules above, then decompose using this priority order. Rule 1 is most important; only consider rule 2 once rule 1 is satisfied; only consider rule 3 once rules 1 and 2 are satisfied:

1. **Avoid collisions first (top priority).** No two agents should be writing to the same file. If a file is touched by multiple logical tasks, either: (a) assign it to one agent who handles all touches, or (b) lock it and have boss handle it post-merge.
2. **Then split by component.** Group tasks by natural seams — module, package, layer, feature. An agent should own a coherent slice, not scattered diffs.
3. **Then balance time complexity (lowest priority).** Once collisions and components are settled, even out the workload so the slowest agent isn't 10x the fastest.

If a lower-priority rule wants to override a higher one — e.g. "splitting by component would balance the workload better" — the higher one wins. Better to have one agent doing 70% of the work alone than two agents fighting over the same files.

For `--del`, see [Delegate mode](#delegate-mode) below.

### Step 3: Set up worktrees

Each dev agent works in its own git worktree to isolate changes:

```bash
git worktree add .mtask/worktrees/agent-1 -b mtask/agent-1
git worktree add .mtask/worktrees/agent-2 -b mtask/agent-2
# etc.
```

If the project isn't a git repo, fall back to having agents write to distinct file sets and skip worktrees — note this limitation in the plan.

### Step 4: Spawn dev agents

For each agent, give it:

- The context bundle (`.mtask/context.md`)
- The full plan (`.mtask/plan.md`)
- The [Rules for all agents](#rules-for-all-agents) section of this skill
- Its specific task list and worktree path
- Its file ownership and locked-file list
- Instructions to **not** modify locked files; if a locked file needs changing, surface it to the boss instead of editing
- Model and effort: per the plan's **Run settings** section. Leaf model and effort are uniform across all dev / investigation agents in the run.

Sub-bosses are spawned the same way but always with `claude-opus-4-7` (boss tier model) and the boss-tier effort from Run settings, plus a coordination brief instead of an execution brief.

Spawn agents in parallel where the dependency graph allows. Run them serially when one's output feeds another's input.

### Step 5: Monitor

While agents work, the boss (and any sub-boss) **streams and gates** their output:

- Watch each agent's progress as it streams — don't fire-and-forget
- Block any change that violates the rules: scope creep, unauthorized file writes, new dependencies, branch sprawl
- Permit and acknowledge changes that conform; agents wait briefly for permission on flagged actions before proceeding
- If an agent goes off-rails repeatedly, kill it, update the plan, and respawn with a tighter task description

Sub-bosses do this for their own dev agents; the top boss does it for sub-bosses.

### Step 6: Merge

**Only the top boss merges.** Dev agents and sub-bosses never merge into the main branch.

For each completed worktree, in the merge order from the plan:

1. **Verify against SSOT.** Re-read **operator vision** and the agent's task assignment. Read the agent's **Live state** entry: do the files touched, decisions made, and deviations stay within scope of what the user actually asked for? Three outcomes:
   - **In scope** → proceed to step 2.
   - **Clearly out of scope and unwanted** (silent scope creep, hallucinated requirements, unrelated refactors) → reject the worktree, respawn the agent with a tightened brief or absorb the deviation into a re-plan.
   - **Out of scope but plausibly valuable** (e.g. agent noticed a bug adjacent to its task and fixed it; agent picked a different library that's actually better) → **stop and consult the operator.** Surface the deviation, the reasoning, and the diff. Wait for explicit go-ahead before merging. Do not assume good intent grants permission.

   Verification is not optional. A clean diff that drifts from intent is worse than a messy diff that stays on target.
2. Review the diff for code quality, test coverage, and adherence to the agent's file ownership.
3. Resolve any conflicts (these should be rare if decomposition was clean — frequent conflicts mean the plan was wrong; stop and re-plan).
4. Merge into the main working branch.
5. Run tests if a test command is known.
6. Update `.mtask/plan.md` to mark the task done in **Live state**.

### Step 7: Report

Final report includes: what each agent did, what was merged, what tests passed, anything unresolved, and any locked-file changes the boss made directly.

---

## Delegate mode

Triggered by `--del` explicitly, or auto-promoted when `--N` is requested with N ≥ 5.

The structure is **recursive**: any boss can spawn sub-bosses if its assigned slice is too big to manage as flat dev agents. Each level auto-decides its own decomposition — there's no top-level count to specify because every boss makes its own call. In practice:

- 1 layer (top boss → dev agents) — standard parallel; rare under `--del` since it usually downgrades to a numbered flag
- 2 layers (top boss → sub-bosses → dev agents) — most `--del` tasks
- 3+ layers — extremely large refactors, unusual

### Sub-boss responsibilities

A sub-boss is a coordination layer, **not** a merge point. Its job:

1. Receive its slice of the plan from its parent boss (a coherent component or feature area)
2. Decompose its slice further if needed (5+ tasks → spawn sub-sub-bosses; 2–4 tasks → spawn dev agents directly)
3. Set up its own worktrees under `.mtask/worktrees/<sub-boss-id>/agent-N`
4. Spawn and supervise its dev agents
5. **Verify each dev agent's worktree against operator vision and the agent's slice** before accepting it. Same scope check as the top boss does at merge:
   - In scope → accept and stage for handback.
   - Clearly out of scope and unwanted → reject and respawn.
   - Out of scope but plausibly valuable → **escalate to the top boss**, who decides whether to consult the operator. Sub-bosses do not consult the operator directly — that channel belongs to the top boss only, to keep operator interactions coherent.

   Sub-bosses are the first line of SSOT enforcement; the top boss does the final pass and owns operator communication.
6. Hand back **finished, verified worktrees** to the parent — no merging into shared branches

### Why sub-bosses don't merge

Centralizing merge at the top boss preserves a single integrity gate. If sub-bosses merged, you'd have:

- Multiple merge points = multiple places conflicts hide
- Sub-bosses making merge decisions without seeing siblings' work
- Top boss reviewing pre-merged code that's harder to attribute

Sub-bosses *review* their dev agents' work (catch obvious bugs, request fixes) but don't integrate. Their output to the top boss is a set of clean worktrees, each tagged with what it does.

### Plan structure under `--del`

`.mtask/plan.md` reflects the tree:

```
Top boss: <task>
├── Sub-boss A: <component-1>
│   ├── Dev agent A1: <task-1>, files: [...]
│   └── Dev agent A2: <task-2>, files: [...]
└── Sub-boss B: <component-2>
    ├── Dev agent B1: <task-3>, files: [...]
    └── Dev agent B2: <task-4>, files: [...]

Locked files (top-boss only): [...]
Merge order: A1, A2, B1, B2
```

Every agent at every level reads this same file. File ownership and locks are global — a sub-boss cannot grant access to a top-boss-locked file.

### When `--del` doesn't fit

If decomposition naturally yields ≤4 clean slices, don't actually delegate even if the user passed `--del`. Run flat parallel mode with that count and tell the user delegation wasn't needed.

If decomposition yields >4 slices but they aren't cleanly groupable into 2–4 sub-components (e.g., 6 totally independent slices with no natural pairing), run them as sequential `--4` batches rather than forcing artificial groupings.

---

## Rules for all agents

These rules apply to **every agent** — top boss, sub-bosses, and dev agents. Boss includes them in the spawn message for every agent it creates. Sub-bosses propagate them downward.

### Git hygiene

1. **Granular commits.** Commit per logical unit of work, not per task or per agent. A typical agent should produce 3–10 commits, not 1 mega-commit. Boss reviews commits incrementally; mega-commits make rollback all-or-nothing.
2. **Commit messages reference the plan.** Use the format `[<agent-id>] <message>` (e.g. `[A1] add JWT validator`). Boss uses these to trace each commit back to a planned task.
3. **No runaway branching.** Each agent gets exactly one branch (`mtask/agent-N` or `mtask/<sub-boss>/agent-N`). No feature sub-branches, no fix-up branches, no experimental detours. If an approach isn't working, stop and ask the boss — don't branch off to try alternatives.
4. **Only the top boss merges to the main working branch.** Dev agents and sub-bosses never merge upward; they hand back worktrees.
5. **No force-pushes, no rebases of shared branches.** Agents work in their own worktree; history there is theirs to manage, but once handed back it's frozen.

### Scope discipline

6. **Surface, don't solve, out-of-scope work.** If a task requires changes outside an agent's file ownership, the agent stops and reports to its boss rather than expanding scope. The boss decides whether to re-plan, lock the file, or assign the new work to another agent.
7. **No new dependencies without boss approval.** Adding a package to `package.json`, `requirements.txt`, `Cargo.toml`, etc. is a global change masquerading as local. Treat dependency manifests as locked-by-default; agents must request approval through the plan's "Boss attention" section.
8. **No changes to locked files.** Period. Surface the need; don't edit.
9. **No changes to project-wide config without boss approval.** This includes CI configs, lint configs, formatter configs, build configs, env files, and similar. Treat as locked even if not explicitly listed.

### Verification

10. **Tests run in worktree before handoff.** Agent runs the test command from `.mtask/context.md` and verifies its slice passes before declaring done. Boss should not be discovering broken tests at merge time.
11. **No skipping or disabling tests to make things pass.** If a test legitimately needs to change, it's a planned task, not a workaround.
12. **No commented-out code in handoff.** Either delete it or keep it; don't ship indecision.

### Coordination

13. **Re-read the plan after every task completion.** Other agents may have updated it. The plan is the source of truth, not the snapshot you saw at spawn. Always re-read **operator vision** first — that's the anchor that prevents cumulative drift across many agent updates.
14. **Sift every change up to the plan, append-only.** The plan is the project's single source of truth — it must reflect actual state, not intended state. After each task: append an entry to **Live state** with task ID, status, files actually touched, key decisions made (e.g. "used bcrypt instead of argon2 because X"), and any deviations from the plan. Log blockers under **Boss attention**. An agent that finishes silently has broken coordination even if their code works.
15. **Never edit upstream sections of the plan.** Operator vision, task list, agent assignments, file ownership, locked files, dependencies, and merge order are all written by the boss at planning time and are immutable to dev agents. If a deviation contradicts an upstream section, flag it in **Boss attention** — the boss decides whether to amend or accept. Sub-bosses likewise don't edit sections they didn't author. This is what prevents runaway editing: changes are *recorded as observations*, not *applied as overwrites*.
16. **Stay within your slice.** Don't read or analyze files outside your ownership unless they're explicit dependencies. Keeps context windows focused and prevents drift into other agents' work.

### Boss-specific rules

These apply to top boss and sub-bosses only:

17. **Monitor agent streams; don't fire-and-forget.** Watch progress, block rule violations in real time, permit conforming changes. Agents wait briefly for permission on flagged actions.
18. **Verify against SSOT at every merge or handback.** Before accepting a worktree, re-read operator vision and the agent's task assignment, then check the actual diff and Live state entry against them. Three outcomes: in-scope → proceed; clearly out-of-scope and unwanted → reject and respawn; **out-of-scope but plausibly valuable → consult the operator before merging**. Don't accept drift on the agent's behalf, even good drift. Orchestration without verification is just delegation.
19. **Kill and respawn over heroic intervention.** If an agent goes sideways, kill it, tighten the task description in the plan, and respawn. Don't try to course-correct mid-stream past one or two nudges.
20. **Re-plan over papering over.** If decomposition is producing collisions, scope creep, or merge conflicts, stop and re-plan. A bad plan compounds; a re-plan resets.
21. **Never modify operator vision.** Even the top boss leaves it untouched. If the user's intent genuinely changed mid-execution, that's a separate `/mtask` invocation, not an in-flight edit. The vision section is the one piece of the plan that survives unchanged from start to finish.

---

## Conflict-handling rules

- **A dev agent hits a locked file**: it stops, logs the need in `.mtask/plan.md` under "Boss attention", and moves on.
- **Two agents need the same unlocked file**: this is a planning failure. Boss reclaims the file, either re-assigning it to one agent or locking it.
- **Merge conflict at integration time**: top boss resolves. If conflicts are non-trivial, re-plan rather than papering over.
- **An agent finishes early**: check the plan for unblocked tasks it could pick up. Update assignments in the plan file before reassigning.
- **A sub-boss reports its slice can't be cleanly decomposed**: top boss either accepts a flat dev-agent assignment for that slice or re-plans the overall decomposition.

---

## When NOT to use this skill

mtask adds coordination overhead. Skip it entirely when:

- The task is small (under ~3 files) — just do it directly
- Tasks are tightly coupled (every change ripples through every file)
- The codebase isn't a git repo and the task involves overlapping file sets
- Sub-agent spawning isn't available in the current environment

In any of these cases, handle the task as a normal request and tell the user why mtask wasn't the right fit.

---

## Quick reference

```
# Orchestration (pick one)
/mtask <inv|dev> <task>                 → --auto, 1 pass for inv
/mtask <inv|dev> --N <task>             → exactly N agents (2–4)
/mtask <inv|dev> --auto <task>          → boss picks count (default)
/mtask <inv|dev> --del <task>           → boss + sub-bosses (recursive)

# inv-only
/mtask inv --pass=N <task>              → N sequential passes (1–4)

# Modifiers (combine freely with orchestration)
... --opus                              → leaves use Opus 4.7 (bosses always Opus)
... --low / --medium / --high           → leaf effort (boss stays high)
... --xhigh / --max                     → leaf AND boss effort upgraded together

# Adaptive auto (opt-in: lets boss override uniform run-level settings mid-run)
... --mauto                             → boss may upgrade leaf model on observed signal
... --eauto                             → boss may upgrade leaf effort on observed signal
... --fauto                             → mauto + eauto + boss may spawn extra agents

# Defaults
Boss:    Opus 4.7, effort=high
Leaves:  Sonnet 4.6, effort=medium
Adaptive: off (uniform run-level settings, no mid-run changes)
```
