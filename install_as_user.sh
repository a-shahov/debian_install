#!/usr/bin/env bash

URL_QTILE="https://github.com/qtile/qtile.git"

PYTHON_DIR="python3.12"
PYTHON_VERSION="Python-3.12.2"
URL_PYTHON="https://www.python.org/ftp/python/3.12.2/$PYTHON_VERSION.tar.xz"


install_python() {
    cd $HOME
    wget $URL_PYTHON
    tar -xavf $PYTHON_VERSION.tar.xz -C $HOME
    rm $PYTHON_VERSION.tar.xz
    cd $PYTHON_VERSION
    ./configure --enable-optimizations --prefix=$HOME/.local/$PYTHON_DIR
    make -j8
    make test
    make install
    cd && rm -rf $PYTHON_VERSION
    PATH=$HOME/.local/$PYTHON_DIR/bin:$PATH
}

install_qtile() {
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
}

install_python
install_qtile
install_kitty
