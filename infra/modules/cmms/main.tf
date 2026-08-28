terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# ── Shared infrastructure: read only ─────────────────────────────────────
# Everything below is owned by other teams and shared with a dozen other
# applications. It is looked up, never created, so `tofu destroy` on this
# config can never take down another team's app.

data "azurerm_resource_group" "shared" {
  name = var.resource_group_name
}

data "azurerm_container_registry" "shared" {
  name                = var.acr_name
  resource_group_name = var.acr_resource_group_name
}

locals {
  name         = "cmms-${var.environment}"
  storage_name = "cmmsstorage${var.environment}001"
  vault_name   = "enkm-cmms-${var.environment}"
  container    = "atlas-files"
  image        = "${var.image_repository}:${var.image_tag}"

  tags = merge({
    application = "cmms"
    environment = var.environment
    managed_by  = "opentofu"
    repository  = "EnerkemIT/New Services Implementations/cmms"
  }, var.tags)

  # Reference a secret by name, resolved by the web app's managed identity at
  # runtime. No version pinned, so rotating a secret takes effect without a
  # redeploy. Tofu never reads these values, so no secret reaches the state
  # file or the pipeline.
  kv = { for k in ["db-password", "jwt-secret-key", "oauth2-client-secret", "smtp-password"] :
    k => "@Microsoft.KeyVault(VaultName=${local.vault_name};SecretName=${k})"
  }
}

# ── Identity ─────────────────────────────────────────────────────────────
# User-assigned rather than system-assigned, deliberately. A system-assigned
# identity only exists once the web app does, so its role assignments can only
# be created afterwards - and the app needs AcrPull to pull its first image
# and Key Vault access to resolve its first secret reference. That is a
# genuine dependency cycle, and the usual workaround is a manual restart after
# the first apply. Creating the identity separately lets every role land
# before the app is created, so a cold `tofu apply` produces a working app.

resource "azurerm_user_assigned_identity" "cmms" {
  name                = "id-${local.name}"
  resource_group_name = data.azurerm_resource_group.shared.name
  location            = var.location
  tags                = local.tags
}

# ── Compute ──────────────────────────────────────────────────────────────

resource "azurerm_service_plan" "cmms" {
  name                = "asp-${local.name}"
  resource_group_name = data.azurerm_resource_group.shared.name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.plan_sku
  tags                = local.tags
}

# ── Storage for attachments and exports ──────────────────────────────────
# Browsers fetch attachments straight from here via SAS URLs handed out by
# FileMapper, so this account must stay publicly reachable. Blobs themselves
# are private: allow_nested_items_to_be_public is false, and every download
# goes through a short-lived signature.

resource "azurerm_storage_account" "cmms" {
  name                            = local.storage_name
  resource_group_name             = data.azurerm_resource_group.shared.name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  public_network_access_enabled   = true
  allow_nested_items_to_be_public = false
  tags                            = local.tags

  blob_properties {
    delete_retention_policy {
      days = var.environment == "prod" ? 30 : 7
    }
  }
}

resource "azurerm_storage_container" "files" {
  name                  = local.container
  storage_account_id    = azurerm_storage_account.cmms.id
  container_access_type = "private"
}

# ── Secrets ──────────────────────────────────────────────────────────────
# The vault is created empty. Seed it by hand (or with the az commands in
# infra/README.md) BEFORE the first deploy: the app settings above reference
# these secrets, and a missing one leaves the setting unresolved and the
# container unable to start.

resource "azurerm_key_vault" "cmms" {
  name                       = local.vault_name
  resource_group_name        = data.azurerm_resource_group.shared.name
  location                   = var.location
  tenant_id                  = var.oauth2_tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  purge_protection_enabled   = var.environment == "prod"
  soft_delete_retention_days = 7
  tags                       = local.tags
}

# ── Web app ──────────────────────────────────────────────────────────────

