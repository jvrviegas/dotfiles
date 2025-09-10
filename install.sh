
# Dotfiles
echo "• Putting dotfiles in your home path: $HOME"

files=(
  "./.gitconfig"
  "./.tmux.conf"
  "./.local"
  "./.config"
  "./zsh/.zshrc"
  "./zsh/.zsh_profile"
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
echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
echo '[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm' >> ~/.zshrc
echo '[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion' >> ~/.zshrc

echo "• Cloning Neovim configs"
if [[ ! -r "$HOME/.config/nvim" ]]; then
    mkdir "$HOME/.config/nvim"
fi
if [[ ! -r "$HOME/.config/nvim/init.lua" ]]; then
    git clone https://github.com/jvrviegas/nvim-config "$HOME/.config/nvim/"
fi
echo ""

echo "• Installing Node LTS and PNPM"
source node.sh
echo ""

echo "• Installing zsh plugins"
source zsh/zap_zsh.sh
