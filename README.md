# skills

Claude Code skills by [@kap-il](https://github.com/kap-il), distributed as a plugin marketplace.

## Install

In Claude Code:

```
/plugin marketplace add kap-il/skills
```

Then install any plugin from the marketplace:

```
/plugin install mtask@kap-il-skills
```

Verify with `/plugin` — installed plugins should be listed.

> If `/plugin marketplace add` fails with `git@github.com: Permission denied (publickey)`, your SSH keys aren't set up for GitHub. Use the HTTPS URL instead: `/plugin marketplace add https://github.com/kap-il/skills`

## Plugins

### `mtask` — Multi-agent task orchestration

Decomposes a coding task across 2–4 parallel sub-agents (or a recursive tree of sub-bosses for larger tasks), runs them in isolated git worktrees, and merges through a single integrity gate.

Two subcommands:

- **`/mtask inv`** — interactive, multi-pass investigation. Maps a codebase area, finds bugs, scopes features. Output is a verified findings report, an execution plan, or a direct hand-off to `dev`.
- **`/mtask dev`** — implementation. Boss plans, spawns dev agents in worktrees, monitors their streams, verifies their output against the operator's original ask, and merges.

Plus the optional **`/mtask-toggle`** session-mode that routes every subsequent prompt through `mtask dev` automatically:

```
/mtask-toggle on --del --opus      # every prompt now becomes /mtask dev --del --opus <prompt>
# do work; use # prefix on conversational prompts to bypass for one turn
/mtask-toggle off                  # back to normal
```

**Architecture:**
- Top boss + sub-bosses: Opus 4.7 (planning, monitoring, SSOT verification, merging)
- Dev / investigation agents: Sonnet 4.6 (execution within tightly-scoped slices)

**Flags:**

```
/mtask <inv|dev> [--N | --auto | --del] [--pass=N] <task>
```

| Flag        | Meaning                                                                                      |
| ----------- | -------------------------------------------------------------------------------------------- |
| `--2/3/4`   | Exactly N dev agents under one boss                                                          |
| `--auto`    | Boss picks count (capped at 4). Default if no flag given.                                    |
| `--del`     | Delegate mode — boss spawns sub-bosses recursively. Auto-decides counts at every layer.      |
| `--pass=N`  | (`inv` only) N sequential investigation passes (1–4), fresh agents each pass with findings-only handoffs |

**Examples:**

```
/mtask dev --4 build a 3d version of pong with ascii assets on webgl and nextjs
/mtask dev --auto refactor the auth module to use JWT
/mtask dev --del migrate the entire backend from express to fastify
/mtask inv --3 why is the checkout flow dropping conversions
/mtask inv --pass=2 --3 why is the checkout flow dropping conversions
/mtask inv --pass=4 --del audit the entire codebase for security issues
```

See the full skill at [`plugins/mtask/skills/mtask/SKILL.md`](plugins/mtask/skills/mtask/SKILL.md).

## Repo structure

```
skills/                                       ← this repo IS the marketplace
├── .claude-plugin/
│   └── marketplace.json                      ← marketplace catalog
├── plugins/
│   └── mtask/                                ← one plugin
│       ├── .claude-plugin/
│       │   └── plugin.json                   ← plugin manifest
│       └── skills/
│           └── mtask/
│               └── SKILL.md                  ← the skill itself
├── README.md
└── LICENSE
```

Adding more plugins later: drop a new `plugins/<name>/` directory and add an entry to `.claude-plugin/marketplace.json`.

## License

MIT — see [LICENSE](LICENSE).
