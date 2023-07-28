# azure-tf-epod
This repo provides an example to create the necessary azure infrastructure for deployment of epods. This is presently a wip and not complete. Provided as-is, only for demo/training purposes.

## Prerequisites
The script needs terraform and azure cli to run. These can be installed using a packet manager like apt (linux) or using homebrew (mac).

NOTE: These are mac instructions (homebrew -> terraform --> azure cli). Provided as-is. 
```shell
#install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
## install terraform
brew install terraform
## install az cli
brew install azure-cli
$> az login
## az group create ....
```

## To use the tfscript
Clone `main` branch. Alternatively use [released packages](https://github.com/amitgupta7/azure-tf-vms/releases)
```shell
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