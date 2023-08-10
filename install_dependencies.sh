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

setup_helm() {
    mkdir -p "$BASE/tmp"
    cd "$BASE/tmp"
    # download helm
    curl -fsSL -o "helm-v3.6.0-linux-amd64.tar.gz" "https://get.helm.sh/helm-v3.6.0-linux-amd64.tar.gz"
    # extract helm/tiller
    tar -xzf "helm-v3.6.0-linux-amd64.tar.gz"
    # move helm into path
    cp --force linux-amd64/helm helm
    install_bin "helm"
    # remove temporary directory
    cd "$BASE"
    rm -rf "$BASE/tmp"
    # make directory for storing state files
    mkdir -p "$BASE/state"
    # creates YAML for service account
    cat <<'EOF' >"$BASE/state/sa-tiller.yaml"
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: tiller
    namespace: kube-system
EOF
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
setup_helm