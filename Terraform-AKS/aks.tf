resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.aks_cluster_name}-${var.env}"

  kubernetes_version      = var.aks_version
  private_cluster_enabled = false
  node_resource_group     = "${var.resource_group_name}-${var.env}-${var.aks_cluster_name}"

  sku_tier = "Free"

  network_profile {
    network_plugin = "azure"
    dns_service_ip = "10.0.64.10"
    service_cidr   = "10.0.64.0/19"
  }

  default_node_pool {
    name                 = "default"
    vm_size              = "Standard_D3_v2"
    vnet_subnet_id       = azurerm_subnet.subnet2.id
    orchestrator_version = var.aks_version
    node_count           = 1
  }

  identity {
    type = "SystemAssigned"
  }
}