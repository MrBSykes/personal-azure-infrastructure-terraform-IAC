terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "TerraformStateRG"
    storage_account_name = "sykestfstate"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  subscription_id                 = "ed6e958b-2f8b-475b-a5e4-97595e1b4beb"
}
 resource "azurerm_resource_group" "hub" {
  name     = "hub-rg"
  location = "eastus"
}
 resource "azurerm_virtual_network" "hub" {
  name                = "hub-vnet"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "hub_gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.0.0/24"]
}
# Dev Spoke
resource "azurerm_resource_group" "dev" {
  name     = "dev-rg"
  location = "eastus2"
}

resource "azurerm_virtual_network" "dev" {
  name                = "dev-vnet"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "dev_private" {
  name                 = "private-subnet"
  resource_group_name  = azurerm_resource_group.dev.name
  virtual_network_name = azurerm_virtual_network.dev.name
  address_prefixes     = ["10.1.1.0/24"]
}

# Prod Spoke
resource "azurerm_resource_group" "prod" {
  name     = "prod-rg"
  location = "eastus"
}

resource "azurerm_virtual_network" "prod" {
  name                = "prod-vnet"
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name
  address_space       = ["10.2.0.0/16"]
}

resource "azurerm_subnet" "prod_private" {
  name                 = "private-subnet"
  resource_group_name  = azurerm_resource_group.prod.name
  virtual_network_name = azurerm_virtual_network.prod.name
  address_prefixes     = ["10.2.1.0/24"]
}
# Hub to Dev peering
resource "azurerm_virtual_network_peering" "hub_to_dev" {
  name                      = "hub-to-dev"
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.dev.id
}

# Dev to Hub peering
resource "azurerm_virtual_network_peering" "dev_to_hub" {
  name                      = "dev-to-hub"
  resource_group_name       = azurerm_resource_group.dev.name
  virtual_network_name      = azurerm_virtual_network.dev.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
}

# Hub to Prod peering
resource "azurerm_virtual_network_peering" "hub_to_prod" {
  name                      = "hub-to-prod"
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.prod.id
}

# Prod to Hub peering
resource "azurerm_virtual_network_peering" "prod_to_hub" {
  name                      = "prod-to-hub"
  resource_group_name       = azurerm_resource_group.prod.name
  virtual_network_name      = azurerm_virtual_network.prod.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
}
# NSG for Dev private subnet
resource "azurerm_network_security_group" "dev_nsg" {
  name                = "dev-nsg"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name

  security_rule {
    name                       = "allow-ssh-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-https-outbound"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSG with Dev subnet
resource "azurerm_subnet_network_security_group_association" "dev_nsg_assoc" {
  subnet_id                 = azurerm_subnet.dev_private.id
  network_security_group_id = azurerm_network_security_group.dev_nsg.id
}
# Network interface for the VM
# resource "azurerm_network_interface" "dev_vm_nic" {
#  name                = "dev-vm-nic"
#  location            = "eastus2"
#  resource_group_name = azurerm_resource_group.dev.name
#
#  ip_configuration {
#    name                          = "internal"
#    subnet_id                     = azurerm_subnet.dev_private.id
#    private_ip_address_allocation = "Dynamic"
#  }
#}

# resource "azurerm_linux_virtual_machine" "dev_vm" {
#  name                  = "dev-vm"
#  location              = "eastus2"
#  resource_group_name   = azurerm_resource_group.dev.name
#  size                  = "Standard_B1ms"
#  admin_username        = "azureadmin"
#  network_interface_ids = [azurerm_network_interface.dev_vm_nic.id]
#
#  admin_ssh_key {
#    username   = "azureadmin"
#    public_key = file("C:/Users/bball/.ssh/id_rsa_azure.pub")
#  }
#
#  os_disk {
#    caching              = "ReadWrite"
#    storage_account_type = "Standard_LRS"
#  }
#
#  source_image_reference {
#    publisher = "Canonical"
#    offer     = "0001-com-ubuntu-server-jammy"
#    sku       = "22_04-lts"
#    version   = "latest"
#  }
#}# Storage Account
resource "azurerm_storage_account" "dev" {
  name                     = "sykesdevstore"
  resource_group_name      = azurerm_resource_group.dev.name
  location                 = azurerm_resource_group.dev.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}

# Private Endpoint for Storage
resource "azurerm_private_endpoint" "dev_storage" {
  name                = "dev-storage-pe"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
  subnet_id           = azurerm_subnet.dev_private.id

  private_service_connection {
    name                           = "dev-storage-psc"
    private_connection_resource_id = azurerm_storage_account.dev.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}