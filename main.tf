
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
  address_prefixes     = var.bastion_address_prefix
}

resource "azurerm_subnet" "service-subnet" {
  name                = "${var.az_name_prefix}-epod-subnet"
  resource_group_name  = var.az_resource_group
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.service_subnet_address_prefixes

  enforce_private_link_service_network_policies = true
}

resource "azurerm_subnet" "endpoint-subnet" {
  name                = "${var.az_name_prefix}-endpoint-subnet"
  resource_group_name  = var.az_resource_group
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.endpoint_subnet_address_prefixes

  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_public_ip" "epod-public-ip" {
  name                = "${var.az_name_prefix}-epod-publicip"
  sku                 = "Standard"
  location            = var.region
  resource_group_name = var.az_resource_group
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "bastion-public-ip" {
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
    public_ip_address_id = azurerm_public_ip.bastion-public-ip.id
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

resource "azurerm_redis_cache" "redis" {
  name                = "${var.az_name_prefix}-redis"
  location            = var.region
  resource_group_name = var.az_resource_group
  capacity            = 2
  family              = "P"
  sku_name            = "Premium"
  enable_non_ssl_port = true
  minimum_tls_version = "1.2"

  redis_configuration {
  }

  zones = ["1", "2"]
}

resource "azurerm_storage_account" "storage_acc" {
  name                     = substr(replace("${var.az_name_prefix}-storage-acc", "-", ""), 0,24)
  resource_group_name      = var.az_resource_group
  location                 = var.region
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "example" {
  name                  = "${var.az_name_prefix}-storage-container"
  storage_account_name  = azurerm_storage_account.storage_acc.name
  container_access_type = "private"
}

resource "azurerm_storage_queue" "example" {
  name                 = "${var.az_name_prefix}-storage-container-queue"
  storage_account_name = azurerm_storage_account.storage_acc.name
}

## Create Private Link to connect epods to Redis and Storage
resource "azurerm_lb" "epod-loadbalancer" {
  name                = "${var.az_name_prefix}-epod-loadbalancer"
  sku                 = "Standard"
  location            = var.region
  resource_group_name      = var.az_resource_group

  frontend_ip_configuration {
    name                 = azurerm_public_ip.epod-public-ip.name
    public_ip_address_id = azurerm_public_ip.epod-public-ip.id
  }
}

resource "azurerm_private_link_service" "privatelink-service" {
  name                = "${var.az_name_prefix}-privatelink-service"
  location            = var.region
  resource_group_name      = var.az_resource_group
  nat_ip_configuration {
    name      = azurerm_public_ip.epod-public-ip.name
    primary   = true
    subnet_id = azurerm_subnet.service-subnet.id
  }

  load_balancer_frontend_ip_configuration_ids = [
    azurerm_lb.epod-loadbalancer.frontend_ip_configuration.0.id,
  ]
}

resource "azurerm_private_endpoint" "privat-endpoint" {
  name                = "${var.az_name_prefix}-priv-endpoint"
  location            = var.region
  resource_group_name      = var.az_resource_group
  subnet_id           = azurerm_subnet.endpoint-subnet.id

  private_service_connection {
    name                           = "${var.az_name_prefix}-privateserviceconnection"
    private_connection_resource_id = azurerm_private_link_service.privatelink-service.id
    is_manual_connection           = false
  }
}


output "redis_host_ip" {
  value = azurerm_redis_cache.redis.hostname
}

output "redis_primary_access_key" {
 value     = azurerm_redis_cache.redis.primary_access_key
 sensitive = true
}

output "repository_host" {
  value = azurerm_container_registry.acr1.login_server
}

output "repository_pwd" {
  value = azurerm_container_registry.acr1.admin_password
  sensitive = true
}

output "repository_usr" {
  value = azurerm_container_registry.acr1.admin_username
}

output "repository_id" {
  value = azurerm_container_registry.acr1.name
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}