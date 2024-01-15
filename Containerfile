FROM registry.fedoraproject.org/fedora-toolbox:39

LABEL com.github.containers.toolbox="true" \
      usage="This image is meant to be used with the distrobox or toolbox commands" \
      summary="A container image with all my most frequently used commands, tools and configuration." \
      maintainer="github.com/m5lapp/dotfiles"

WORKDIR /tmp/

COPY setup/dev_container_setup.sh /opt/setup/dev_container_setup.sh

RUN source /opt/setup/dev_container_setup.sh && \
    update_dnf && \
    install_system_packages_dnf && \
    install_bitwarden && \
    install_chezmoi && \
    install_gcloud_dnf && \
    install_golang && \
    install_kubectl_dnf && \
    install_kubeseal && \
    install_istioctl_dnf && \
    install_neovim_dnf && \
    install_terraform_dnf && \
    install_starship
    #install_oci && \
