output "app_url" {
  description = "Public HTTPS URL of the FastAPI application"
  value       = "https://${azurerm_container_app.api.ingress[0].fqdn}"
}

output "log_analytics_workspace_name" {
  description = "Log Analytics workspace holding the Container Apps console and system logs"
  value       = azurerm_log_analytics_workspace.main.name
}
