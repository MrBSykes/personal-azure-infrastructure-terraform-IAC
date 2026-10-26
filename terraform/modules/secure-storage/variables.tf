variable "name" {
  description = "Environment name; used for the private endpoint names."
  type        = string
}

variable "storage_account_name" {
  description = "Globally unique, 3-24 chars, lowercase letters and digits only."
  type        = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  description = "Subnet that hosts the private endpoint."
  type        = string
}

variable "private_endpoint_enabled" {
  description = "Create a blob private endpoint (costs money per hour)."
  type        = bool
  default     = false
}

variable "locked_down" {
  description = "true = public network access off and anonymous blob access off."
  type        = bool
  default     = true
}
