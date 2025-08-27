
# Dotfiles
echo "• Putting dotfiles in your home path: $HOME"

files=(
  # "./.aliases"
  # "./.exports"
  "./.gitconfig"
  "./.local"
  "./.config"
  "./.zshrc"
  "./.zsh_profile"
  "./.zshenv"
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


# Git configuration
echo "• Git / GitHub configuration"
read -p "  - What your Git user.name? " git_name
git config --global user.name "$git_name"

read -p "  - What your Git user.email? " git_email
git config --global user.email $git_email
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
source brew.sh
echo ""

echo "• Cloning Neovim configs"
if [[ ! -r "$HOME/.config/nvim" ]]; then
    mkdir "$HOME/.config/nvim"
fi
git clone https://github.com/jvrviegas/nvim-config "$HOME/.config/nvim/"


# Preparing NeoVim and Packer
echo "• Preparing NeoVim and Plugins"
git clone https://github.com/jvrviegas/nvim-config.git ~/.config/nvim
