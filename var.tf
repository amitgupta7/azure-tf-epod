variable "az_subscription_id" {
  description = "azure subscription id"
  type        = string
}

variable "region" {
  default = "westus2"
}

variable "vm_size" {
  default = "Standard_B1s"
}

variable "os_disk_size_in_gb" {
  default = 1024
}


variable "os_publisher" {
  default = "RedHat"
}

variable "os_offer" {
  default = "RHEL"
}

variable "os_sku" {
  default = "8_5"
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
  default     = "1.25.6"
  description = "Kubernetes version"
}

variable "node_vm_size" {
  default = "Standard_D8s_v3"
}

variable "min_node_count" {
  default     = "2"
  description = "AKS min nodes"
}

variable "max_node_count" {
  default     = "4"
  description = "AKS max nodes"
}

variable "output_file" {
  default = ".terraform.output"
}

variable "azpwd" {
  description = "common vm password, 16 characters containg --> [chars-alpha-num-special-char]"
}

variable "azuser" {
  default = "azuser"
}

variable "pod_owner" {
  description = "Securiti tenant Admin email"
}