resource "azurerm_linux_web_app" "cmms" {
  name                          = local.name
  resource_group_name           = data.azurerm_resource_group.shared.name
  location                      = azurerm_service_plan.cmms.location
  service_plan_id               = azurerm_service_plan.cmms.id
  https_only                    = true
  public_network_access_enabled = true
  tags                          = local.tags

  # Regional VNet integration: the database has public access disabled and is
  # injected into a private VNet, so this is the only route to it.
  virtual_network_subnet_id = var.vnet_integration_subnet_id

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.cmms.id]
  }

  # Both of these are required when the identity is user-assigned: without
  # them the platform falls back to the (absent) system-assigned identity and
  # every Key Vault reference and registry pull fails.
  key_vault_reference_identity_id = azurerm_user_assigned_identity.cmms.id

  site_config {
    always_on = true
    # Pull from ACR as this app's managed identity rather than with registry
    # credentials. Paired with the AcrPull assignment below.
    container_registry_use_managed_identity       = true
    container_registry_managed_identity_client_id = azurerm_user_assigned_identity.cmms.client_id
    ftps_state                                    = "Disabled"
    minimum_tls_version                           = "1.2"
    health_check_path                             = "/health-check"
    # Liquibase runs the whole changelog on a cold start; the default 2 minute
    # eviction window will kill the container mid-migration.
    health_check_eviction_time_in_min = 10
    # Send all outbound traffic through the integrated subnet, so database
    # traffic actually uses the private route.
    vnet_route_all_enabled = true

    application_stack {
      docker_image_name   = local.image
      docker_registry_url = "https://${data.azurerm_container_registry.shared.login_server}"
    }
  }

  app_settings = {
    # Not application config: Web App for Containers needs this to know which
    # port the container listens on. Without it the platform probes the wrong
    # port and every request returns 504.
    WEBSITES_PORT = "8080"

    SPRING_PROFILES_ACTIVE = var.spring_profile

    # Host:port/database only. application.yml prepends jdbc:postgresql://
    DB_URL  = "${var.db_fqdn}:5432/${var.db_name}"
    DB_USER = var.db_user
    DB_PWD  = local.kv["db-password"]

    JWT_SECRET_KEY = local.kv["jwt-secret-key"]

    # One jar serves the API and the SPA, so these are the same host.
    PUBLIC_API_URL   = var.public_url
    PUBLIC_FRONT_URL = var.public_url

    MAIL_RECIPIENTS            = var.mail_recipients
    MAIL_TYPE                  = var.mail_type
    SMTP_HOST                  = var.smtp_host
    SMTP_PORT                  = var.smtp_port
    SMTP_USER                  = var.smtp_user
    SMTP_FROM                  = var.smtp_from
    SMTP_PWD                   = local.kv["smtp-password"]
    ENABLE_EMAIL_NOTIFICATIONS = tostring(var.enable_email_notifications)
    INVITATION_VIA_EMAIL       = tostring(var.invitation_via_email)

    # No account key: AzureBlobService authenticates as the managed identity
    # and signs downloads with user delegation SAS.
    STORAGE_TYPE            = "azure"
    AZURE_STORAGE_ACCOUNT   = azurerm_storage_account.cmms.name
    AZURE_STORAGE_CONTAINER = azurerm_storage_container.files.name

    ENABLE_SSO           = tostring(var.enable_sso)
    OAUTH2_PROVIDER      = var.oauth2_provider
    OAUTH2_CLIENT_ID     = var.oauth2_client_id
    OAUTH2_TENANT_ID     = var.oauth2_tenant_id
    OAUTH2_CLIENT_SECRET = local.kv["oauth2-client-secret"]

    # Single origin: the SPA and the API share a host.
    ENABLE_CORS                 = "false"
    ALLOWED_ORGANIZATION_ADMINS = var.allowed_organization_admins
  }

  # Every role must land before the app starts, so its first image pull and
  # first Key Vault reference both succeed. Possible only because the identity
  # is user-assigned; see the comment on it above.
  depends_on = [
    azurerm_role_assignment.acr_pull,
    azurerm_role_assignment.kv_secrets,
    azurerm_role_assignment.blob_contributor,
    azurerm_role_assignment.blob_delegator,
  ]
}

# ── Role assignments for the app's managed identity ──────────────────────

resource "azurerm_role_assignment" "acr_pull" {
  scope                = data.azurerm_container_registry.shared.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.cmms.principal_id
}

resource "azurerm_role_assignment" "kv_secrets" {
  scope                = azurerm_key_vault.cmms.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.cmms.principal_id
}

# Read and write the blobs themselves.
resource "azurerm_role_assignment" "blob_contributor" {
  scope                = azurerm_storage_account.cmms.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.cmms.principal_id
}

# Mint the user delegation key that signs download URLs. Without this the app
# uploads fine and every download link fails.
resource "azurerm_role_assignment" "blob_delegator" {
  scope                = azurerm_storage_account.cmms.id
  role_definition_name = "Storage Blob Delegator"
  principal_id         = azurerm_user_assigned_identity.cmms.principal_id
}

# ── Diagnostics ──────────────────────────────────────────────────────────

resource "azurerm_monitor_diagnostic_setting" "cmms" {
  name                       = "cmms-${var.environment}-logs"
  target_resource_id         = azurerm_linux_web_app.cmms.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AppServiceConsoleLogs"
  }
  enabled_log {
    category = "AppServiceHTTPLogs"
  }
  enabled_log {
    category = "AppServicePlatformLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
