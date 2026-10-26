# Tells Terraform that resources defined in the old flat main.tf now live inside
# modules, so it RENAMES them in state instead of destroying and recreating.
# Safe to delete once every state that used the old addresses has been applied.

# ---- dev spoke network ----
moved {
  from = azurerm_resource_group.dev
  to   = module.spoke_network["dev"].azurerm_resource_group.this
}
moved {
  from = azurerm_virtual_network.dev
  to   = module.spoke_network["dev"].azurerm_virtual_network.this
}
moved {
  from = azurerm_subnet.dev_private
  to   = module.spoke_network["dev"].azurerm_subnet.private
}
moved {
  from = azurerm_virtual_network_peering.hub_to_dev
  to   = module.spoke_network["dev"].azurerm_virtual_network_peering.hub_to_spoke
}
moved {
  from = azurerm_virtual_network_peering.dev_to_hub
  to   = module.spoke_network["dev"].azurerm_virtual_network_peering.spoke_to_hub
}

# ---- prod spoke network ----
moved {
  from = azurerm_resource_group.prod
  to   = module.spoke_network["prod"].azurerm_resource_group.this
}
moved {
  from = azurerm_virtual_network.prod
  to   = module.spoke_network["prod"].azurerm_virtual_network.this
}
moved {
  from = azurerm_subnet.prod_private
  to   = module.spoke_network["prod"].azurerm_subnet.private
}
moved {
  from = azurerm_virtual_network_peering.hub_to_prod
  to   = module.spoke_network["prod"].azurerm_virtual_network_peering.hub_to_spoke
}
moved {
  from = azurerm_virtual_network_peering.prod_to_hub
  to   = module.spoke_network["prod"].azurerm_virtual_network_peering.spoke_to_hub
}

# ---- dev NSG ----
moved {
  from = azurerm_network_security_group.dev_nsg
  to   = module.baseline_nsg["dev"].azurerm_network_security_group.this
}
moved {
  from = azurerm_subnet_network_security_group_association.dev_nsg_assoc
  to   = module.baseline_nsg["dev"].azurerm_subnet_network_security_group_association.this
}

# ---- dev storage + private endpoint ----
moved {
  from = azurerm_storage_account.dev
  to   = module.secure_storage["dev"].azurerm_storage_account.this
}
moved {
  from = azurerm_private_endpoint.dev_storage
  to   = module.secure_storage["dev"].azurerm_private_endpoint.this[0]
}
