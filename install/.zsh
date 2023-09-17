# install oh my zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

zdot="${ZDOTDIR:-$HOME}"
$zdot/.zshrc

# 替换样本库中的插件
sed -i 's/plugins=(git)/plugins=(
git
zsh-syntax-highlighting
zsh-autosuggestions
autojump
)/g' $zdot/.zshrc
