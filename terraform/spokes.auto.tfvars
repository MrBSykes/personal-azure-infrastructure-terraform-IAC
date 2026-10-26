# Environment definitions. Contains no secrets, so this file is committed.
# Each spoke gets the baseline NSG by default and a locked-down storage account
# when storage_account_name is set.

spokes = {
  dev = {
    location             = "eastus2"
    address_space        = "10.1.0.0/16"
    subnet_prefix        = "10.1.1.0/24"
    storage_account_name = "sykesdevstore"
    private_endpoint     = true
  }

  prod = {
    location             = "eastus"
    address_space        = "10.2.0.0/16"
    subnet_prefix        = "10.2.1.0/24"
    storage_account_name = "sykesprodstore"
    # No private endpoint in prod yet: it bills per hour. Documented trade-off.
  }
}