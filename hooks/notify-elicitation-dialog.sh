#!/bin/bash
TITLE="Claude Code - 입력 필요"
MESSAGE="MCP 도구 입력이 필요합니다. 터미널을 확인하세요."
SOUND="Ping"
ICON="$HOME/.claude/icons/claude-logo.png"

if [[ "$(uname -r)" == *microsoft* || "$(uname -r)" == *Microsoft* ]]; then
  if command -v wsl-notify-send &>/dev/null; then
    wsl-notify-send --category "$TITLE" "$MESSAGE"
  else
    powershell.exe -Command "New-BurntToastNotification -Text '$TITLE','$MESSAGE' -AppLogo '$(wslpath -w "$ICON" 2>/dev/null || echo "$ICON")'" 2>/dev/null \
      || powershell.exe -Command "[void][Windows.UI.Notifications.ToastNotificationManager,Windows.UI.Notifications,ContentType=WindowsRuntime];\$t=[Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent(0);\$t.GetElementsByTagName('text').Item(0).AppendChild(\$t.CreateTextNode('$TITLE - $MESSAGE'))>[System.Void];\$n=[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Claude Code');\$n.Show(\$t)"
  fi
elif command -v terminal-notifier &>/dev/null; then
  terminal-notifier \
    -title "$TITLE" \
    -message "$MESSAGE" \
    -sound "$SOUND" \
    -contentImage "$ICON" \
    -group "claude-code-elicitation" \
    -activate com.microsoft.VSCode
else
  osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" sound name \"$SOUND\""
fi
