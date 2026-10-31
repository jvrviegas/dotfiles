#!/usr/bin/env bash

# Obsidian Glass - tmux theme

tmux set-option -gq status on
tmux set-option -gq status-bg "#08090A"
tmux set-option -gq status-fg "#BACACD"
tmux set-option -gq status-justify left
tmux set-option -gq status-left-length 100
tmux set-option -gq status-right-length 100

tmux set-option -gq message-style "fg=#E4E9E8,bg=#151719,align=centre"
tmux set-option -gq message-command-style "fg=#E4E9E8,bg=#BACACD,align=centre"

tmux set-option -gq pane-border-style "fg=#303538"
tmux set-option -gq pane-active-border-style "fg=#BACACD"

tmux set-window-option -gq window-status-activity-style "fg=#BACACD,bg=#151719,none"
tmux set-window-option -gq window-status-separator ""
tmux set-window-option -gq window-status-style "fg=#BACACD,bg=#08090A,none"

tmux set-option -gq status-left "#[fg=#BACACD,bg=#08090A]#[fg=#08090A,bg=#BACACD,bold] ≡ #[fg=#BACACD,bg=#08090A] "

tmux set-option -gq status-right "#[fg=#BACACD,bg=#08090A]#[fg=#08090A,bg=#BACACD,bold] 󰅐 #[fg=#BACACD,bg=#303538]#[fg=#BACACD,bg=#303538] %Y-%m-%d %H:%M #[fg=#303538,bg=#08090A]"

tmux set-window-option -gq window-status-format "#[fg=#858E91,bg=#08090A]#[fg=#08090A,bg=#858E91,bold] #I #[fg=#858E91,bg=#151719]#[fg=#858E91,bg=#151719] #W #[fg=#151719,bg=#08090A]"

tmux set-window-option -gq window-status-current-format "#[fg=#BACACD,bg=#08090A]#[fg=#08090A,bg=#BACACD,bold] #I #[fg=#BACACD,bg=#303538]#[fg=#BACACD,bg=#303538] #W #[fg=#303538,bg=#08090A]"
