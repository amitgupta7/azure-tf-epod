variable "az_subscription_id" {
  description = "azure subscription id"
  type        = string
}

variable "location" {
  default = "westus2"
}

variable "azuser" {
  default = "azuser"
}

variable "azpwd" {
  description = "common vm password, 16 characters containg --> [chars-alpha-num-special-char]"
}

variable "vm_size" {
  default = "Standard_D2ds_v4"
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