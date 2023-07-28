# azure-tf-epod
This repo provides an example to create the necessary azure infrastructure for deployment of epods. This is presently a wip and not complete. Provided as-is, only for demo/training purposes.

## Prerequisites
The script needs terraform and azure cli to run. These can be installed using a packet manager like apt (linux) or using homebrew (mac). We will create a jumpbox machine on azure first, after which we will be able to provision the infrastructure and install epods from the jumpbox machine. We do this because the jumpbox machine on the azure cloud will have more stable internet, and would be less dependent on local network. 

NOTE: These are mac instructions (homebrew --> azure cli --> jumpbox-machine --> terraform). Provided as-is. 
```shell
#install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
## install terraform
brew install terraform
## install az cli
brew install azure-cli
$> az login
## Deploy the jump-box (with azure-cli or use included jumpbox helper script)
$> az vm create --resource-group your-resource-group --name epod-training-jumpbox-$RANDOM --image UbuntuLTS --admin-username "azuser" --admin-password "5tgb%TGB6yhn^YHN" --os-disk-size-gb 512 --size Standard_D2ds_v4
## login to the vm with ssh to run install terraform and provision the epod.
## ssh azuser@[jumpbox-hostname]
## clean-up with tfda command
```

Alternatively, to use the jumpbox helper script to provision the jumpbox:
```shell
$> git clone https://github.com/amitgupta7/azure-tf-epod.git
$> source tfAlias
$> cd azure-tf-epod/jumpbox
$> tf init
$> tfaa -var="az_subscription_id=your-azure-subscription-id" -var="az_resource_group=existing-azure-resourcegroup" -var="azpwd=strong_password_here"
## clean-up
$> tfda -var="az_subscription_id=your-azure-subscription-id" -var="az_resource_group=existing-azure-resourcegroup" -var="azpwd=strong_password_here"
```

## To use the tfscript
Clone `main` branch on the jumpbox machine. And install terraform and azure-cli before running the epod infrastructure provisioning with `terraform apply -auto-approve`.
```shell
## Install Terraform and azure-cli
$> sudo snap install terraform --classic
$> sudo apt-get update
$> sudo apt-get install -y libssl-dev libffi-dev python3-dev build-essential
$> curl -L https://aka.ms/InstallAzureCli | bash
$> az login
## Get this script to provision the infrastruture
$> git clone https://github.com/amitgupta7/azure-tf-epod.git
$> cd azure-tf-epod
$> source tfAlias
$> tf init 
## provision infra for pods provide EXISTING resource group name,
## provide azure subscription-id and az-name-prefix on prompt.
$> tfaa 
## to de-provision provide EXISTING resource group name, 
## azure subscription-id and az-name-prefix on prompt 
## EXACTLY SAME VALUES AS PROVIDED DURING PROVISIONING
$> tfda
```
Create a `terraform.tfvars` file to proivide azure subscription id and existing resource group. And/Or override default cidr values for infra provisioning. e.g.
```hcl
az_subscription_id = "your-azure-subscription-id"
az_resource_group  = "existing-resource-group-in-azure"
az_name_prefix     = "unique-prefix-to-use-in-resource-names"
bastion_address_prefix           = ["192.168.1.224/27"]
address_space                    = ["192.168.1.0/24"]
service_subnet_address_prefixes  = ["192.168.1.0/28"]
endpoint_subnet_address_prefixes = ["192.168.1.16/28"]
```

##  Connecting to AKS
```shell
$> sudo az aks install-cli
$> az aks get-credentials --resource-group my-resource-group --name my-name-prefix-aks
$> kubectl get nodes
NAME                             STATUS   ROLES   AGE   VERSION
aks-system-25983833-vmss000000   Ready    agent   22m   v1.24.10
```
