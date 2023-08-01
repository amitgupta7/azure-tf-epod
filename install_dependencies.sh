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
}

install_bin() {
    export bin_name="$1"
    chmod +x "$bin_name"
    mkdir -p "$BASE/bin"
    cp --force "$bin_name" "/bin/$bin_name"
    cp --force "$bin_name" "/usr/local/bin/$bin_name"
    cp --force "$bin_name" "$BASE/bin/$bin_name"
}

install_az_cli() {
    mkdir -p "$BASE/tmp"
    cd "$BASE/tmp"
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

    sudo sh -c 'echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'

    sudo yum install azure-cli -y
}




# include locals if the file exists
if [ -f "$BASE/locals.sh" ]; then
    . "$BASE/locals.sh"
fi


install_basics
install_az_cli
sudo az aks install-cli
sudo curl https://kots.io/install | bash
