#!/bin/bash

CONTAINER_NAME="dev-box"
CONTAINER_REGISTRY="docker.io"
CONTAINER_REGISTRY_USER="rareb1t"
CONTAINER_TAG="39.1"
CONTAINER_IMAGE="${CONTAINER_REGISTRY}/${CONTAINER_REGISTRY_USER}/dev-container"
GITHUB_USERNAME="m5lapp"

build_dev_container_image() {
    local CONTAINER_CMD=${1:-podman}

    ${CONTAINER_CMD} build -t ${CONTAINER_IMAGE}:${CONTAINER_TAG} .
}

push_dev_container_image() {
    local CONTAINER_CMD=${1:-podman}

    if [ -z "${CONTAINER_REGISTRY_ACCESS_TOKEN}" ]
    then
        echo "Please export the CONTAINER_REGISTRY_ACCESS_TOKEN variable to push the container image."
        return 1
    fi

	${CONTAINER_CMD} login ${CONTAINER_REGISTRY} \
		--username ${CONTAINER_REGISTRY_USER} \
		--password ${CONTAINER_REGISTRY_ACCESS_TOKEN}

    ${CONTAINER_CMD} push ${CONTAINER_IMAGE}:${CONTAINER_TAG}
}

create_dev_container_distrobox() {
    local CONTAINER_NAME=${1:-CONTAINER_NAME}
    local GITHUB_USERNAME=${2:-GITHUB_USERNAME}
    local CONTAINER_IMAGE=${3:-CONTAINER_IMAGE}
    local CONTAINER_TAG=${4:-CONTAINER_TAG}

    # Create the dev container with Distrobox.
    distrobox create --yes \
        --image ${CONTAINER_IMAGE}:${CONTAINER_TAG} \
        --name ${CONTAINER_NAME}

    # Run the chezmoi initialization command.
    distrobox enter ${CONTAINER_NAME} \
        -- \
        sh -c '
            export BW_SESSION=$(bw login --raw || bw unlock --raw) && \
            chezmoi init --apply --interactive --verbose ${GITHUB_USERNAME}'
}

create_dev_container_toolbox() {
    local CONTAINER_NAME=${1:-CONTAINER_NAME}
    local GITHUB_USERNAME=${2:-GITHUB_USERNAME}
    local CONTAINER_IMAGE=${3:-CONTAINER_IMAGE}
    local CONTAINER_TAG=${4:-CONTAINER_TAG}

    # Create the dev container with Toolbox.
    yes | toolbox create \
        --image ${CONTAINER_IMAGE}:${CONTAINER_TAG} \
        ${CONTAINER_NAME}

    # Run the chezmoi initialization command.
    toolbox run \
        --container ${CONTAINER_NAME} \
        -- \
        sh -c '
            export BW_SESSION=$(bw login --raw || bw unlock --raw) && \
            chezmoi init --apply --interactive --verbose ${GITHUB_USERNAME}'
}

is_running_in_container() {
    if [ -e /run/.containerenv ] || [ -e /.dockerenv ]
    then
        return 0
    else
        return 1
    fi
}

command_exists() {
    local COMMAND="${1:-''}"

    # Check if the given command is already installed and executable.
    if command -v ${COMMAND} &>/dev/null
    then
        return 0
    else
        return 1
    fi
}

add_gcp_repo_dnf() {
    # Check if the google-cloud-cli repo is already installed and active.
    dnf repolist google-cloud-cli | grep --silent enabled && return

    sudo tee -a "/etc/yum.repos.d/google-cloud-sdk.repo" << EOM
[google-cloud-cli]  
name=Google Cloud CLI  
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el8-x86_64  
enabled=1  
gpgcheck=1  
repo_gpgcheck=0  
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg  
EOM
}

update_dnf() {
    echo "Updating packages in DNF..."
    sudo dnf update -y
}

install_system_packages_dnf() {
    echo "Installing general dependencies via DNF..."
    sudo dnf install -y \
        bash-completion \
        flatpak-spawn
}

install_bitwarden() {
    # Check if the Bitwarden CLI is already installed and executable.
    command_exists bw && return

    # Install the Bitwarden CLI.
    echo "Installing the Bitwarden CLI..."
    local BITWARDEN_CLI_URL="https://vault.bitwarden.com/download/?app=cli&platform=linux"

    curl -L -o /tmp/bitwarden-cli.zip "${BITWARDEN_CLI_URL}"
    sudo unzip /tmp/bitwarden-cli.zip -d /usr/local/bin/
    rm /tmp/bitwarden-cli.zip

    # Install bash completion.
    # Bitwarden currently only offers completion for zsh.
}

