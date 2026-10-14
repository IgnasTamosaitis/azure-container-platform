resource "azurerm_resource_group" "main" {
  name     = "rg-container-platform-dev"
  location = "northeurope"

  tags = {
    environment = "dev"
    project     = "azure-container-platform"
    managed_by  = "terraform"
  }
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-container-platform-dev"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 0.5 # hard cap on ingestion to keep costs predictable

  tags = azurerm_resource_group.main.tags
}

resource "azurerm_container_app_environment" "main" {
  name                       = "cae-container-platform-dev"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  logs_destination           = "log-analytics"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

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

  lifecycle {
    ignore_changes = [
      template[0].container[0].image
    ]
  }

  template {
    min_replicas = 0
    max_replicas = 1

    container {
      name   = "api"
      image  = "ghcr.io/ignastamosaitis/azure-container-platform:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      startup_probe {
        transport               = "HTTP"
        port                    = 8080
        path                    = "/health"
        interval_seconds        = 5
        failure_count_threshold = 10
      }

      liveness_probe {
        transport               = "HTTP"
        port                    = 8080
        path                    = "/health"
        interval_seconds        = 30
        failure_count_threshold = 3
      }

      readiness_probe {
        transport               = "HTTP"
        port                    = 8080
        path                    = "/health"
        interval_seconds        = 10
        failure_count_threshold = 3
      }
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

# Optional alerting: created only when alert_email is set
resource "azurerm_monitor_action_group" "email" {
  count               = var.alert_email == "" ? 0 : 1
  name                = "ag-container-platform-dev"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "acp-dev"

  email_receiver {
    name                    = "owner"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_metric_alert" "http_5xx" {
  count               = var.alert_email == "" ? 0 : 1
  name                = "alert-api-5xx-dev"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_container_app.api.id]
  description         = "API returned 5 or more server errors (5xx) within 5 minutes."
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.App/containerApps"
    metric_name      = "Requests"
    aggregation      = "Total"
    operator         = "GreaterThanOrEqual"
    threshold        = 5

    dimension {
      name     = "statusCodeCategory"
      operator = "Include"
      values   = ["5xx"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.email[0].id
  }
}
