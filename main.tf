locals {
  base_name             = "${var.project_name}-${var.environment}"
  resolved_rg_name      = coalesce(var.resource_group_name, "rg-${local.base_name}")
  use_existing_rg       = var.create_resource_group == false
  resolved_rg_location  = local.use_existing_rg ? data.azurerm_resource_group.existing[0].location : azurerm_resource_group.this[0].location
  resolved_resource_group_name = local.use_existing_rg ? data.azurerm_resource_group.existing[0].name : azurerm_resource_group.this[0].name

  common_tags = merge(
    {
      project     = var.project_name
      environment = var.environment
      managed_by  = "terraform"
    },
    var.tags
  )
}

resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "azurerm_resource_group" "this" {
  count    = var.create_resource_group ? 1 : 0
  name     = local.resolved_rg_name
  location = var.location
  tags     = local.common_tags
}

data "azurerm_resource_group" "existing" {
  count = var.create_resource_group ? 0 : 1
  name  = local.resolved_rg_name
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "law-${local.base_name}-${random_string.suffix.result}"
  location            = local.resolved_rg_location
  resource_group_name = local.resolved_resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags
}

resource "azurerm_container_registry" "this" {
  name                = "acr${replace(var.project_name, "-", "")}${var.environment}${random_string.suffix.result}"
  resource_group_name = local.resolved_resource_group_name
  location            = local.resolved_rg_location
  sku                 = "Standard"
  admin_enabled       = false
  tags                = local.common_tags
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = "aks-${local.base_name}"
  location            = local.resolved_rg_location
  resource_group_name = local.resolved_resource_group_name
  dns_prefix          = "aks-${local.base_name}-${random_string.suffix.result}"
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                 = "system"
    node_count           = var.node_count
    vm_size              = var.node_vm_size
    os_disk_size_gb      = 128
    type                 = "VirtualMachineScaleSets"
    orchestrator_version = var.kubernetes_version
    enable_auto_scaling  = false
  }

  identity {
    type = "SystemAssigned"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  }

  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
  }

  role_based_access_control_enabled = true
  local_account_disabled            = false
  sku_tier                          = "Free"

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  tags = local.common_tags
}

resource "azurerm_role_assignment" "aks_to_acr_pull" {
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}
