#!/usr/bin/env bash

# The Mandalorian - tmux theme

tmux set-option -gq status on
tmux set-option -gq status-bg "#0a0a0f"
tmux set-option -gq status-fg "#acacba"
tmux set-option -gq status-justify left
tmux set-option -gq status-left-length 100
tmux set-option -gq status-right-length 100

tmux set-option -gq message-style "fg=#e4e4ec,bg=#15151d,align=centre"
tmux set-option -gq message-command-style "fg=#e4e4ec,bg=#e89858,align=centre"

tmux set-option -gq pane-border-style "fg=#2d2d3a"
tmux set-option -gq pane-active-border-style "fg=#e89858"

tmux set-window-option -gq window-status-activity-style "fg=#e8c070,bg=#15151d,none"
tmux set-window-option -gq window-status-separator ""
tmux set-window-option -gq window-status-style "fg=#acacba,bg=#0a0a0f,none"

tmux set-option -gq status-left "#[fg=#e89858,bg=#0a0a0f]#[fg=#0a0a0f,bg=#e89858,bold] ≡ #[fg=#e89858,bg=#0a0a0f] "

tmux set-option -gq status-right "#[fg=#d4b896,bg=#0a0a0f]#[fg=#0a0a0f,bg=#d4b896,bold] 󰅐 #[fg=#d4b896,bg=#20202b]#[fg=#d4b896,bg=#20202b] %Y-%m-%d %H:%M #[fg=#20202b,bg=#0a0a0f]"

tmux set-window-option -gq window-status-format "#[fg=#8c8c9a,bg=#0a0a0f]#[fg=#0a0a0f,bg=#8c8c9a,bold] #I #[fg=#8c8c9a,bg=#15151d]#[fg=#8c8c9a,bg=#15151d] #W #[fg=#15151d,bg=#0a0a0f]"

tmux set-window-option -gq window-status-current-format "#[fg=#e8c070,bg=#0a0a0f]#[fg=#0a0a0f,bg=#e8c070,bold] #I #[fg=#e8c070,bg=#20202b]#[fg=#e8c070,bg=#20202b] #W #[fg=#20202b,bg=#0a0a0f]"
