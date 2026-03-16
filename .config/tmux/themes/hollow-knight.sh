#!/usr/bin/env bash

# hollow-knight - tmux theme

tmux set-option -gq status on
tmux set-option -gq status-bg "#0d0d14"
tmux set-option -gq status-fg "#a8a8c0"
tmux set-option -gq status-justify left
tmux set-option -gq status-left-length 100
tmux set-option -gq status-right-length 100

tmux set-option -gq message-style "fg=#e8e8f0,bg=#1a1a24,align=centre"
tmux set-option -gq message-command-style "fg=#e8e8f0,bg=#e8c84f,align=centre"

tmux set-option -gq pane-border-style "fg=#3a3a4a"
tmux set-option -gq pane-active-border-style "fg=#e8c84f"

tmux set-window-option -gq window-status-activity-style "fg=#7bb8e8,bg=#1a1a24,none"
tmux set-window-option -gq window-status-separator ""
tmux set-window-option -gq window-status-style "fg=#a8a8c0,bg=#0d0d14,none"

tmux set-option -gq status-left "#[fg=#e8c84f,bg=#0d0d14]#[fg=#0d0d14,bg=#e8c84f,bold] ≡ #[fg=#e8c84f,bg=#0d0d14] "

tmux set-option -gq status-right "#[fg=#5db898,bg=#0d0d14]#[fg=#0d0d14,bg=#5db898,bold] 󰅐 #[fg=#5db898,bg=#2a2a3a]#[fg=#5db898,bg=#2a2a3a] %Y-%m-%d %H:%M #[fg=#2a2a3a,bg=#0d0d14]"

tmux set-window-option -gq window-status-format "#[fg=#888898,bg=#0d0d14]#[fg=#0d0d14,bg=#888898,bold] #I #[fg=#888898,bg=#1a1a24]#[fg=#888898,bg=#1a1a24] #W #[fg=#1a1a24,bg=#0d0d14]"

tmux set-window-option -gq window-status-current-format "#[fg=#7bb8e8,bg=#0d0d14]#[fg=#0d0d14,bg=#7bb8e8,bold] #I #[fg=#7bb8e8,bg=#2a2a3a]#[fg=#7bb8e8,bg=#2a2a3a] #W #[fg=#2a2a3a,bg=#0d0d14]"
