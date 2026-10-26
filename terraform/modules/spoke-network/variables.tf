variable "name" {
  description = "Environment name, e.g. dev or prod. Drives resource names."
  type        = string
}

variable "location" {
  description = "Azure region for this spoke."
  type        = string
}

variable "address_space" {
  description = "VNet CIDR. Must not overlap the hub or any other spoke."
  type        = string
}

variable "subnet_prefix" {
  description = "CIDR of the private subnet inside the VNet."
  type        = string
}

variable "hub_vnet_id" {
  description = "Resource ID of the hub VNet."
  type        = string
}

variable "hub_vnet_name" {
  description = "Name of the hub VNet."
  type        = string
}

variable "hub_resource_group_name" {
  description = "Resource group of the hub VNet."
  type        = string
}
