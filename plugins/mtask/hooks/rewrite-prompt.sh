#!/bin/bash
# mtask-toggle UserPromptSubmit hook
# When the toggle is on, instructs Claude to route the prompt through /mtask dev.
# When off, no-op (passes through).
# Bypass prefix `#` lets the user send a one-off non-mtask prompt.

set -uo pipefail

# Read the hook input JSON from stdin
INPUT=$(cat)

# Parse JSON using python3 (no jq dependency — python3 is universally available on dev machines)
parse_json() {
  local key="$1"
  python3 -c "import json,sys
try:
  d=json.loads(sys.stdin.read())
  print(d.get('$key',''))
except Exception:
  pass" <<< "$INPUT" 2>/dev/null
}

PROMPT=$(parse_json prompt)
SESSION_ID=$(parse_json session_id)

# Fallback if session_id missing — bail safely (don't risk wrong-session state pollution)
if [ -z "$SESSION_ID" ]; then
  exit 0
fi

# State file is per-session — lives in temp dir keyed by session ID.
# Cleaned up by the SessionEnd hook.
STATE_DIR="${TMPDIR:-/tmp}/mtask-toggle"
STATE_FILE="$STATE_DIR/${SESSION_ID}.state"

# If state file doesn't exist, toggle is off — pass through.
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# Read the toggle state and last-used flags
TOGGLE=$(grep '^toggle=' "$STATE_FILE" 2>/dev/null | cut -d= -f2- || echo "off")
FLAGS=$(grep '^flags=' "$STATE_FILE" 2>/dev/null | cut -d= -f2- || echo "--auto")

# If toggle is off, pass through.
if [ "$TOGGLE" != "on" ]; then
  exit 0
fi

# Bypass prefix: if prompt starts with `#`, instruct Claude to skip mtask for this turn.
if [[ "$PROMPT" == \#* ]]; then
  cat <<EOF
[mtask-toggle: bypass prefix detected]
The user's message starts with '#' which means they want this ONE prompt to bypass mtask-toggle.
Treat the rest of their message (after the leading '#') as a normal conversational prompt.
Do NOT invoke /mtask for this turn. Do not flip the toggle off — it stays on for the next prompt.
EOF
  exit 0
fi

# Don't reroute if the user is already invoking a slash command.
if [[ "$PROMPT" == /* ]]; then
  exit 0
fi

# Toggle is on, no bypass — instruct Claude to route through /mtask dev.
cat <<EOF
[mtask-toggle: ON]
The mtask-toggle is currently ON. Treat the user's message as the task description for an mtask invocation.

You should:
1. Invoke the mtask skill as if the user had typed: /mtask dev $FLAGS <their message>
2. Use the orchestration semantics defined in the mtask skill (operator vision, plan, agent spawning, etc.)
3. Do NOT mention this hook or the toggle unless the user asks about it
4. The flags above ($FLAGS) come from the user's most recent /mtask-toggle on invocation, or default to --auto if none was set

If the user's message is clearly conversational (a question, a thank-you, a clarification request) rather than a coding task, ask the user whether they meant to send it through mtask or as a normal message — they may have forgotten to use the '#' bypass prefix.
EOF
exit 0
