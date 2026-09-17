#!/usr/bin/env bash

# Red Dead Redemption 2 - tmux theme

FRONTIER="#1a1410"
CAMP="#1f1813"
LEATHER="#261e17"
IRON="#3d3229"
PARCHMENT="#e4d8c2"
WORN="#c4b4a0"
AGED="#a89880"
DEADEYE="#c4732e"
GOLDEN="#e0a040"
PRAIRIE="#8aaa4a"
GUNMETAL="#8a9ca8"
CAMPFIRE="#c46a2e"
WOUND="#c84a3c"

# tmux theme
tmux set-option -gq status on
tmux set-option -gq status-bg "$FRONTIER"
tmux set-option -gq status-fg "$AGED"
tmux set-option -gq status-justify left
tmux set-option -gq status-left-length 100
tmux set-option -gq status-right-length 100

tmux set-option -gq message-style "fg=$PARCHMENT,bg=$CAMP,align=centre"
tmux set-option -gq message-command-style "fg=$FRONTIER,bg=$DEADEYE,align=centre"

tmux set-option -gq pane-border-style "fg=$IRON"
tmux set-option -gq pane-active-border-style "fg=$DEADEYE"

tmux set-window-option -gq window-status-activity-style "fg=$GOLDEN,bg=$CAMP,none"
tmux set-window-option -gq window-status-separator ""
tmux set-window-option -gq window-status-style "fg=$AGED,bg=$FRONTIER,none"

tmux set-option -gq status-left "#[fg=$DEADEYE,bg=$FRONTIER]#[fg=$FRONTIER,bg=$DEADEYE,bold] 🤠 #[fg=$DEADEYE,bg=$FRONTIER] "

tmux set-option -gq status-right "#[fg=$PRAIRIE,bg=$FRONTIER]#[fg=$FRONTIER,bg=$PRAIRIE,bold] 󰅐 #[fg=$PRAIRIE,bg=$LEATHER]#[fg=$WORN,bg=$LEATHER] %Y-%m-%d %H:%M #[fg=$LEATHER,bg=$FRONTIER]"

tmux set-window-option -gq window-status-format "#[fg=$AGED,bg=$FRONTIER]#[fg=$FRONTIER,bg=$AGED,bold] #I #[fg=$AGED,bg=$CAMP]#[fg=$AGED,bg=$CAMP] #W #[fg=$CAMP,bg=$FRONTIER]"

tmux set-window-option -gq window-status-current-format "#[fg=$GOLDEN,bg=$FRONTIER]#[fg=$FRONTIER,bg=$GOLDEN,bold] #I #[fg=$GOLDEN,bg=$LEATHER]#[fg=$GOLDEN,bg=$LEATHER] #W #[fg=$LEATHER,bg=$FRONTIER]"
