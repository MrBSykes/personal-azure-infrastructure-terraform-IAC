# Storage account with network rules default-deny. Optionally fully locked down
# (no public network access, no anonymous blobs) and optionally reachable
# through a private endpoint inside the spoke subnet.

resource "azurerm_storage_account" "this" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  public_network_access_enabled   = !var.locked_down
  allow_nested_items_to_be_public = !var.locked_down

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}

# Billed per hour plus per GB processed, so it is optional per environment.
resource "azurerm_private_endpoint" "this" {
  count = var.private_endpoint_enabled ? 1 : 0

  name                = "${var.name}-storage-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${var.name}-storage-psc"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}
