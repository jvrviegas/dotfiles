#!/usr/bin/env bash

# Gruvbox (dark, hard) - tmux theme

BG0="#1d2021"
BG1="#3c3836"
BG2="#504945"
BG3="#665c54"
FG0="#fbf1c7"
FG1="#ebdbb2"
FG4="#a89984"
GRAY="#928374"
ORANGE="#fe8019"
ORANGE_DIM="#d65d0e"
AQUA="#8ec07c"
YELLOW="#fabd2f"
GREEN="#b8bb26"

# tmux theme
tmux set-option -gq status on
tmux set-option -gq status-bg "$BG0"
tmux set-option -gq status-fg "$FG4"
tmux set-option -gq status-justify left
tmux set-option -gq status-left-length 100
tmux set-option -gq status-right-length 100

tmux set-option -gq message-style "fg=$FG1,bg=$BG1,align=centre"
tmux set-option -gq message-command-style "fg=$BG0,bg=$ORANGE,align=centre"

tmux set-option -gq pane-border-style "fg=$BG2"
tmux set-option -gq pane-active-border-style "fg=$ORANGE"

tmux set-window-option -gq window-status-activity-style "fg=$YELLOW,bg=$BG1,none"
tmux set-window-option -gq window-status-separator ""
tmux set-window-option -gq window-status-style "fg=$FG4,bg=$BG0,none"

tmux set-option -gq status-left "#[fg=$ORANGE,bg=$BG0]#[fg=$BG0,bg=$ORANGE,bold] 󰊠 #[fg=$ORANGE,bg=$BG0] "

tmux set-option -gq status-right "#[fg=$AQUA,bg=$BG0]#[fg=$BG0,bg=$AQUA,bold] 󰅐 #[fg=$AQUA,bg=$BG1]#[fg=$FG1,bg=$BG1] %Y-%m-%d %H:%M #[fg=$BG1,bg=$BG0]"

tmux set-window-option -gq window-status-format "#[fg=$GRAY,bg=$BG0]#[fg=$BG0,bg=$GRAY,bold] #I #[fg=$GRAY,bg=$BG1]#[fg=$FG4,bg=$BG1] #W #[fg=$BG1,bg=$BG0]"

tmux set-window-option -gq window-status-current-format "#[fg=$ORANGE,bg=$BG0]#[fg=$BG0,bg=$ORANGE,bold] #I #[fg=$ORANGE,bg=$BG2]#[fg=$FG0,bg=$BG2] #W #[fg=$BG2,bg=$BG0]"
