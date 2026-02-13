#!/bin/bash
TITLE="Claude Code - 응답 대기"
MESSAGE="Claude가 사용자 입력을 기다리고 있습니다."
SOUND="Blow"
ICON="$HOME/.claude/icons/claude-logo.png"

if command -v terminal-notifier &>/dev/null; then
  terminal-notifier \
    -title "$TITLE" \
    -message "$MESSAGE" \
    -sound "$SOUND" \
    -contentImage "$ICON" \
    -group "claude-code-idle" \
    -activate com.microsoft.VSCode
else
  osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" sound name \"$SOUND\""
fi
