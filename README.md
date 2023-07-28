# azure-tf-epod
This repo provides an example to create the necessary azure infrastructure for deployment of epods. This is presently a wip and not complete. Provided as-is, only for demo/training purposes.

## Prerequisites
The script needs terraform and azure cli to run. These can be installed using a packet manager like apt (linux) or using homebrew (mac). We will create a bastion machine on azure first, after which we will be able to provision the infrastructure and install epods from the bastion machine. We do this because the bastion machine on the azure cloud will have more stable internet, and would be less dependent on local network. 

NOTE: These are mac instructions (homebrew --> azure cli --> bastion-machine --> terraform). Provided as-is. 
```shell
#install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
## install az cli
brew install azure-cli
$> az login
$> az vm create --resource-group your-resource-group --name epod-training-bastion-$RANDOM --image UbuntuLTS --admin-username "azureuser" --admin-password "5tgb%TGB6yhn^YHN" --os-disk-size-gb 512 --size Standard_D2ds_v4
## login to the vm with ssh to run install terraform and provision the epod.
## ssh azureuser@[vm-ip-address]
```

## To use the tfscript
Clone `main` branch on the bastion machine. Alternatively use [released packages](https://github.com/amitgupta7/azure-tf-vms/releases)
```shell
$> sudo apt install terraform azure-cli
$> az login
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
