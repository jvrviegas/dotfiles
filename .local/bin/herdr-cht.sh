#!/usr/bin/env bash

selected=$(cat "$HOME/.tmux-cht-languages" "$HOME/.tmux-cht-command" | fzf)
[[ -z ${selected:-} ]] && exit 0

read -r -p "Enter Query: " query

if grep -Fqx "$selected" "$HOME/.tmux-cht-languages"; then
  query=${query// /+}
  url="https://cht.sh/${selected}/${query}/"
else
  url="https://cht.sh/${selected}~${query}"
fi

printf '%s\n\n' "$url"
curl -fsSL "$url" | less -R
