# metaplan

A plan for how the project plan gets built.

You decide to build something — say, a web-based 3d racing game. Before any planning or building starts, `/metaplan` decomposes the project into phases and routes each phase to the right tool in your installed skill library: this phase needs research, that one needs design exploration, that one warrants a parallel `/mtask dev --del` run, that one is a plain session. The output is a routing map, not a project plan — each phase's *assigned skill* is what produces the actual plan or work for that phase.

## Install

```
/plugin marketplace add kap-il/kap-skills
/plugin install metaplan@kap-skills
```

## Usage

```
/metaplan <project description>     create mode
/metaplan                           checkpoint mode (METAPLAN.md exists)
/metaplan status                    report state, no re-eval
```

### Create mode

1. **Scoping pass** — asks only questions whose answers change the decomposition or routing ("learning project or shippable?"), batched, 2–4 max. Never asks what a research phase would answer ("which framework?").
2. **Phase map** — decomposes by work *type* (research → design → build → verify), routes each phase to an installed skill or a plain session, records why that route over the rejected alternatives.
3. **Estimates** — per phase: **`CC: n sessions`** (active Claude Code time) and your time (review, decisions — the real bottleneck), with confidence markers.
4. **Re-route triggers** — each phase records the specific discoveries that would change downstream routing, written as predictions ("if no mature web physics engine fits, phase 3 grows a build-vs-buy decision").
5. Writes **`METAPLAN.md`** at the project root as the cross-session anchor, proposes the phase-1 invocation, and **stops**.

### Checkpoint mode

Re-invoke at every phase boundary. metaplan re-reads the operator vision, reads the closing phase's actual artifacts, tests its re-route triggers against what really happened, sanity-passes the remaining phases, re-reads the live skill list (skills change between sessions), updates `METAPLAN.md`, and composes the next phase's handoff invocation — distilling the prior phase's artifacts so you never re-explain context at a boundary. Then it **stops**.

## Hard rules

| Rule | Meaning |
| ---- | ------- |
| **Never executes** | Every invocation ends with an updated `METAPLAN.md` + a proposed next invocation, then a full stop. You authorize every phase launch, every time. Authorization for phase N is not authorization for N+1. |
| **Never plans content** | Phase goals are *what the phase answers*, 1–3 sentences. The how belongs to the routed skill. |
| **No silent scope absorption** | A distinct addition or change (a new build like a proprietary physics engine, a phase growing past ~2x its estimate) triggers a **scope-change consult**: what changed, CC-session + review-time cost delta, alternatives (adopt / buy-or-reuse / cut), downstream effects. The plan changes only after you decide. |
| **"No skill" is a valid route** | Plain implementation gets a plain session. Forcing a skill onto every phase is ceremony. |
| **Routes from the live skill list** | The session's available-skills list is the source of truth, re-read at every checkpoint. Never routes from memory. |

## The layering

```
metaplan          → decides WHICH skill plans/executes each phase
phase skill       → produces that phase's actual plan or work
review skills     → check the phase plan (autoplan, plan-eng-review, ...)
execution skills  → build it (mtask dev, plain session, ...)
```

Pairs naturally with [`mtask`](../mtask): metaplan decides *when* a phase warrants parallel orchestration; mtask is *how* that phase runs.

## When not to use it

Single-phase work (just do it), ideas that need "should I even build this?" first (ideation skills come before metaplan), plans that already exist and need review (that's the review skills' job), or mid-phase (the routed skill owns the process until the phase boundary).

## Files

```
metaplan/
├── .claude-plugin/
│   └── plugin.json          plugin manifest
└── skills/
    └── metaplan/
        └── SKILL.md         the skill
```