install_chezmoi() {
    # Check if the chezmoi binary is already installed and executable.
    command_exists chezmoi && return

    sudo sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin/

    # Install bash completion.
    sudo chezmoi completion bash --output /etc/bash_completion.d/chezmoi
}

install_cilium() {
    # Check if the cilium binary is already installed and executable.
    command_exists cilium && return

    local CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
    local CLI_ARCH=amd64
    if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
    curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
    sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
    sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
    rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

    # Install bash completion.
    cilium completion bash | sudo tee /etc/bash_completion.d/cilium > /dev/null
}

install_fly() {
    # Check if the fly binary is already installed and executable.
    command_exists fly && return

    local FLYCTL_INSTALL="/home/${USER}/.local/fly"
    echo "Installing the fly.io CLI to ${FLYCTL_INSTALL}/..."
    curl -L https://fly.io/install.sh | sh

    # Install bash completion.
    ${FLYCTL_INSTALL}/bin/fly completion bash | \
        sudo tee /etc/bash_completion.d/flyctl > /dev/null
}

install_gcloud_dnf() {
    # Check if the gcloud binary is already installed and executable.
    command_exists gcloud && return

    echo "Installing the GCP gcloud CLI via DNF..."
    add_gcp_repo_dnf
    sudo dnf install -y google-cloud-cli

    # Install additional components you might want.
    sudo dnf install -y \
        google-cloud-cli-app-engine-go \
        google-cloud-cli-app-engine-grpc \
        google-cloud-cli-app-engine-python \
        google-cloud-cli-app-engine-python-extras \
        google-cloud-cli-docker-credential-gcr \
        google-cloud-cli-firestore-emulator \
        google-cloud-cli-package-go-module

    # Initialise the gcloud tool and log in to your account.
    # gcloud init
}

install_golang() {
    # Check if the golang binary is already installed and executable.
    command_exists go && return

    local LATEST_VERSION=$(curl -Ls 'https://go.dev/VERSION?m=text' | head -n 1)
    local DOWNLOAD_URL="https://go.dev/dl/${LATEST_VERSION}.linux-amd64.tar.gz"
    local GOPATH="${HOME}/.local/share/go"

    echo "Installing Golang version ${LATEST_VERSION} to /usr/local/go/..."
    curl -L -o /tmp/go.tar.gz ${DOWNLOAD_URL}
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz
}

install_golang_tools() {
    if ! command_exists go
    then
        echo "Cannot install Go tools without the go binary being installed first."
        return 1
    fi

    echo "Install Golang tools/dependants..."
    go install golang.org/x/tools/gopls@latest
    go install github.com/golang/protobuf/protoc-gen-go@latest
    go install github.com/golang-migrate/migrate@latest
}

install_istioctl() {
    # Check if the istioctl binary is already installed and executable.
    command_exists istioctl && return

    echo "Installing istioctl..."
    curl -L https://istio.io/downloadIstio | sh -
    sudo install -o root -g root -m 0755 istio-*/bin/istioctl /usr/local/bin/istioctl
    rm -rf istio-*/

    # Install bash completion.
    istioctl completion bash | sudo tee /etc/bash_completion.d/istioctl > /dev/null
}

install_istioctl_dnf() {
    # Check if the istioctl binary is already installed and executable.
    command_exists istioctl && return

    echo "Installing istioctl via DNF..."
    add_gcp_repo_dnf
    sudo dnf install -y google-cloud-cli-istioctl

    # Install bash completion.
    istioctl completion bash | sudo tee /etc/bash_completion.d/istioctl > /dev/null
}

