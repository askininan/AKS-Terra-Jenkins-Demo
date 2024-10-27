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

    # Enable Application Gateway Ingress Controller
  ingress_application_gateway {
    gateway_name = var.appgw_name
    subnet_id = azurerm_subnet.subnet1.id
  }
  
  tags = {
    env = var.env
  }
}

resource "azurerm_role_assignment" "aks_agic_integration" {
  scope = azurerm_virtual_network.vnet.id
  role_definition_name = "Network Contributor"
  principal_id = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
}