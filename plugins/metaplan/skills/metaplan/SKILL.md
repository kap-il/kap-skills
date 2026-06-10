---
name: metaplan
description: Plan how a project plan gets built — decompose a project into phases and route each phase to the right installed skill. Use when the user runs `/metaplan`, says "metaplan", "plan how to plan", "which skills should I use for this", or describes a new multi-phase project and wants to map their skill library onto it before any planning or building starts. Also use in checkpoint mode whenever a METAPLAN.md exists in the project and the user finishes a phase, says "checkpoint", "re-eval the metaplan", "phase done", or asks "what's next" — re-evaluate routing before anything else happens.
---

# metaplan

A metaplan is a plan for how the project plan gets built. It does exactly one thing: decompose a project into phases and route each phase to the tool that should produce that phase's plan or work — an installed skill, or a plain session. It never plans the project's content, and it never executes anything.

```
/metaplan <project description>     → create mode: scoping pass, phase map, METAPLAN.md
/metaplan                           → checkpoint mode (METAPLAN.md exists): re-eval, re-route, propose next
/metaplan status                    → report current state, no re-eval
```

## The layering

metaplan routes; it does not do. Every other skill stays exactly what it was:

```
metaplan          → decides WHICH skill plans/executes each phase
phase skill       → produces that phase's actual plan or work (research doc, design system, code)
review skills     → check the phase plan (e.g. autoplan, plan-eng-review)
execution skills  → build it (e.g. mtask dev, plain session)
```

If metaplan finds itself writing project content — feature lists, architecture, designs — it has drifted into the phase skill's job. Stop and route instead.

---

## Hard rules

