#!/usr/bin/env bash

# Darth Vader - tmux theme

VOID="#08080a"
CHAMBER="#0e0e12"
ARMOR="#16161c"
DURASTEEL="#26262e"
IMPERIAL="#d8d8dc"
TROOPER="#b4b4bc"
HULL="#90909a"
SABER="#d43a3a"
BLADE="#ef4f4f"
RIMLIGHT="#7ee6e6"
CYAN="#3f9e9e"
PANEL="#e0bc63"
CONSOLE="#79c987"

# tmux theme
tmux set-option -gq status on
tmux set-option -gq status-bg "$VOID"
tmux set-option -gq status-fg "$HULL"
tmux set-option -gq status-justify left
tmux set-option -gq status-left-length 100
tmux set-option -gq status-right-length 100

tmux set-option -gq message-style "fg=$IMPERIAL,bg=$CHAMBER,align=centre"
tmux set-option -gq message-command-style "fg=$VOID,bg=$SABER,align=centre"

tmux set-option -gq pane-border-style "fg=$DURASTEEL"
tmux set-option -gq pane-active-border-style "fg=$SABER"

tmux set-window-option -gq window-status-activity-style "fg=$BLADE,bg=$CHAMBER,none"
tmux set-window-option -gq window-status-separator ""
tmux set-window-option -gq window-status-style "fg=$HULL,bg=$VOID,none"

tmux set-option -gq status-left "#[fg=$SABER,bg=$VOID]#[fg=$VOID,bg=$SABER,bold] 󱎃 #[fg=$SABER,bg=$VOID] "

tmux set-option -gq status-right "#[fg=$RIMLIGHT,bg=$VOID]#[fg=$VOID,bg=$RIMLIGHT,bold] 󰅐 #[fg=$RIMLIGHT,bg=$ARMOR]#[fg=$TROOPER,bg=$ARMOR] %Y-%m-%d %H:%M #[fg=$ARMOR,bg=$VOID]"

tmux set-window-option -gq window-status-format "#[fg=$HULL,bg=$VOID]#[fg=$VOID,bg=$HULL,bold] #I #[fg=$HULL,bg=$CHAMBER]#[fg=$HULL,bg=$CHAMBER] #W #[fg=$CHAMBER,bg=$VOID]"

tmux set-window-option -gq window-status-current-format "#[fg=$BLADE,bg=$VOID]#[fg=$VOID,bg=$BLADE,bold] #I #[fg=$BLADE,bg=$ARMOR]#[fg=$BLADE,bg=$ARMOR] #W #[fg=$ARMOR,bg=$VOID]"
