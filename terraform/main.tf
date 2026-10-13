resource "azurerm_resource_group" "main" {
  name     = "rg-container-platform-dev"
  location = "northeurope"

  tags = {
    environment = "dev"
    project     = "azure-container-platform"
    managed_by  = "terraform"
  }
}

resource "azurerm_container_app_environment" "main" {
  name                = "cae-container-platform-dev"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }
}

resource "azurerm_container_app" "api" {
  name                         = "ca-container-api-dev"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  template {
    min_replicas = 0
    max_replicas = 1

    container {
      name   = "api"
      image  = "ghcr.io/ignastamosaitis/azure-container-platform:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  ingress {
    external_enabled           = true
    allow_insecure_connections = false
    target_port                = 8080
    transport                  = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}
