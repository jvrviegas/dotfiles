
# Dotfiles
echo "• Putting dotfiles in your home path: $HOME"

files=(
  "./.gitconfig"
  "./.tmux.conf"
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
# Add NVM setup to .zshrc
echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.config/zsh/.zshrc
echo '[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm' >> ~/.config/zsh/.zshrc
echo '[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion' >> ~/.config/zsh/.zshrc

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

echo "• Installing Node LTS and PNPM"
source node.sh
echo ""

echo "• Installing zsh plugins"
source .config/zsh/zap_zsh.sh
