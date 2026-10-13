output "app_url" {
  description = "Public HTTPS URL of the FastAPI application"
  value       = "https://${azurerm_container_app.api.ingress[0].fqdn}"
}
