
git clone --depth 1 https://github.com/Licay/misc_files.git $HOME/.config/casey_files

env_file=$HOME/.config/casey_files/scripts/env_normal.sh

echo "if [ -e $env_file ]; then . $env_file; fi " >> $HOME/.zshrc
