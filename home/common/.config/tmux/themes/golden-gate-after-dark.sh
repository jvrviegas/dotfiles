#!/usr/bin/env bash

# Golden Gate After Dark - tmux theme

tmux set-option -gq status on
tmux set-option -gq status-bg "#101820"
tmux set-option -gq status-fg "#E58B65"
tmux set-option -gq status-justify left
tmux set-option -gq status-left-length 100
tmux set-option -gq status-right-length 100

tmux set-option -gq message-style "fg=#E3E7EA,bg=#1b2833,align=centre"
tmux set-option -gq message-command-style "fg=#E3E7EA,bg=#E58B65,align=centre"

tmux set-option -gq pane-border-style "fg=#354756"
tmux set-option -gq pane-active-border-style "fg=#E58B65"

tmux set-window-option -gq window-status-activity-style "fg=#E58B65,bg=#1b2833,none"
tmux set-window-option -gq window-status-separator ""
tmux set-window-option -gq window-status-style "fg=#E58B65,bg=#101820,none"

tmux set-option -gq status-left "#[fg=#E58B65,bg=#101820]#[fg=#101820,bg=#E58B65,bold] ≡ #[fg=#E58B65,bg=#101820] "

tmux set-option -gq status-right "#[fg=#E58B65,bg=#101820]#[fg=#101820,bg=#E58B65,bold] 󰅐 #[fg=#E58B65,bg=#354756]#[fg=#E58B65,bg=#354756] %Y-%m-%d %H:%M #[fg=#354756,bg=#101820]"

tmux set-window-option -gq window-status-format "#[fg=#858E91,bg=#101820]#[fg=#101820,bg=#858E91,bold] #I #[fg=#858E91,bg=#1b2833]#[fg=#858E91,bg=#1b2833] #W #[fg=#1b2833,bg=#101820]"

tmux set-window-option -gq window-status-current-format "#[fg=#E58B65,bg=#101820]#[fg=#101820,bg=#E58B65,bold] #I #[fg=#E58B65,bg=#354756]#[fg=#E58B65,bg=#354756] #W #[fg=#354756,bg=#101820]"
