#!/bin/bash
TITLE="Claude Code - 권한 요청"
MESSAGE="권한 승인이 필요합니다. 터미널을 확인하세요."
SOUND="Ping"
ICON="$HOME/.claude/icons/claude-logo.png"

if command -v terminal-notifier &>/dev/null; then
  terminal-notifier \
    -title "$TITLE" \
    -message "$MESSAGE" \
    -sound "$SOUND" \
    -contentImage "$ICON" \
    -group "claude-code-permission" \
    -activate com.microsoft.VSCode
else
  osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" sound name \"$SOUND\""
fi
