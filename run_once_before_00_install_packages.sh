#!/bin/bash

source setup/dev_container_setup.sh

if ! is_running_in_container
then
    echo "Not currently running in a container, nothing to do..."
    exit 0
fi

# These are installed here rather than directly into the container as they need
# to be installed or modify the home directory which is mounted from the local
# file system.
install_filen_cli
install_fly
install_golang_tools
install_linkerd
install_neovim_nvchad_config

