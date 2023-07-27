
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.66.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id            = var.az_subscription_id
  skip_provider_registration = true
}
#resource_group_name = var.az_resource_group

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.az_name_prefix}-vnet"
  address_space       = var.address_space
  location            = var.region
  resource_group_name = var.az_resource_group
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.az_name_prefix}-nsg"
  location            = var.region
  resource_group_name = var.az_resource_group
}

resource "azurerm_subnet" "bastion-subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.az_resource_group
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.1.224/27"]
}

resource "azurerm_public_ip" "public-ip" {
  name                = "${var.az_name_prefix}-bastion-publicip"
  location            = var.region
  resource_group_name = var.az_resource_group
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion-host" {
  name                = "${var.az_name_prefix}-bastion-host"
  location            = var.region
  resource_group_name = var.az_resource_group

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion-subnet.id
    public_ip_address_id = azurerm_public_ip.public-ip.id
  }
}

resource "azurerm_container_registry" "acr1" {
  name                = replace("${var.az_name_prefix}-acr", "-", "")
  resource_group_name = var.az_resource_group
  location            = var.region
  sku                 = "Premium"
  admin_enabled       = false
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.az_name_prefix}-aks"
  kubernetes_version  = var.kubernetes_version
  location            = var.region
  resource_group_name = var.az_resource_group
  dns_prefix          = var.az_name_prefix

  default_node_pool {
    name                = "system"
    node_count          = var.min_node_count
    vm_size             = var.node_vm_size
    type                = "VirtualMachineScaleSets"
    enable_auto_scaling = true
    min_count           = var.min_node_count
    max_count           = var.max_node_count
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "dev"
  }
}
