install_fonts () {
    # The following is based on the documentation at:
    #   https://docs.rockylinux.org/de/books/nvchad/nerd_fonts/
    local INSTALL_DIR="/tmp/nerd-fonts/"
    mkdir ${INSTALL_DIR}
    cd ${INSTALL_DIR}

    # The names of the available fonts to be installed can be found from the
    # directory names here:
    #   https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/
    local FONTS=( "JetBrainsMono" )

    git clone \
        --filter=blob:none \
        --sparse https://github.com/ryanoasis/nerd-fonts.git \
        ${INSTALL_DIR}

    for FONT in ${FONTS[@]}; do
        echo "Installing ${FONT} font..."
        git sparse-checkout add patched-fonts/${FONT}
        ./install.sh ${FONT}
    done

    cd -
    rm -rf ${INSTALL_DIR}
}

