#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null)

# Allow edits to ~/.claude/ files
case "$FILE_PATH" in
  $HOME/.claude/*) exit 0;;
esac

# Block edits on main branch
if [ "$(git branch --show-current)" = "main" ]; then
  echo '{"block": true, "message": "Cannot edit on main branch. Create a feature branch first."}' >&2
  exit 2
fi
