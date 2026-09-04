#!/bin/bash
# Reads Claude Code notification JSON from stdin and sends a macOS notification
# Skips if the user is focused on this instance (Ghostty focused + tmux pane active)
input=$(cat)

# Check if Ghostty is the frontmost app
front_app=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null)

# Check if the current tmux pane is active
pane_active=$(tmux display-message -p '#{pane_active}' 2>/dev/null)

if [[ "$front_app" == "Ghostty" && "$pane_active" == "1" ]]; then
  exit 0
fi

message=$(echo "$input" | jq -r '.message // "Task complete"')
cwd=$(echo "$input" | jq -r '.cwd // ""')
project=$(basename "$cwd")

osascript -e "display notification \"$message\" with title \"Claude Code — $project\""
