#!/usr/bin/env bash

# Script for installing desktop environment for python/C/C++
# development on bare Debian 12 bookworm

URL_DOTFILES="https://github.com/a-shahov/dotfiles.git"

display_usage() {
    echo 'Usage : install.sh -u <username> -p <password>'
    exit 1
}

if [[ "$(id -u)" != 0 ]] then
    echo 'script requires root privileges'
    exit 1
fi

if [[ -z $4 ]] then
    display_usage
fi

while [[ "$1" != "" ]]; do
    case $1 in
	-u) shift 1; USERNAME=$1 ;;
	-p) shift 1; PASSWORD=$1 ;;
    esac
    shift 1
done

if [[ "$PASSWORD" == "" ]] || [[ "$USERNAME" == "" ]] then
    display_usage
fi

HOME_DIR="/home/$USERNAME"

install_packages() {
    apt-get update && apt-get dist-upgrade -y
    apt-get build-dep -y python3
    apt-get install -y sudo zsh git zip unzip neovim build-essential wget curl \
	    xorg libpangocairo-1.0-0 libxcb1 libcairo2 libgdk-pixbuf-2.0-0 \
	    pkg-config gdb lcov libbz2-dev libffi-dev libgdbm-dev libgdbm-compat-dev liblzma-dev \
	    libncurses5-dev libreadline6-dev libsqlite3-dev libssl-dev lzma lzma-dev tk-dev uuid-dev zlib1g-dev
}

create_user() {
    # Creating user
    mkdir "$HOME_DIR"

    useradd --home-dir $HOME_DIR --groups sudo --shell /usr/bin/zsh $USERNAME
    echo "$USERNAME:$PASSWORD" | chpasswd 
    chown -R $USERNAME:$USERNAME $HOME_DIR

    # generate ssh keys
    sudo -u $USERNAME ssh-keygen -t ed25519 -N "" -f $HOME_DIR/.ssh/id_ed25519 <<< $'\ny'
}

install_dotfiles() {
    # Install dotfiles
    git clone $URL_DOTFILES
    mv $(pwd)/dotfiles "$HOME_DIR/"
    chown -R $USERNAME:$USERNAME $HOME_DIR/dotfiles
    sudo -u $USERNAME $HOME_DIR/dotfiles/install -c user.conf.yaml
    git config --global --add safe.directory $HOME_DIR/dotfiles
    git config --global --add safe.directory $HOME_DIR/dotfiles/dotbot
    $HOME_DIR/dotfiles/install -c admin.conf.yaml
    rm ~/.gitconfig
}

install_packages
create_user
install_dotfiles

cp install_as_user.sh $HOME_DIR/
chown $USERNAME:$USERNAME $HOME_DIR/install_as_user.sh
sudo -u $USERNAME $HOME_DIR/install_as_user.sh

