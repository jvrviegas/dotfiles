#!/usr/bin/env bash

# monokai-pro - tmux theme

tmux set-option -gq status on
tmux set-option -gq status-bg "#19181a"
tmux set-option -gq status-fg "#c1c0c0"
tmux set-option -gq status-justify left
tmux set-option -gq status-left-length 100
tmux set-option -gq status-right-length 100

tmux set-option -gq message-style "fg=#fcfcfa,bg=#221f22,align=centre"
tmux set-option -gq message-command-style "fg=#fcfcfa,bg=#fc9867,align=centre"

tmux set-option -gq pane-border-style "fg=#5b595c"
tmux set-option -gq pane-active-border-style "fg=#fc9867"

tmux set-window-option -gq window-status-activity-style "fg=#a9dc76,bg=#221f22,none"
tmux set-window-option -gq window-status-separator ""
tmux set-window-option -gq window-status-style "fg=#c1c0c0,bg=#19181a,none"

tmux set-option -gq status-left "#[fg=#fc9867,bg=#19181a]#[fg=#19181a,bg=#fc9867,bold] ≡ #[fg=#fc9867,bg=#19181a] "

tmux set-option -gq status-right "#[fg=#ab9df2,bg=#19181a]#[fg=#19181a,bg=#ab9df2,bold] 󰅐 #[fg=#ab9df2,bg=#403e41]#[fg=#ab9df2,bg=#403e41] %Y-%m-%d %H:%M #[fg=#403e41,bg=#19181a]"

tmux set-window-option -gq window-status-format "#[fg=#939293,bg=#19181a]#[fg=#19181a,bg=#939293,bold] #I #[fg=#939293,bg=#221f22]#[fg=#939293,bg=#221f22] #W #[fg=#221f22,bg=#19181a]"

tmux set-window-option -gq window-status-current-format "#[fg=#a9dc76,bg=#19181a]#[fg=#19181a,bg=#a9dc76,bold] #I #[fg=#a9dc76,bg=#403e41]#[fg=#a9dc76,bg=#403e41] #W #[fg=#403e41,bg=#19181a]"
