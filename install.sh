
# Dotfiles
echo "• Putting dotfiles in your home path: $HOME"

files=(
  "./.aliases"
  "./.exports"
  "./.gitconfig"
  "./.local"
  "./.zshrc"
  "./.zsh_profile"
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

if [[ -r "$HOME/.local/share/nvim/plugged" ]]; then
  echo "  - Packer.nvim already installed. Lets install the plugins"
  nvim +PackerInstall +qall
  echo "  - Done installing the Plugins"

else
  echo "  - Lets install Packer.nvim Manager"
  git clone --depth 1 https://github.com/wbthomason/packer.nvim\
    ~/.local/share/nvim/site/pack/packer/start/packer.nvim
  nvim +PackerInstall +qall
  echo " - Done installing the Plugins"
fi;
