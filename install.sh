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

if [[ -z "$PASSWORD" ]] then
    for ((i=0; i<3; i++)); 
    do
        IFS= read -r -s -p 'password: ' pass1
	echo
        IFS= read -r -s -p 'repeat password: ' pass2
	echo
	if [[ $pass1 = $pass2 ]] then
	    PASSWORD=$pass1
	    break
	fi
	echo "passwords don't match"
    done
fi

if [[ -z "$PASSWORD" ]] || [[ -z "$USERNAME" ]] then
    display_usage
fi

HOME_DIR="/home/$USERNAME"

install_packages() {
    apt-get update && apt-get dist-upgrade -y
    apt-get install -y dbus man
    apt-get build-dep -y python3
    apt-get install -y sudo zsh git zip unzip neovim build-essential wget curl pipewire-audio pavucontrol-qt \
	    xorg libpangocairo-1.0-0 libxcb1 libcairo2 libgdk-pixbuf-2.0-0 python3-venv python3-pip \
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

install_python() {
    local PYTHON_DIR="python3.12"
    local PYTHON_VERSION="Python-3.12.2"
    local URL_PYTHON="https://www.python.org/ftp/python/3.12.2/$PYTHON_VERSION.tar.xz"

    cd $HOME
    wget $URL_PYTHON
    tar -xavf $PYTHON_VERSION.tar.xz -C $HOME
    rm $PYTHON_VERSION.tar.xz
    cd $PYTHON_VERSION
    ./configure --enable-optimizations --prefix=$HOME/.local/$PYTHON_DIR
    make -j`nproc`
    make test
    make install
    cd && rm -rf $PYTHON_VERSION
    PATH=$HOME/.local/$PYTHON_DIR/bin:$PATH
}
 
install_qtile() {
    local URL_QTILE="https://github.com/qtile/qtile.git"

    cd $HOME/.local
    git clone $URL_QTILE
    cd qtile
    python3 -m pip install -U pip
    python3 -m venv .venv
    source .venv/bin/activate
    python3 -m pip install dbus-next psutil pyxdg pulsectl_asyncio
    python3 -m pip install "."
    cp .venv/bin/qtile $HOME/.local/bin
    deactivate
}

install_kitty() {
    local URL_KITTY="https://sw.kovidgoyal.net/kitty/installer.sh" 

    curl -L $URL_KITTY | sh /dev/stdin
    ln -sf $HOME/.local/kitty.app/bin/kitty $HOME/.local/kitty.app/bin/kitten $HOME/.local/bin
    cp $HOME/.local/kitty.app/share/applications/kitty.desktop $HOME/.local/share/applications/
    cp $HOME/.local/kitty.app/share/applications/kitty-open.desktop $HOME/.local/share/applications/
    sed -i "s|Icon=kitty|Icon=/home/$USER/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" ~/.local/share/applications/kitty*.desktop
    sed -i "s|Exec=kitty|Exec=/home/$USER/.local/kitty.app/bin/kitty|g" ~/.local/share/applications/kitty*.desktop
}

date > /tmp/log.txt
chgrp $USERNAME /tmp/log.txt
echo "Installing new system..." | tee -a /tmp/log.txt
install_packages 2>&1 | tee -a /tmp/log.txt
create_user 2>&1 | tee -a /tmp/log.txt
install_dotfiles 2>&1 | tee -a /tmp/log.txt

DECL_PYTHON=`declare -f install_python`
DECL_QTILE=`declare -f install_qtile`
DECL_KITTY=`declare -f install_kitty`

sudo -u $USERNAME /usr/bin/env bash -c "$DECL_PYTHON; install_python 2>&1 | tee -a /tmp/log.txt"
sudo -u $USERNAME /usr/bin/env bash -c "$DECL_QTILE; install_qtile 2>&1 | tee -a /tmp/log.txt"
sudo -u $USERNAME /usr/bin/env bash -c "$DECL_KITTY; install_kitty 2>&1 | tee -a /tmp/log.txt"

#cp install_as_user.sh $HOME_DIR/
#chown $USERNAME:$USERNAME $HOME_DIR/install_as_user.sh
#sudo -u $USERNAME $HOME_DIR/install_as_user.sh
#rm $HOME_DIR/install_as_user.sh

