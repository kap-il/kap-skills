#!/bin/bash
# mtask-toggle SessionEnd hook
# Cleans up the per-session state file when Claude Code exits.

set -uo pipefail

INPUT=$(cat)

SESSION_ID=$(python3 -c "import json,sys
try:
  d=json.loads(sys.stdin.read())
  print(d.get('session_id',''))
except Exception:
  pass" <<< "$INPUT" 2>/dev/null)

if [ -z "$SESSION_ID" ]; then
  exit 0
fi

STATE_DIR="${TMPDIR:-/tmp}/mtask-toggle"
STATE_FILE="$STATE_DIR/${SESSION_ID}.state"

if [ -f "$STATE_FILE" ]; then
  rm -f "$STATE_FILE"
fi

exit 0
