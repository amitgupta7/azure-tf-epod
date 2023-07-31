# azure-tf-epod
This repo provides an example to create the necessary azure infrastructure for deployment of epods. This is presently a wip and not complete. Provided as-is, only for demo/training purposes.

## Prerequisites
The script needs terraform and azure cli to run. These can be installed using a packet manager like apt (linux) or using homebrew (mac). We will create a jumpbox machine on azure first to download the installer and perform the install. We will do this because the jumpbox machine on the azure cloud will have more stable internet, and would be less dependent on local network. 

NOTE: These are mac instructions (homebrew --> azure cli --> terraform --> jumpbox-machine, aks, acr). Provided as-is. 
```shell
#install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
## install terraform
brew install terraform
## install az cli
brew install azure-cli
$> az login
$> git clone https://github.com/amitgupta7/azure-tf-epod.git
$> source tfAlias
$> tf init
$> tfaa
## clean-up
$> tfda
```


Create a `terraform.tfvars` file to proivide azure subscription id and existing resource group. And/Or override default cidr values for infra provisioning. e.g.
```hcl
az_subscription_id = "your-azure-subscription-id"
az_resource_group  = "existing-resource-group-in-azure"
az_name_prefix     = "unique-prefix-to-use-in-resource-names"
```

##  Connecting to AKS
Kubectl should be connected to aks (done using file provisioner). SSH into the jumpbox, and run the following commands. Also, installer is available in `/mnt/epod-installer.tar`. Please see `todo.md` for existing limiatation. 

```shell
$> kubectl get nodes
NAME                             STATUS   ROLES   AGE   VERSION
aks-system-25983833-vmss000000   Ready    agent   22m   v1.24.10
$> ls -larth /mnt
total 17G
dr-xr-xr-x. 17 root root  224 Jun  9  2022 ..
drwx------.  2 root root  16K Jul 31 18:30 lost+found
-rw-r--r--.  1 root root  366 Jul 31 18:30 DATALOSS_WARNING_README.txt
drwxr-xr-x.  3 root root 4.0K Jul 31 18:48 .
-rw-r--r--.  1 root root 17G Jul 31 19:09 epod-installer.tar

```
