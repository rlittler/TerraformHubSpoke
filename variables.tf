variable "rgname" {
  description = "The name of the resource group in which the resources will be created"
  default     = "TERRAFORM-RG"
}


variable "hubVnetName" {
  description = "The name of the HUB-VNET"
  default     = "HUB-VNET"
}

variable "spoke01VNetName" {
  description = "The name of the SPOKE01-VNET"
  default     = "SPOKE01-VNET"
}

variable "spoke02VNetName" {
  description = "The name of the SPOKE02-VNET"
  default     = "SPOKE02-VNET"
}



variable "az_fw_name" {
  default = "AZFW-TF01"
}

variable "azfw_pip_name" {
  default = "azfwpiptf"
}

variable "location" {
  default = "West Europe"
}

variable "fwrgname" {
  default = "AzureFirewallTF"
}