#!/bin/bash
# Continuous Learning v2 - Observation Hook
#
# Captures tool use events for pattern analysis.
# Claude Code passes hook data via stdin as JSON.
#
# Hook config (in ~/.claude/settings.json):
# {
#   "hooks": {
#     "PreToolUse": [{
#       "matcher": "*",
#       "hooks": [{ "type": "command", "command": "~/.claude/skills/continuous-learning-v2/hooks/observe.sh" }]
#     }],
#     "PostToolUse": [{
#       "matcher": "*",
#       "hooks": [{ "type": "command", "command": "~/.claude/skills/continuous-learning-v2/hooks/observe.sh" }]
#     }]
#   }
# }

CONFIG_DIR="${HOME}/.claude/homunculus"
OBSERVATIONS_FILE="${CONFIG_DIR}/observations.jsonl"
ERROR_LOG="${CONFIG_DIR}/hook-errors.log"
MAX_FILE_SIZE_MB=10

# Ensure directory exists
mkdir -p "$CONFIG_DIR"

# Skip if disabled
if [ -f "$CONFIG_DIR/disabled" ]; then
  exit 0
fi

# Read JSON from stdin (Claude Code hook format)
INPUT_JSON=$(cat)

# Exit if no input
if [ -z "$INPUT_JSON" ]; then
  exit 0
fi

# Archive if file too large
if [ -f "$OBSERVATIONS_FILE" ]; then
  file_size_mb=$(du -m "$OBSERVATIONS_FILE" 2>/dev/null | cut -f1)
  if [ "${file_size_mb:-0}" -ge "$MAX_FILE_SIZE_MB" ]; then
    archive_dir="${CONFIG_DIR}/observations.archive"
    mkdir -p "$archive_dir"
    mv "$OBSERVATIONS_FILE" "$archive_dir/observations-$(date +%Y%m%d-%H%M%S).jsonl"
  fi
fi

# Parse and write observation using Python with stdin (avoids escaping issues)
printf '%s\n' "$INPUT_JSON" | python3 -c "
import json
import sys
from datetime import datetime, timezone

observations_file = '$OBSERVATIONS_FILE'

try:
    raw_input = sys.stdin.read()
    data = json.loads(raw_input)

    # Extract fields - Claude Code hook format
    hook_event = data.get('hook_event_name', '')
    tool_name = data.get('tool_name', data.get('tool', 'unknown'))
    tool_input = data.get('tool_input', {})
    tool_response = data.get('tool_response', {})
    session_id = data.get('session_id', 'unknown')

    # Determine event type
    event = 'tool_start' if 'Pre' in hook_event else 'tool_complete'

    # Build observation
    observation = {
        'timestamp': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
        'event': event,
        'tool': tool_name,
        'session': session_id
    }

    # Add input for tool_start events
    if event == 'tool_start' and tool_input:
        if isinstance(tool_input, dict):
            # Extract key fields only to keep size manageable
            input_summary = {}
            for key in ['command', 'file_path', 'pattern', 'query', 'prompt', 'description']:
                if key in tool_input:
                    val = tool_input[key]
                    input_summary[key] = val[:500] if isinstance(val, str) else val
            observation['input'] = input_summary if input_summary else str(tool_input)[:500]
        else:
            observation['input'] = str(tool_input)[:500]

    # Add truncated output for tool_complete events
    if event == 'tool_complete' and tool_response:
        if isinstance(tool_response, dict):
            # Extract stdout/stderr for Bash, or truncate content for Read
            output_summary = {}
            if 'stdout' in tool_response:
                output_summary['stdout'] = tool_response['stdout'][:200] if tool_response['stdout'] else ''
            if 'stderr' in tool_response and tool_response['stderr']:
                output_summary['stderr'] = tool_response['stderr'][:200]
            if output_summary:
                observation['output'] = output_summary
        else:
            observation['output'] = str(tool_response)[:200]

    # Write observation
    with open(observations_file, 'a') as f:
        f.write(json.dumps(observation) + '\n')

except json.JSONDecodeError as e:
    # Log parse error with truncated raw input
    observation = {
        'timestamp': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
        'event': 'parse_error',
        'error': str(e),
        'raw_length': len(raw_input) if 'raw_input' in dir() else 0
    }
    with open(observations_file, 'a') as f:
        f.write(json.dumps(observation) + '\n')
except Exception as e:
    with open('$ERROR_LOG', 'a') as f:
        f.write(f'{datetime.now(timezone.utc).strftime(\"%Y-%m-%dT%H:%M:%SZ\")} ERROR: {type(e).__name__}: {e}\n')
        f.write(f'  input_length={len(raw_input) if \"raw_input\" in dir() else \"N/A\"}\n')
        f.write(f'  input_preview={raw_input[:200] if \"raw_input\" in dir() else \"N/A\"}\n')
" 2>>"$ERROR_LOG"

# Signal observer if running
OBSERVER_PID_FILE="${CONFIG_DIR}/.observer.pid"
if [ -f "$OBSERVER_PID_FILE" ]; then
  observer_pid=$(cat "$OBSERVER_PID_FILE")
  if kill -0 "$observer_pid" 2>/dev/null; then
    kill -USR1 "$observer_pid" 2>/dev/null || true
  fi
fi
