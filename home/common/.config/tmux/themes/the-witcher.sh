#!/usr/bin/env bash

# The Witcher - tmux theme

KAER="#0b0f12"
KEEP="#12181c"
STONE="#1b2428"
IRON="#2a363b"
SILVER="#d8d3c5"
STEEL="#c1bbaa"
DULL="#827d72"
AMBER="#d89a2b"
GOLD="#e0b85f"
POTION="#8fcf4f"
AARD="#7f9aa3"
IGNI="#c56b2c"
BLOOD="#d75f4f"

# tmux theme
tmux set-option -gq status on
tmux set-option -gq status-bg "$KAER"
tmux set-option -gq status-fg "$DULL"
tmux set-option -gq status-justify left
tmux set-option -gq status-left-length 100
tmux set-option -gq status-right-length 100

tmux set-option -gq message-style "fg=$SILVER,bg=$KEEP,align=centre"
tmux set-option -gq message-command-style "fg=$KAER,bg=$AMBER,align=centre"

tmux set-option -gq pane-border-style "fg=$IRON"
tmux set-option -gq pane-active-border-style "fg=$AMBER"

tmux set-window-option -gq window-status-activity-style "fg=$GOLD,bg=$KEEP,none"
tmux set-window-option -gq window-status-separator ""
tmux set-window-option -gq window-status-style "fg=$DULL,bg=$KAER,none"

tmux set-option -gq status-left "#[fg=$AMBER,bg=$KAER]#[fg=$KAER,bg=$AMBER,bold] 󰀘 #[fg=$AMBER,bg=$KAER] "

tmux set-option -gq status-right "#[fg=$POTION,bg=$KAER]#[fg=$KAER,bg=$POTION,bold] 󰅐 #[fg=$POTION,bg=$STONE]#[fg=$STEEL,bg=$STONE] %Y-%m-%d %H:%M #[fg=$STONE,bg=$KAER]"

tmux set-window-option -gq window-status-format "#[fg=$DULL,bg=$KAER]#[fg=$KAER,bg=$DULL,bold] #I #[fg=$DULL,bg=$KEEP]#[fg=$DULL,bg=$KEEP] #W #[fg=$KEEP,bg=$KAER]"

tmux set-window-option -gq window-status-current-format "#[fg=$GOLD,bg=$KAER]#[fg=$KAER,bg=$GOLD,bold] #I #[fg=$GOLD,bg=$STONE]#[fg=$GOLD,bg=$STONE] #W #[fg=$STONE,bg=$KAER]"
