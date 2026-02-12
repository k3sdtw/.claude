#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null)

# Allow edits to ~/.claude/ files
case "$FILE_PATH" in
  $HOME/.claude/*) exit 0;;
esac

# Determine branch from the file's directory, not CWD
if [ -n "$FILE_PATH" ] && [ -e "$(dirname "$FILE_PATH")" ]; then
  BRANCH=$(git -C "$(dirname "$FILE_PATH")" branch --show-current 2>/dev/null)
else
  BRANCH=$(git branch --show-current 2>/dev/null)
fi

# Block edits on main branch
if [ "$BRANCH" = "main" ]; then
  echo '{"block": true, "message": "Cannot edit on main branch. Create a feature branch first."}' >&2
  exit 2
fi
