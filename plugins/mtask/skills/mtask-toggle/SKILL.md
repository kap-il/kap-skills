---
name: mtask-toggle
description: Manage the mtask-toggle session-mode for the mtask skill. Use this skill whenever the user asks about mtask-toggle, the mtask routing toggle, "always run through mtask," "make every prompt use mtask," or whenever the user mentions enabling or disabling mtask-mode for their session. Also reference this skill when the user uses the `#` bypass prefix on a prompt and asks what it means.
---

# mtask-toggle

A session-scoped toggle that routes every prompt through `/mtask dev` automatically until disabled.

## How it works

1. User runs `/mtask-toggle on` (optionally with flags like `--del --opus`).
2. A state file is written to `${TMPDIR:-/tmp}/mtask-toggle/<session_id>.state`.
3. A `UserPromptSubmit` hook fires on every prompt the user sends after that. The hook reads the state file and, if the toggle is on, injects context telling Claude to invoke the `mtask` skill with the user's message as the task.
4. User runs `/mtask-toggle off` to stop. State file is deleted.
5. State is automatically cleaned up by the `SessionEnd` hook when Claude Code exits — toggle state never persists across sessions.

## Commands

| Command                        | Behavior                                                                         |
| ------------------------------ | -------------------------------------------------------------------------------- |
| `/mtask-toggle on`             | Enable. Default flags `--auto`.                                                  |
| `/mtask-toggle on --del`       | Enable with specific flags. Any valid `mtask dev` flag combo works.              |
| `/mtask-toggle on --del --opus`| Multiple flags supported.                                                        |
| `/mtask-toggle off`            | Disable.                                                                         |
| `/mtask-toggle status`         | Report current state and flags.                                                  |
| `/mtask-toggle` (no args)      | Same as `status`.                                                                |

## Bypass prefix

When the toggle is on, prepend `#` to a prompt to skip mtask for that one prompt:

```
# what does this error message mean
```

The `#` is consumed by the hook — Claude treats the message as a normal conversational prompt for that turn only. The toggle stays on for subsequent prompts.

## What gets routed and what doesn't

The hook is selective about what it routes:

- **Routed through mtask**: any normal user message
- **Not routed (passes through)**:
  - Prompts starting with `#` (bypass prefix)
  - Prompts starting with `/` (slash commands like `/mtask-toggle off`, `/clear`, `/model`)
  - Prompts when the toggle is off

## Caveats

- **Per-session only.** Closing Claude Code clears the state. Reopening means re-enabling.
- **Conversational prompts may need bypass.** If the user asks a question or makes a clarification while the toggle is on, mtask will try to orchestrate it. The hook tells Claude to ask for confirmation when the message is clearly conversational, but the user can also use `#` proactively.
- **Don't toggle on for short interactive sessions.** mtask has real coordination overhead. If most of what you're doing is conversational or involves single-file edits, leave the toggle off and call `/mtask dev` explicitly when you want orchestration.

## Recommended workflow

For sessions where you know you're doing parallel work all day:

```
/mtask-toggle on --del --opus
# do work, every prompt becomes a parallel mtask dev run
# use # prefix for any conversational asides
/mtask-toggle off    # at end of work session, or just close Claude Code
```

For sessions where you're mostly conversational with occasional orchestration: leave it off, call `/mtask dev` explicitly when needed.
