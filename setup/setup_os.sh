#!/bin/bash

source dev_container_setup.sh
DEV_CONTAINER_NAME="${CONTAINER_NAME}"
DEV_GITHUB_USERNAME="${GITHUB_USERNAME}"
DEV_CONTAINER_IMAGE="${CONTAINER_IMAGE}"
DEV_CONTAINER_TAG="${CONTAINER_TAG}"

usage () {
    echo "Usage: ./setup_os.sh [options]"
    echo "Options:"
    echo "    -h                   Show usage information"
    echo "    -n CONTAINER_NAME    Defaults to ${DEV_CONTAINER_NAME}"
    echo "    -i CONTAINER_IMAGE   Defaults to ${DEV_CONTAINER_IMAGE}"
    echo "    -t CONTAINER_TAG     Defaults to ${DEV_CONTAINER_TAG}"
    echo "    -u GITHUB_USERNAME   Defaults to ${DEV_GITHUB_USERNAME}"
}

# Override any default options with any supplied parameters.
while getopts hn:i:t:u: OPT
do
    case ${OPT} in
        n) DEV_CONTAINER_NAME=${OPTARG};;
        i) DEV_CONTAINER_IMAGE=${OPTARG};;
        t) DEV_CONTAINER_TAG=${OPTARG};;
        u) DEV_GITHUB_USERNAME=${OPTARG};;
        h) usage; exit 0;;
    esac
done

# Determine the host OS.
if [ -e /run/ostree-booted ]
then
    BOOTSTRAP_FUNCTIONS_FILE=fedora_immutable.sh
else
    echo "Could not determine operating system type."
    exit 2
fi

# Load the set up functions for the determined OS and run them.
source ${BOOTSTRAP_FUNCTIONS_FILE}

update_os
add_system_packages
remove_system_packages
add_flatpaks
create_dev_container \
    ${DEV_CONTAINER_NAME} \
    ${DEV_GITHUB_USERNAME} \
    ${DEV_CONTAINER_IMAGE} \
    ${DEV_CONTAINER_TAG}

