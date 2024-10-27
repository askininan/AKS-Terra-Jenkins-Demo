variable "az_SubID" {
  type = string
}

variable "region" {
  type        = string
  description = "Resources AZ region"
}

variable "resource_group_name" {
  type        = string
  description = "RG name"
}

variable "VnetName" {
  type    = string
  default = "Custom vnet name"
}