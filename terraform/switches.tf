# Cost switches. Both default to false, so a normal plan/apply creates nothing
# billable. Turn on only for a timed demo, then turn off and apply (or destroy).

variable "enable_vm" {
  description = "Create the dev test VM and its NIC (billable while it exists)."
  type        = bool
  default     = false
}

variable "enable_bastion" {
  description = "Create the hub Azure Bastion (Basic SKU) with its subnet and public IP. Billed hourly while it exists."
  type        = bool
  default     = false
}

variable "vm_size" {
  description = "VM size. Check it is deployable with: az vm list-skus --location eastus2 --size Standard_B"
  type        = string
  default     = "Standard_B1s"
}

variable "ssh_public_key" {
  description = "Public SSH key text for the VM admin user. A public key is not a secret."
  type        = string
  default     = null
}
