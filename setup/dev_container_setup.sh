#!/bin/bash

CONTAINER_NAME="dev-box"
CONTAINER_REGISTRY="docker.io"
CONTAINER_REGISTRY_USER="rareb1t"
CONTAINER_TAG="40.0"
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
        echo "Please export the CONTAINER_REGISTRY_ACCESS_TOKEN variable to push the container image:"
        read -p "Token: " CONTAINER_REGISTRY_ACCESS_TOKEN
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

    # The FORCE_INSTALL environment variable can be used to force commands to be
    # reinstalled/updated if set to true.
    if test "${FORCE_INSTALL:-}" == "true"
    then
        return 2
    fi

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
        bind-utils \
        flatpak-spawn
}

install_act() {
    # Check if Act is already installed and executable.
    command_exists act && return

    # Install Act.
    echo "Installing Act from Github..."
    local ACT_CLI_URL="https://raw.githubusercontent.com/nektos/act/master/install.sh"
    curl --proto '=https' --tlsv1.2 -sSf ${ACT_CLI_URL} | sudo bash -s -- -b ~/.local/bin
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

install_flux() {
    # Check if the flux binary is already installed and executable.
    command_exists flux && return

    curl -s https://fluxcd.io/install.sh | BIN_DIR="/usr/local/bin" sudo bash

    # Install bash completion.
    flux completion bash | sudo tee /etc/bash_completion.d/flux > /dev/null
}

install_fly() {
    local FLYCTL_INSTALL="/home/${USER}/.local/fly"

    # Check if the fly binary is already installed and executable.
    if command_exists fly
    then
        echo "Upgrading the fly.io CLI in ${FLYCTL_INSTALL}..."
        fly version upgrade
    else
        echo "Installing the fly.io CLI to ${FLYCTL_INSTALL}..."
        curl -L https://fly.io/install.sh | sh
    fi

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
    if ! command_exists go; then
        echo "Cannot install Go tools without the go binary being installed first."
        return 1
    fi

    echo "Install Golang tools/dependants..."
    local GOPATH="${HOME}/.local/share/go"
    go install golang.org/x/tools/gopls@latest
    go install github.com/golang/protobuf/protoc-gen-go@latest

    # Install the golang-migrate CLI.
    curl -L https://github.com/golang-migrate/migrate/releases/download/v4.17.0/migrate.linux-amd64.tar.gz | tar -xvz migrate
    mv migrate ${GOPATH}/bin/migrate
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

install_k9s() {
    # Check if the k9s binary is already installed and executable.
    command_exists k9s && return

    local K9S_TARBALL="k9s_Linux_amd64.tar.gz"
    local K9S_VERSION="0.32.4"

    echo "Downloading and installing K9s version ${K9S_VERSION}."
    curl -LO "https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/${K9S_TARBALL}"

    tar -zxvf ${K9S_TARBALL} k9s
    sudo install -o root -g root -m 0755 k9s /usr/local/bin/k9s
    rm ${K9S_TARBALL} k9s

    # Install bash completion.
    k9s completion bash | sudo tee /etc/bash_completion.d/k9s > /dev/null
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

    local KUBESEAL_VERSION="0.28.0"
    local DOWNLOAD_URL="https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION:?}/kubeseal-${KUBESEAL_VERSION:?}-linux-amd64.tar.gz"

    echo "Installing the kubeseal CLI version ${KUBESEAL_VERSION}..."
    curl -Lo kubeseal-${KUBESEAL_VERSION:?}-linux-amd64.tar.gz ${DOWNLOAD_URL}
    tar -xvzf kubeseal-${KUBESEAL_VERSION:?}-linux-amd64.tar.gz kubeseal

    sudo install -m 755 kubeseal /usr/local/bin/kubeseal
    rm kubeseal*

    # There is no completion available for kubeseal.
}

install_latex_dnf() {
    # Check if the latex command is already installed and executable.
    command_exists latex && return

    echo "Installing LaTeX..."
    sudo dnf install texlive-scheme-basic "tex(fullpage.sty)"
}

install_linkerd() {
    # Check if the linkerd binary is already installed and executable.
    if ! command_exists linkerd
    then
        echo "Installing the Linkerd CLI from linkerd.io..."
        curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | \
            INSTALLROOT=/home/${USER}/.local/linkerd2 sh
    fi

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
    # Check if an existing nvim configuration directory exists.
    if [ -d ~/.config/nvim/ ]; then 
        read -p "~/.config/nvim/ exists. Back up and replace (y/n)? " NVIM_OVERWRITE
        if [ "${NVIM_OVERWRITE}" != "y" ]; then
            # The user opted to not back up and replace the nvim config.
            return 0
        fi

        local BACKUP_DIR=~/.config/nvim.backup.$(date "+%Y%m%d%H%M%S")/
        echo "Backing up NeoVim config from ~/.config/nvim/ to ${BACKUP_DIR}..."
        mv ~/.config/nvim/ ${BACKUP_DIR}
    fi

    # Install NeoVim's NvChad configuration.
    echo "Installing the NvChad NeoVim distribution..."
    rm -rf ~/.local/share/nvim/
    git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1
}

install_python_dnf() {
    # Check if the pip3 command is already installed and executable.
    command_exists pip3 && return

    sudo dnf install -y \
        python3 \
        python3-pip
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

install_oci_dnf() {
    # Check if the oci binary is already installed and executable.
    command_exists oci && return

    echo "Installing the OCI CLI..."
    sudo dnf install -y oci-cli
}

install_psql_client_dnf() {
    # Check if the psql binary is already installed and executable.
    command_exists psql && return

    echo "Installing the PostgreSQL client via DNF..."
    sudo dnf install -y postgresql
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

install_taskfile() {
    # Check if the go-task binary is already installed and executable.
    command_exists task && return

    local DOWNLOAD_URL="https://github.com/go-task/task/releases/download/v3.41.0/task_linux_amd64.tar.gz"
    local INSTALL_DIR="${HOME}/.local/bin/"

    echo "Installing Taskfile (task) to ${INSTALL_DIR}..."
    curl -L ${DOWNLOAD_URL} | tar -C ${INSTALL_DIR} -xvz task

    task --completion bash | sudo tee /etc/bash_completion.d/task > /dev/null
}

install_taskfile_dnf() {
    # Check if the go-task binary is already installed and executable.
    command_exists go-task && return

    echo "Installing Taskfile (go-task) via DNF..."
    sudo dnf install -y go-task

    go-task --completion bash | sudo tee /etc/bash_completion.d/go-task > /dev/null
}

install_terraform() {
    # Check if the terraform binary is already installed and executable.
    command_exists terraform && return

    # There is a Github gist available to look up the latest version number for
    # Terraform, but it depends on `jq` which is not guarenteed to be installed.
    # See: https://gist.github.com/danisla/0a394c75bddce204688b21e28fd2fea5
    local TF_VERSION="1.10.5"
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

install_veracrypt_rpm() {
    # Check if the veracrypt binary is already installed and executable.
    command_exists veracrypt && return

    # https://www.veracrypt.fr/en/Downloads.html
    local DOWNLOAD_URL="https://launchpad.net/veracrypt/trunk/1.26.7/+download/veracrypt-console-1.26.7-CentOS-8-x86_64.rpm"
    curl -L -o /tmp/veracrypt-cli.rpm "${DOWNLOAD_URL}"

    sudo dnf -y install fuse-devel
    sudo dnf -y install /tmp/veracrypt-cli.rpm
    rm /tmp/veracrypt-cli.rpm
}
