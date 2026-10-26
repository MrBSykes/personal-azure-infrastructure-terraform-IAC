# Every spoke (dev, prod, ...) is built from the same three modules.
# Adding an environment = adding an entry to spokes.auto.tfvars, not new code.

module "spoke_network" {
  source   = "./modules/spoke-network"
  for_each = var.spokes

  name                    = each.key
  location                = each.value.location
  address_space           = each.value.address_space
  subnet_prefix           = each.value.subnet_prefix
  hub_vnet_id             = azurerm_virtual_network.hub.id
  hub_vnet_name           = azurerm_virtual_network.hub.name
  hub_resource_group_name = azurerm_resource_group.hub.name
}

module "baseline_nsg" {
  source   = "./modules/baseline-nsg"
  for_each = { for k, v in var.spokes : k => v if v.nsg }

  name                = each.key
  location            = module.spoke_network[each.key].location
  resource_group_name = module.spoke_network[each.key].resource_group_name
  subnet_id           = module.spoke_network[each.key].subnet_id
  ssh_source_prefix   = azurerm_virtual_network.hub.address_space[0]
}

module "secure_storage" {
  source   = "./modules/secure-storage"
  for_each = { for k, v in var.spokes : k => v if v.storage_account_name != null }

  name                     = each.key
  storage_account_name     = each.value.storage_account_name
  location                 = module.spoke_network[each.key].location
  resource_group_name      = module.spoke_network[each.key].resource_group_name
  subnet_id                = module.spoke_network[each.key].subnet_id
  private_endpoint_enabled = each.value.private_endpoint
  locked_down              = each.value.storage_locked_down
}
