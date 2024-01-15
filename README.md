# Configuration Dotfiles

This repo contains my main dotfiles for deployment using [chezmoi](https://www.chezmoi.io/). It also contains a script for setting up my host OS and further scripts and a Containerfile for building a container image with all the dev tools that I use.

## Getting Started
The first thing to do is to build and push the dev container image if it has not already been done. From the root of this project, simply run the following commands. If you have made any changes, be sure to first update the CONTAINER_TAG variable at the top of `dev_container_setup.sh`.

```bash
export CONTAINER_REGISTRY_ACCESS_TOKEN="YOUR_CONTAINER_REGISTRY_ACCESS_TOKEN_SECRET"
source setup/dev_container_setup.sh
build_dev_container_image [docker|podman]
push_dev_container_image [docker|podman]
```

This project has the following dependencies, both of which should be installed in the dev container image just mentioned.

 * Bitwarden
 * chezmoi

To get started on a brand new immutable Fedora-based Linux distribution, run the following commands. This will set up the OS, create a new Toolbox container using the dev container image and deploy the configuration dotfiles via `chezmoi`.

```bash
curl -L -o /tmp/dev_container_setup.sh \
    https://github.com/m5lapp/dotfiles/raw/main/setup/dev_container_setup.sh
curl -L -o /tmp/fedora_immutable.sh \
    https://github.com/m5lapp/dotfiles/raw/main/setup/fedora_immutable.sh
curl -L -o /tmp/setup_os.sh \
    https://github.com/m5lapp/dotfiles/raw/main/setup/setup_os.sh

bash /tmp/fedora_immutable_bootstrap.sh GITHUB_USERNAME

rm /tmp/dev_container_image.sh /tmp/fedora_immutable.sh /tmp/setup_os.sh
```

Once you have done that, you will now have this repository cloned to `~/.local/share/chezmoi/`.

You can now enter the dev container as follows and use `chezmoi` as normal to mange your dotfiles:

```bash
# Run one of these as appropriate depending on whether you are using distrobox
# or toolbox.
distrobox enter dev-box
toolbox enter dev-box

chezmoi cd
chezmoi edit ~/.bashrc
chezmoi diff ~/.bashrc
chezmoi apply ~/.bashrc --verbose
```
