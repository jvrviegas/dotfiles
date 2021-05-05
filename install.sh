
# Dotfiles
echo "• Putting dotfiles in your home path: $HOME"

files=(
#  "./.aliases"
#  "./.exports"
  "./.gitconfig"
#  "./.gitignore"
#  "./.screenrc"
  "./.vim"
  "./.vimrc"
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

#echo "• Install Homebrew apps"
#source brew.sh
#echo ""

# Preparing VIM and VIM Plug 
echo "• Preparing Vim and Plugins"

if [[ -r "$HOME/.vim/plugged" ]]; then
  echo "  - VIM Plug already installed. Lets install the plugins"
  vim +PlugInstall +qall
  echo "  - Done installing the Plugins"

else
  echo "  - Lets install VIM Plug Manager"
  curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  vim +PlugInstall +qall
  echo " - Done installing the Plugins"
fi;

