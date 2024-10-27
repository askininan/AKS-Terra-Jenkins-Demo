resource "azurerm_virtual_network" "vnet" {
  name                = var.VnetName
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    env = var.env
  }
}