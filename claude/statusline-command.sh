#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract values from JSON
model=$(echo "$input" | jq -r '.model.display_name')
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens')
context_size=$(echo "$input" | jq -r '.context_window.context_window_size')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')

# Calculate consumed tokens
consumed=$((total_input + total_output))

# Determine color based on usage percentage
# Green: below 25%, Yellow: 26-50%, Red: above 50%
if (( $(echo "$used_pct < 25" | bc -l) )); then
    color="\033[32m"  # Green
elif (( $(echo "$used_pct <= 50" | bc -l) )); then
    color="\033[33m"  # Yellow
else
    color="\033[31m"  # Red
fi
reset="\033[0m"  # Reset color

# Format and print the statusline with color
printf "$model | %s | Context: ${color}%'d / %'d tokens (%.1f%% used)${reset}" \
    "$(basename "$cwd")" \
    "$consumed" \
    "$context_size" \
    "$used_pct"
