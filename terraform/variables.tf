variable "subscription_id" {
  description = "Azure subscription ID to deploy into. Supply it with the TF_VAR_subscription_id environment variable so it never lands in a file."
  type        = string
}

variable "spokes" {
  description = <<-EOT
    Spoke environments, defined as data. Each key (e.g. "dev", "prod") becomes
    its own resource group, VNet, private subnet and hub peering. Optional
    controls are switched on per spoke:
      nsg                  - attach the baseline default-deny NSG to the subnet
      storage_account_name - create a locked-down storage account (null = none)
      private_endpoint     - give that storage account a blob private endpoint
      storage_locked_down  - disable public network access and anonymous blobs
  EOT

  type = map(object({
    location             = string
    address_space        = string
    subnet_prefix        = string
    nsg                  = optional(bool, true)
    storage_account_name = optional(string)
    private_endpoint     = optional(bool, false)
    storage_locked_down  = optional(bool, true)
  }))
}
