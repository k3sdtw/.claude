#!/bin/bash
TITLE="Claude Code - 인증 성공"
MESSAGE="인증이 완료되었습니다."
SOUND="Glass"
ICON="$HOME/.claude/icons/claude-logo.png"

if command -v terminal-notifier &>/dev/null; then
  terminal-notifier \
    -title "$TITLE" \
    -message "$MESSAGE" \
    -sound "$SOUND" \
    -contentImage "$ICON" \
    -group "claude-code-auth"
else
  osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" sound name \"$SOUND\""
fi
