#!/bin/bash
set -o nounset
set -o errexit
set -o pipefail
set -x

export VERSION=development

echo $VERSION

BASE="/opt/provisioner"
export PATH="$BASE/bin:$BASE/venv/bin:/usr/local/bin:$PATH"

install_basics() {
    sudo dnf update --disablerepo=* --enablerepo='*microsoft*' -y
    yum update -y --allowerasing
    yum install -y git jq python3 tar unzip
    sudo yum check-update
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install -y docker-ce docker-ce-cli containerd.io -y
    sudo systemctl start docker
    sudo systemctl enable docker
}

install_bin() {
    export bin_name="$1"
    chmod +x "$bin_name"
    mkdir -p "$BASE/bin"
    cp --force "$bin_name" "/bin/$bin_name"
    cp --force "$bin_name" "/usr/local/bin/$bin_name"
    cp --force "$bin_name" "$BASE/bin/$bin_name"
}

setup_kubernetes() {
    mkdir -p "$BASE/tmp"
    cd "$BASE/tmp"
    # download kubectl & install
    curl -fsSL -o "kubectl" "https://dl.k8s.io/release/v1.19.9/bin/linux/amd64/kubectl"
    install_bin "kubectl"
    # download kubectx & install
    curl -fsSL -o "kubectx" "https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx"
    install_bin "kubectx"
    # download kubens & install
    curl -fsSL -o "kubens" "https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens"
    install_bin "kubens"
    # download kubectl_aliases & install
    curl -fsSL -o "kubectl_aliases" "https://raw.githubusercontent.com/ahmetb/kubectl-aliases/master/.kubectl_aliases"
    install_bin "kubectl_aliases"
    # download kube-ps1 & install
    curl -fsSL -o "kubectl_prompt" "https://raw.githubusercontent.com/jonmosco/kube-ps1/master/kube-ps1.sh"
    install_bin "kubectl_prompt"
    # remove temporary directory
    cd "$BASE"
    rm -rf "$BASE/tmp"
}

# include locals if the file exists
if [ -f "$BASE/locals.sh" ]; then
    . "$BASE/locals.sh"
fi


install_basics
setup_kubernetes
