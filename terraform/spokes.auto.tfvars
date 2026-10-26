# Environment definitions. Contains no secrets, so this file is committed.
#
# STAGE 1 (refactor only): values below reproduce what is deployed today, so
# `terraform plan` should show resources MOVING and nothing changing.
#   - dev storage_locked_down = false  -> matches current (public access still on)
#   - prod nsg = false and no storage  -> prod controls arrive in stage 2

spokes = {
  dev = {
    location             = "eastus2"
    address_space        = "10.1.0.0/16"
    subnet_prefix        = "10.1.1.0/24"
    storage_account_name = "sykesdevstore"
    private_endpoint     = true
    storage_locked_down  = false # STAGE 1 only. Delete this line in stage 2.
  }

  prod = {
    location      = "eastus"
    address_space = "10.2.0.0/16"
    subnet_prefix = "10.2.1.0/24"
    nsg           = false # STAGE 1 only. Delete this line in stage 2.
    # Stage 2 adds:
    # storage_account_name = "sykesprodstore"
  }
}
