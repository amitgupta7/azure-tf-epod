
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

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.az_name_prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.region
  resource_group_name = var.az_resource_group
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.az_name_prefix}_pod-subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = var.az_resource_group
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "pod_sg" {
  name                = "${var.az_name_prefix}_pods-sg"
  location            = var.region
  resource_group_name = var.az_resource_group

  security_rule {
    name                       = "SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "pod_ip" {
  name                = "${var.az_name_prefix}_jumpbox_ip"
  location            = var.region
  resource_group_name = var.az_resource_group
  allocation_method   = "Dynamic"
  domain_name_label   = "${var.az_name_prefix}-jumpbox"
}

resource "azurerm_network_interface" "pod_nic" {
  name                = "${var.az_name_prefix}_jumpbox_nic"
  location            = var.region
  resource_group_name = var.az_resource_group
  ip_configuration {
    name                          = "${var.az_name_prefix}_jumpbox_ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.2.21"
    public_ip_address_id          = azurerm_public_ip.pod_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nsg" {
  network_interface_id      = azurerm_network_interface.pod_nic.id
  network_security_group_id = azurerm_network_security_group.pod_sg.id
}

resource "azurerm_linux_virtual_machine" "jumpbox-vm" {
  name                  = "${var.az_name_prefix}-jumpbox-vm"
  network_interface_ids = [azurerm_network_interface.pod_nic.id]
  //variables
  location            = var.region
  resource_group_name = var.az_resource_group
  size                = var.vm_size
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = var.os_publisher
    offer     = var.os_offer
    sku       = var.os_sku
    version   = var.os_version
  }
  admin_username                  = var.azuser
  admin_password                  = var.azpwd
  disable_password_authentication = false

}

resource "null_resource" "install_dependencies" {
  triggers = {
    build_number = "${timestamp()}"
  }

  depends_on = [azurerm_linux_virtual_machine.jumpbox-vm]
  connection {
    type     = "ssh"
    user     = var.azuser
    password = var.azpwd
    host     = azurerm_public_ip.pod_ip.fqdn
  }

  provisioner "file" {
    source = "install_dependencies.sh"
    destination = "/home/${var.azuser}/install_dependencies.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sh /home/${var.azuser}/install_dependencies.sh"
     ]
  }
}

resource "null_resource" "post_provisioning" {
  triggers = {
    build_number = "${timestamp()}"
  }

  depends_on = [azurerm_linux_virtual_machine.jumpbox-vm, azurerm_kubernetes_cluster.aks, null_resource.install_dependencies]
  connection {
    type     = "ssh"
    user     = var.azuser
    password = var.azpwd
    host     = azurerm_public_ip.pod_ip.fqdn
  }

  provisioner "local-exec" {
  command = "az aks get-credentials --resource-group ${var.az_resource_group} --name ${azurerm_kubernetes_cluster.aks.name} --file config.aks --overwrite-existing"
}

  provisioner "file" {
    source = "config.aks"
    destination = "/home/${var.azuser}/.kube_config"
    
  }

  provisioner "file" {
    source = "online_kots_installer.sh"
    destination = "/home/${var.azuser}/online_kots_installer.sh"
  }

    provisioner "file" {
    source = "license.yaml"
    destination = "/home/${var.azuser}/license.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/${var.azuser}/.kube && mv /home/${var.azuser}/.kube_config /home/${var.azuser}/.kube/config && chmod 600 /home/${var.azuser}/.kube/config"
     ]
  }

  provisioner "remote-exec" {
    ## to-do: need to mount a larger partition to / (tmp downlaod to /mnt/ due to limitations of azure RHEL provisioning)
    inline = [
      "sh /home/${var.azuser}/online_kots_installer.sh -o ${var.pod_owner} -r ${var.region} -k ${var.X_API_Key} -s ${var.X_API_Secret} -t ${var.X_TIDENT} -n ${var.az_name_prefix}",
     ]
  }
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
    os_disk_size_gb     = 512
    os_sku              = "Ubuntu" 
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "dev"
  }
}

output "ssh_credentials" {
  value = "ssh -L 8800:localhost:8800 ${var.azuser}@${azurerm_public_ip.pod_ip.fqdn} \nwith password: ${var.azpwd}"
}