#!/bin/bash

update_os () {
    rpm-ostree upgrade
}

add_flathub () {
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

add_flatpaks () {
    add_flathub

    flatpak install flathub \
        com.getpostman.Postman \
        com.github.tchx84.Flatseal \
        com.vscodium.codium \
        md.obsidian.Obsidian \
        org.chromium.Chromium \
        org.freac.freac \
        org.freedesktop.Sdk.Extension.golang \
        org.kde.amarok \
        org.kde.falkon \
        org.libreoffice.LibreOffice \
        org.mozilla.firefox \
        org.raspberrypi.rpi-imager \
        org.subsurface_divelog.Subsurface

    # Look in /etc/os-release to check if we're running Fedora Sericea
    # specifically.
    source /etc/os-release
    if [ "${VARIANT_ID}" == "sericea" ]
    then
        add_flatpaks_sericea
    fi
}

add_flatpaks_sericea() {
    add_flathub

    flatpak install flathub \
        org.kde.dolphin \
        org.kde.kalk \
        org.kde.kate \
        org.kde.kwrite \
        org.kde.okular
}

add_system_packages () {
    rpm-ostree install \
        distrobox \
        jetbrains-mono-fonts-all \
        make \
        neovim \
        tmux
}

remove_system_packages () {
    rpm-ostree override remove \
        firefox \
        firefox-langpacks
}

create_dev_container () {
    source dev_container_setup.sh
    create_dev_container_toolbox ${1} ${2} ${3} ${4}
}

