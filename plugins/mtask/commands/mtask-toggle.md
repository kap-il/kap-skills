---
description: Toggle mtask routing on or off for the current session
argument-hint: on|off|status [flags...]
allowed-tools: Bash
---

The user wants to manage the mtask-toggle state. Their input was: `$ARGUMENTS`

Parse the input and act:

**`on` (with optional flags like `--del --opus`)**: Enable the toggle. Every subsequent non-bypass-prefixed prompt this session will be routed through `/mtask dev <flags> <prompt>`. If flags are provided, store them as the toggle's default. If no flags, use `--auto`.

**`off`**: Disable the toggle. Subsequent prompts behave normally.

**`status`** (or no argument): Report current state — on/off, and the flags it's using.

To persist state across the session, use the bash tool to write/read `${TMPDIR:-/tmp}/mtask-toggle/${CLAUDE_SESSION_ID}.state`. The file format is simple key=value:

```
toggle=on
flags=--del --opus
```

If the directory doesn't exist, create it. If `CLAUDE_SESSION_ID` env var isn't set in the bash shell, fall back to a process-stable identifier — but warn the user that toggle state may not persist correctly.

After modifying state, confirm to the user what changed in one sentence. Don't be verbose. Examples:
- "mtask-toggle: ON (using --del --opus). Prompts will route through /mtask dev. Use '#' prefix to bypass for one prompt."
- "mtask-toggle: OFF. Prompts behave normally."
- "mtask-toggle: ON, flags --auto. (Set since this session started.)"

If the user passes invalid input (e.g. `/mtask-toggle maybe`), tell them the valid options are `on`, `off`, or `status`.
