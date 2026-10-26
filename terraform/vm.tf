# Planned dev VM, not deployed: Azure free-tier VM capacity was unavailable in
# eastus and eastus2 (see troubleshooting log, issue 4). Kept here, commented
# out, and updated to the module outputs so it is ready to enable.

# resource "azurerm_network_interface" "dev_vm_nic" {
#   name                = "dev-vm-nic"
#   location            = module.spoke_network["dev"].location
#   resource_group_name = module.spoke_network["dev"].resource_group_name
#
#   ip_configuration {
#     name                          = "internal"
#     subnet_id                     = module.spoke_network["dev"].subnet_id
#     private_ip_address_allocation = "Dynamic"
#   }
# }
#
# resource "azurerm_linux_virtual_machine" "dev_vm" {
#   name                  = "dev-vm"
#   location              = module.spoke_network["dev"].location
#   resource_group_name   = module.spoke_network["dev"].resource_group_name
#   size                  = "Standard_B1ms"
#   admin_username        = "azureadmin"
#   network_interface_ids = [azurerm_network_interface.dev_vm_nic.id]
#
#   admin_ssh_key {
#     username   = "azureadmin"
#     public_key = file("~/.ssh/id_rsa_azure.pub")
#   }
#
#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }
#
#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "0001-com-ubuntu-server-jammy"
#     sku       = "22_04-lts"
#     version   = "latest"
#   }
# }
