
# Dotfiles
echo "• Putting dotfiles in your home path: $HOME"

files=(
  "./.gitconfig"
  "./.tmux.conf"
  "./.tmux-cht-languages"
  "./.tmux-cht-command"
  "./.zshenv"
  "./.local"
  "./.config"
)

for file in ${files[@]}; do
    if [[ $(file $file | awk '{print $2}') == "directory" ]]; then
      [ -r "$file" ] && cp -r "$file" $HOME && echo "  - Copied folder $file"

    else
      [ -r "$file" ] && cp "$file" $HOME && echo "  - Copied file $file"
    fi;
done;
unset file files;
echo ""


# Homebrew
echo "• Check if Homebrew is installed"

if [[ $(which brew) != "" ]]; then
  echo "  - Homebrew already installed"
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add Homebrew to your PATH in ~/.zprofile:
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
  echo "  - Done installing Homebrew"
fi;

echo "• Install Homebrew apps"
source brew/formulae.sh
source brew/cask.sh
echo ""

echo "• NVM Setup"
# Add NVM setup to .zshrc (only if not already present)
if ! grep -q 'NVM_DIR' ~/.config/zsh/.zshrc 2>/dev/null; then
  echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.config/zsh/.zshrc
  echo '[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm' >> ~/.config/zsh/.zshrc
  echo '[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion' >> ~/.config/zsh/.zshrc
  echo "  - NVM setup added to .zshrc"
else
  echo "  - NVM setup already present in .zshrc"
fi

echo "• Setting up Neovim config symlink"
# Backup existing nvim config if it exists and is not already a symlink
if [[ -d "$HOME/.config/nvim" ]] && [[ ! -L "$HOME/.config/nvim" ]]; then
    mv "$HOME/.config/nvim" "$HOME/.config/nvim-old"
    echo "  - Backed up existing nvim config to $HOME/.config/nvim-old"
fi
# Create symlink to nvim config in dotfiles repo
if [[ ! -e "$HOME/.config/nvim" ]]; then
    ln -s "$(pwd)/.config/nvim" "$HOME/.config/nvim"
    echo "  - Created symlink from $HOME/.config/nvim to $(pwd)/.config/nvim"
else
    echo "  - Symlink already exists"
fi
echo ""

echo "• Setting up theme system"
mkdir -p "$HOME/.config/theme"
mkdir -p "$HOME/.config/tmux/themes"
mkdir -p "$HOME/.config/wallpapers"
cp "$(pwd)/.config/tmux/themes/"*.sh "$HOME/.config/tmux/themes/"
chmod +x "$HOME/.config/tmux/themes/"*.sh
if [ ! -f "$HOME/.config/theme/current" ]; then
  echo "the-mandalorian" > "$HOME/.config/theme/current"
fi
CURRENT_THEME=$(cat "$HOME/.config/theme/current")
if [ -f "$HOME/.config/tmux/themes/${CURRENT_THEME}.sh" ]; then
  cp "$HOME/.config/tmux/themes/${CURRENT_THEME}.sh" "$HOME/.config/tmux/themes/current.sh"
fi
echo "  - Theme set to: $CURRENT_THEME"
echo ""


echo "• Installing Node LTS and PNPM"
source node.sh
echo ""

echo "• Installing zsh plugins"
source .config/zsh/zap_zsh.sh

echo ""
echo "• Window Manager Setup"
echo "  Choose your window manager:"
echo "    1) AeroSpace (recommended — no SIP disable, single config)"
echo "    2) yabai + skhd (requires SIP partially disabled)"
echo "    3) Skip"
read -rp "  Enter choice [1/2/3]: " wm_choice

case "$wm_choice" in
  1)
    echo "  - Installing AeroSpace"
    brew install --cask nikitabobko/tap/aerospace
    brew tap FelixKratz/formulae
    brew install sketchybar
    # Stop yabai/skhd if running
    yabai --stop-service 2>/dev/null
    skhd --stop-service 2>/dev/null
    killall yabai 2>/dev/null
    killall skhd 2>/dev/null
    # Start AeroSpace and sketchybar
    open -a AeroSpace
    brew services start sketchybar
    echo "  - AeroSpace setup complete"
    ;;
  2)
    echo "  - Installing yabai + skhd"
    source brew/wm.sh
    # Stop AeroSpace if running
    killall AeroSpace 2>/dev/null
    echo "  - yabai + skhd setup complete"
    ;;
  3)
    echo "  - Skipping window manager setup"
    ;;
  *)
    echo "  - Invalid choice, skipping window manager setup"
    ;;
esac
