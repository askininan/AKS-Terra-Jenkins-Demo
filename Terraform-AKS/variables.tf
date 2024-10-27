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

variable "aks_cluster_name" {
  type        = string
  description = "AKS cluster name"
}

variable "aks_version" {
  type        = string
  description = "Kubernetes version"
}

variable "default_subnet_name" {
  type = string
}

variable "aks_subnet_name" {
  type = string
}

variable "env" {
  type = string
}

variable "appgw_name" {
  type        = string
  description = "application gateway name"
}