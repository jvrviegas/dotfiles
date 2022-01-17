
# Dotfiles
echo "• Putting dotfiles in your home path: $HOME"

files=(
  #"./.aliases"
  #"./.exports"
  "./.gitconfig"
	"./.config"
#  "./.gitignore"
#  "./.screenrc"
#  "./.vim"
#  "./.vimrc"
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
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  echo "  - Done installing Homebrew"
fi;

echo "• Install Homebrew apps"
source brew.sh
echo ""

# Preparing NeoVim and VIM Plug 
echo "• Preparing NeoVim and Plugins"

if [[ -r "$HOME/.config/nvim/plugged" ]]; then
  echo "  - VIM Plug already installed. Lets install the plugins"
  nvim +PlugInstall +qall
  echo "  - Done installing the Plugins"

else
  echo "  - Lets install VIM Plug Manager"
  curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  nvim +PlugInstall +qall
  echo " - Done installing the Plugins"
fi;


