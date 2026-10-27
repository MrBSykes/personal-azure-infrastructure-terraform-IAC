# Dev test VM: private only (no public IP). Reached through Bastion in the hub.
# Off by default (enable_vm = false). Free-tier VM capacity was unavailable
# during the original build (troubleshooting log, issue 4).

resource "azurerm_network_interface" "dev_vm" {
  count = var.enable_vm ? 1 : 0

  name                = "dev-vm-nic"
  location            = module.spoke_network["dev"].location
  resource_group_name = module.spoke_network["dev"].resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.spoke_network["dev"].subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "dev" {
  count = var.enable_vm ? 1 : 0

  name                  = "dev-vm"
  location              = module.spoke_network["dev"].location
  resource_group_name   = module.spoke_network["dev"].resource_group_name
  size                  = var.vm_size
  admin_username        = "azureadmin"
  network_interface_ids = [azurerm_network_interface.dev_vm[0].id]

  # Key-based login only; password authentication stays disabled.
  admin_ssh_key {
    username   = "azureadmin"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  lifecycle {
    precondition {
      condition     = var.ssh_public_key != null
      error_message = "enable_vm = true requires ssh_public_key (TF_VAR_ssh_public_key)."
    }
  }
}
