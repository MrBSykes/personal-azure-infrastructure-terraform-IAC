# Azure Bastion in the hub: browser-based SSH/RDP to private VMs over TLS, so
# VMs need no public IP and no internet-facing management port.
# Basic SKU is required to reach VMs in PEERED networks (Developer SKU cannot).
# Bastion bills hourly from creation until deletion. Off by default.

resource "azurerm_subnet" "hub_bastion" {
  count = var.enable_bastion ? 1 : 0

  name                 = "AzureBastionSubnet" # this exact name is mandatory
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.1.0/26"] # /26 is the minimum; inside the NSG's 10.0.0.0/16 SSH rule
}

resource "azurerm_public_ip" "hub_bastion" {
  count = var.enable_bastion ? 1 : 0

  name                = "hub-bastion-pip"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "hub" {
  count = var.enable_bastion ? 1 : 0

  name                = "hub-bastion"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  sku                 = "Basic"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.hub_bastion[0].id
    public_ip_address_id = azurerm_public_ip.hub_bastion[0].id
  }
}
