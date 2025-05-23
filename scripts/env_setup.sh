#!/bin/bash
# Author: Casey
# Date: 2025-01-09
# Description: This script sets up the environment variables required for the workspace.

# 检查当前用户是否是 root 用户
if [ "$(id -u)" -eq 0 ]; then
  echo "请不要使用 root 用户运行此脚本"
  exit 1
fi

LOCAL_DIR=~/.local/bin
mkdir -p $LOCAL_DIR

sudo apt update
sudo apt install git gcc make repo vim adb fastboot minicom tree htop zsh remmina universal-ctags \
cifs-utils nfs-common \
unrar python3 filezilla \
gnome-tweaks gnome-shell-extension-manager \
ibus-rime

# for kernel build
# sudo apt install \
# libncurses-dev flex bison libssl-dev libelf-dev bc cpio xz-utils

# 输入法 不要使用sudo
git clone --depth 1 https://github.com/gaboolic/rime-frost ~/.config/ibus/rime
# 以下为自用配置，需要更改自行打开~/.config/ibus/rime/default.yaml查看
RIME_DEF_CONFIG=~/.config/ibus/rime/default.yaml
sed -i '/schema:/ s/^/#/' $RIME_DEF_CONFIG
sed -i '/schema_list:/a\  - schema: double_pinyin          # 自然码双拼\
  - schema: rime_ice               # 雾凇拼音（全拼）' $RIME_DEF_CONFIG
sed -i 's/page_size: [0-9]*/page_size: 6/' $RIME_DEF_CONFIG

# docker
curl -fsSL https://test.docker.com -o test-docker.sh
sudo sh test-docker.sh

sudo apt install curl software-properties-common apt-transport-https ca-certificates wget
curl -fSsL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor | sudo tee /usr/share/keyrings/microsoft-edge.gpg > /dev/null
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-edge.gpg] https://packages.microsoft.com/repos/edge stable main' | sudo tee /etc/apt/sources.list.d/microsoft-edge.list
sudo apt update
# sudo apt install microsoft-edge-stable

curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor | sudo tee /usr/share/keyrings/vscode.gpg > /dev/null
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/vscode.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
sudo apt update

sudo apt install code \
microsoft-edge-stable \
snap flatpak

# sudo snap install bytedance-feishu-stable
sudo snap install onlyoffice-desktopeditors
# sudo snap install obsidian --classic
flatpak install flathub md.obsidian.Obsidian
# flatpak install flathub cn.feishu.Feishu    # 不显示通知

# oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# wine-hq
# sudo apt install dirmngr ca-certificates curl software-properties-common apt-transport-https
# sudo dpkg --add-architecture i386
# curl -s https://dl.winehq.org/wine-builds/winehq.key | sudo gpg --dearmor | sudo tee /usr/share/keyrings/winehq.gpg > /dev/null
# echo deb [signed-by=/usr/share/keyrings/winehq.gpg] http://dl.winehq.org/wine-builds/ubuntu/ $(lsb_release -cs) main | sudo tee /etc/apt/sources.list.d/winehq.list
# sudo apt update

# set user group
sudo usermod -aG dialout $USER  # for serial port

# snipaste
wget https://dl.snipaste.com/linux-cn -O $LOCAL_DIR/Snipaste.AppImage
# wget https://download.snipaste.com/archives/Snipaste-2.10.6-x86_64.AppImage -O $LOCAL_DIR/Snipaste.AppImage
chmod +x $LOCAL_DIR/Snipaste.AppImage
$LOCAL_DIR/Snipaste.AppImage exit
$LOCAL_DIR/Snipaste.AppImage &
disown %1
