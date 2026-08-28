output "web_app_name" {
  description = "Name of the web app, for the pipeline's container update step."
  value       = azurerm_linux_web_app.cmms.name
}

output "default_hostname" {
  description = "Azure-assigned hostname, before any custom domain."
  value       = azurerm_linux_web_app.cmms.default_hostname
}

output "principal_id" {
  description = "Managed identity object id, for granting access to anything outside this module."
  value       = azurerm_user_assigned_identity.cmms.principal_id
}

output "key_vault_name" {
  description = "Vault the four required secrets must be seeded into before the first deploy."
  value       = azurerm_key_vault.cmms.name
}

output "storage_account_name" {
  value = azurerm_storage_account.cmms.name
}

output "image" {
  description = "Fully qualified image this environment tracks."
  value       = "${data.azurerm_container_registry.shared.login_server}/${local.image}"
}