1. **Never execute. Ever.** After every invocation — create or checkpoint — the output is an updated `METAPLAN.md` plus a proposed next invocation, then a full stop. metaplan does not invoke phase skills, does not start "just the easy part," does not pre-load the next phase's context into action. The operator authorizes every launch explicitly, every time. Authorization for phase N is not authorization for phase N+1.
2. **Never plan content.** Phase goals are one to three sentences of *what the phase answers or produces*, not how. The how is the routed skill's job.
3. **No silent scope absorption.** If a checkpoint reveals a distinct addition or change to the plan — a new phase, a new build (e.g. "no physics engine fits, we'd have to write one"), a materially bigger phase — metaplan must run a [scope-change consult](#scope-change-consult) before rewriting anything. Quiet plan edits that grow the project are the failure mode this rule exists to prevent.
4. **"No skill" is a valid route.** A phase that's plain implementation, or a conversation, gets routed to "regular session, no skill." Forcing a skill onto every phase is ceremony, not orchestration.
5. **Route from the live skill list.** The available-skills list in the current session context is the source of truth — descriptions are the matching signal. Re-read it at every checkpoint; installed skills change between sessions. Never route to a skill from memory of a past session.

---

## Create mode

### Step 1: Scoping pass

Ask only questions whose answers change the decomposition or the routing. Batch them; 2–4 max. Never ask anything derivable from the project description or answerable by a research phase.

Good: "learning project or shippable product?" (changes which phases exist), "solo or will others contribute?" (changes review/process phases), "hard deadline?" (changes how aggressively phases parallelize).
Bad: "which framework?" (that's a research phase's output), "what color scheme?" (that's a design phase's output).

If the description already answers everything routing-relevant, skip the questions and say so.

### Step 2: Discover skills

Read the session's available-skills list. For each candidate phase, shortlist skills whose descriptions match the phase's work type: research, ideation, design exploration, plan review, parallel implementation, QA, shipping, monitoring. Note skills that *almost* fit — they go in the routing rationale as rejected alternatives.

### Step 3: Decompose into phases

Split the project by work *type*, not by component. A phase boundary exists where the kind of work changes (research → design → build → verify), or where one phase's output is another's required input. Typical shape is 3–7 phases; more than that usually means the project needs an office-hours-style ideation pass first — route to that as phase 1 instead of decomposing prematurely.

### Step 4: Route each phase

For each phase record: the route (skill + flags, or "plain session"), why that route over the rejected alternatives, and the **re-route triggers** — the specific discoveries that would change downstream routing, written as predictions. Example: "Phase 1 research: if no mature web physics engine fits, phase 3 grows a build-vs-buy decision and its agent count doubles — scope-change consult required."

### Step 5: Estimate

Per phase, two numbers: **`CC: n sessions`** (active Claude Code work) and **your time** (review, decisions, approvals — always the real bottleneck). Mark confidence (high/medium/low) when it isn't high. Phases estimated above ~3 sessions should say how they split.

### Step 6: Write METAPLAN.md

At the project root (see [format](#metaplanmd-format)). This is the cross-session anchor — a future session must be able to read it cold and know exactly where the project stands and what runs next.

### Step 7: Stop and propose

Present the phase map summary and the composed phase-1 invocation. Then stop. Do not launch phase 1. Do not offer to "get started." Wait for explicit authorization.

---

## METAPLAN.md format

```markdown
# Metaplan: <project name>

## Operator vision (immutable)
<verbatim project description> + 2–4 sentence interpretation of what done looks like.
Written once. Never edited. Every checkpoint re-reads this first.

## Scoping decisions
<Q → A from the scoping pass. Append-only.>

## Phase map

### Phase 1: <name>   [pending | in-progress | done]
- **Goal**: <1–3 sentences — what this phase answers or produces>
- **Route**: `/skill --flags` | plain session
- **Why this route**: <1–2 sentences, name rejected alternatives>
- **Inputs**: <artifacts from prior phases, or "none">
- **Expected output**: <the artifact(s) this phase must leave behind>
- **Estimate**: **`CC: n sessions`** | your time: <m> (confidence)
- **Depends on**: <phase numbers, or "—">
- **Re-route triggers**: <discovery → downstream change it forces>

### Phase 2: ...

## Checkpoint log
<append-only: [date] phase N closed; triggers checked and outcomes; routing changes;
consults run and operator decisions. Empty at creation.>

## Next invocation (awaiting authorization)
<the exact composed command/prompt for the next phase>
```

The operator vision and scoping decisions are immutable; the phase map is editable only by metaplan itself at creation or checkpoint time; the checkpoint log is append-only. If the operator's intent genuinely changes, that's a new `/metaplan` conversation, not an in-flight edit to the vision.

---

## Checkpoint mode

Triggered by `/metaplan` when `METAPLAN.md` exists, or when the user signals a phase boundary. Procedure:

1. **Re-read operator vision**, then the full phase map and checkpoint log.
2. **Gather the closing phase's output.** Read its actual artifacts — research docs, design files, `.mtask/plan.md`, merged diffs. Ask the user only for what isn't on disk.
3. **Check re-route triggers first.** Test each of the closing phase's recorded triggers against what actually happened. Triggers are predictions the plan made about itself — checking them is what keeps re-evaluation from being a vague "still good?"
4. **General sanity pass** on all remaining phases: routes still right given what's now known? Estimates still credible? Dependencies still real?
5. **Re-read the live skill list.** New skills may route a remaining phase better; removed skills must be re-routed.
6. **If a distinct change or addition surfaced** → [scope-change consult](#scope-change-consult). Do not touch the phase map until the operator decides.
7. **Update METAPLAN.md**: mark the phase done, append the checkpoint log entry, apply any authorized routing changes.
8. **Compose the next phase's invocation** (see below), write it to the Next invocation section.
9. **Stop.** Present the checkpoint summary and the proposed invocation. Wait for authorization.

### Composing the handoff invocation

metaplan is the relay runner between phases: distill the closing phase's artifacts into the next phase's actual invocation so the operator never re-explains context at a boundary. The composed invocation includes the exact command with flags, pointers to the input artifacts (paths, not pasted contents), and a 2–4 sentence brief of what the prior phase established that the next skill must honor. Findings only — no reasoning chains, no speculation.

---

## Scope-change consult

Required whenever a checkpoint (or the create-mode scoping pass) surfaces a **distinct change or addition**: a new phase, a new build the plan didn't contain (proprietary physics engine, custom auth, a service that was assumed off-the-shelf), a phase whose estimate grew past ~2x, or a route change that materially changes cost (e.g. plain session → `--del --opus` mtask run).

The consult presents, before anything is rewritten:

- **What changed** — the discovery, with the artifact/evidence that surfaced it
- **Cost delta** — added **`CC: n sessions`** and added operator review time, against the original estimate
- **Alternatives** — always include at least: adopt it / buy-or-reuse instead of build / cut or defer the scope. Recommend one.
- **Downstream effects** — which later phases re-route or re-estimate if adopted

Then wait. The operator's decision gets recorded in the checkpoint log, and only then does the phase map change. No version of "I went ahead and added the phase, veto if wrong" — adoption is opt-in, not opt-out.

---

## When NOT to use this skill

- **Single-phase work.** One bug, one feature, one doc — just do it, or route straight to the one obvious skill. A metaplan over one phase is a routing table with one row.
- **The project doesn't exist yet as an idea.** "Should I even build this?" is ideation — route the user to an office-hours-style skill first, and metaplan after.
- **A plan already exists and needs review.** That's the review skills' job (autoplan, plan-eng-review). metaplan plans the process, not the critique.
- **Mid-phase.** While a phase is running, its routed skill owns the process. metaplan only re-enters at phase boundaries — don't checkpoint a half-finished phase unless the operator says it's stuck.

In any of these cases, say why metaplan isn't the fit and what to use instead.

---

## Quick reference

```
/metaplan <project>        → scoping pass → phase map → METAPLAN.md → propose phase 1 → STOP
/metaplan                  → checkpoint: triggers → sanity pass → skill re-read → update → propose next → STOP
/metaplan status           → report state, no re-eval

Hard rules:
  never executes — operator authorizes every phase launch, every time
  never plans content — phase skills do that
  scope change → consult with CC cost + alternatives, wait for decision
  "plain session, no skill" is a valid route
  routing source of truth = live skill list, re-read at every checkpoint
```
