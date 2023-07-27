variable "az_subscription_id" {
  description = "azure subscription id"
  type        = string
}

variable "region" {
  default = "westus2"
}

variable "azuser" {
  default = "azuser"
}

variable "azpwd" {
  description = "common vm password, 16 characters containg --> [chars-alpha-num-special-char]"
}

variable "vm_size" {
  default = "Standard_D32s_v3"
}

variable "os_disk_size_in_gb" {
  default = 1024
}


variable "os_publisher" {
  default = "Canonical"
}

variable "os_offer" {
  default = "0001-com-ubuntu-server-focal"
}

variable "os_sku" {
  default = "20_04-lts-gen2"
}

variable "os_version" {
  default = "latest"
}

variable "az_resource_group" {
  description = "resource group name to create these resources"
}

variable "az_name_prefix" {
  description = "prefix to add to resource names"
  default     = "azure-tf-vms"
}

variable "X_API_Secret" {
  type        = string
  description = "SAI API secret"
}
  
variable "X_API_Key" {
  type        = string
  description = "SAI API key"
}

variable "X_TIDENT" {
  type        = string
  description = "SAI Tenant ID"
}

variable "kubernetes_version" {
  default     = "1.24.10"
  description = "Kubernetes version"
}

variable "node_vm_size" {
  default = "Standard_D4_v2"
}

variable "min_node_count" {
  default     = "1"
  description = "AKS min nodes"
}

variable "max_node_count" {
  default     = "4"
  description = "AKS max nodes"
}

variable "address_space" {}

variable "service_subnet_address_prefixes" {}

variable "endpoint_subnet_address_prefixes" {}