install_kubectl() {
    # Check if the kubectl binary is already installed and executable.
    command_exists kubectl && return

    echo "Installing Kubectl and Helm..."
    local KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    echo "Downloading and installing Kubectl version ${KUBECTL_VERSION}."
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"

    # Verify the integrity of the downloaded binary.
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256"
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check || return ${?}

    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl kubectl.sha256

    local HELM_VERSION=$(curl --silent https://get.helm.sh/helm-latest-version)
    echo "Downloading and installing Helm version ${HELM_VERSION}."
    curl -LO "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz"

    tar -zxvf helm-${HELM_VERSION}-linux-amd64.tar.gz
    sudo install -o root -g root -m 0755 linux-amd64/helm /usr/local/bin/helm
    rm -rf helm-${HELM_VERSION}-linux-amd64.tar.gz linux-amd64/

    # Use tee with sudo as redirects to a file as sudo do not work.
    kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
    helm completion bash | sudo tee /etc/bash_completion.d/helm > /dev/null
}

install_kubectl_dnf() {
    # Check if the kubectl binary is already installed and executable.
    command_exists kubectl && return

    echo "Installing Kubectl and Helm via DNF..."
    add_gcp_repo_dnf
    sudo dnf install -y helm kubectl

    # Use tee with sudo as redirects to a file as sudo do not work.
    kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
    helm completion bash | sudo tee /etc/bash_completion.d/helm > /dev/null
}

install_kubeseal() {
    # Check if the kubeseal binary is already installed and executable.
    command_exists kubeseal && return

    local KUBESEAL_VERSION="0.24.5"
    local DOWNLOAD_URL="https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION:?}/kubeseal-${KUBESEAL_VERSION:?}-linux-amd64.tar.gz"

    echo "Installing the kubeseal CLI version ${KUBESEAL_VERSION}..."
    curl -Lo kubeseal-${KUBESEAL_VERSION:?}-linux-amd64.tar.gz ${DOWNLOAD_URL}
    tar -xvzf kubeseal-${KUBESEAL_VERSION:?}-linux-amd64.tar.gz kubeseal

    sudo install -m 755 kubeseal /usr/local/bin/kubeseal
    rm kubeseal*

    # There is no completion available for kubeseal.
}

install_linkerd() {
    # Check if the linkerd binary is already installed and executable.
    command_exists linkerd && return

    echo "Installing the Linkerd CLI from linkerd.io..."
    curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | \
        INSTALLROOT=/home/${USER}/.local/linkerd2 sh

    # Install bash completion.
    linkerd completion bash | sudo tee /etc/bash_completion.d/linkerd > /dev/null
}

install_neovim_dnf() {
    # Check if the nvim binary is already installed and executable.
    command_exists nvim && return

    echo "Installing NeoVim via DNF..."
    sudo dnf install -y gcc gcc-c++ neovim
}

install_neovim_nvchad_config() {
    # Backup up the existing nvim configuration directory if it exists.
    if [ -d ~/.config/nvim/ ]
    then 
        local BACKUP_DIR=~/.config/nvim.backup.$(date "+%Y%m%d%H%M%S")/
        echo "Backing up NeoVim config from ~/.config/nvim/ to ${BACKUP_DIR}..."
        mv ~/.config/nvim/ ${BACKUP_DIR}
    fi

    # Install NeoVim's NvChad configuration.
    echo "Installing the NvChad NeoVim distribution..."
    rm -rf ~/.local/share/nvim/
    git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1
}

install_oci() {
    # Check if the oci binary is already installed and executable.
    command_exists oci && return

    echo "Installing the OCI CLI to /usr/bin/"
    local OCI_URL="https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh"
    sudo bash -c "$(curl -L ${OCI_URL})" \
        -s \
        --accept-all-defaults \
        --no-tty \
        --install-dir /usr/lib/oracle-cli/ \
        --exec-dir /usr/bin/ \
        --script-dir /usr/bin/oci-cli-scripts/
}

install_starship() {
    # Check if the starship binary is already installed and executable.
    command_exists starship && return

    local BIN_DIR="/usr/local/bin/"
    echo "Installing the starship prompt to ${BIN_DIR}"
    curl -sS https://starship.rs/install.sh | \
        sh -s -- --yes --bin-dir "${BIN_DIR}"

    # Install bash completion.
    starship completions bash | sudo tee /etc/bash_completion.d/starship > /dev/null
}

install_terraform() {
    # Check if the terraform binary is already installed and executable.
    command_exists terraform && return

    # There is a Github gist available to look up the latest version number for
    # Terraform, but it depends on `jq` which is not guarenteed to be installed.
    # See: https://gist.github.com/danisla/0a394c75bddce204688b21e28fd2fea5
    local TF_VERSION="1.7.0"
    echo "Installing Terraform version ${TF_VERSION}..."
    local TF_FILE_NAME="terraform_${TF_VERSION}_linux_amd64.zip"
    curl -LO https://releases.hashicorp.com/terraform/${TF_VERSION}/${TF_FILE_NAME}

    unzip ${TF_FILE_NAME}
    sudo install -o root -g root -m 0755 terraform /usr/local/bin/terraform
    rm terraform ${TF_FILE_NAME}

    # Set up bash completion. Add this to the .bashrc file to make permanent.
    complete -C $(which terraform) terraform
}

install_terraform_dnf() {
    # Check if the terraform binary is already installed and executable.
    command_exists terraform && return

    echo "Installing Terraform via DNF..."
    sudo dnf install dnf-plugins-core
    sudo dnf config-manager \
        --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
    sudo dnf install -y terraform
}

