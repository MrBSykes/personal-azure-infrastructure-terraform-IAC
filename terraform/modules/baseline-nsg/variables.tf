variable "name" {
  description = "Environment name; the NSG is called <name>-nsg."
  type        = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  description = "Subnet the NSG is attached to."
  type        = string
}

variable "ssh_source_prefix" {
  description = "Only source allowed to reach port 22 (the hub address space)."
  type        = string
}
