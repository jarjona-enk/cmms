terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Shared workspace, owned elsewhere. Read only.
data "azurerm_log_analytics_workspace" "shared" {
  name                = "workspacenewimplementations9584"
  resource_group_name = "New-Implementations"
}

# ── Production database server ───────────────────────────────────────────
# db-caneast-pmdms, in RG-CanEast-PMDMS, owned by the PMDMS team. Referenced
# here so the config records which server production talks to and fails fast
# if it is renamed or moved, but it is a DATA SOURCE: this config never
# creates, changes or destroys it, and `tofu destroy` cannot reach it.
#
# The CMMS database and role on it are created out of band.
data "azurerm_postgresql_flexible_server" "prod_db" {
  name                = "db-caneast-pmdms"
  resource_group_name = "RG-CanEast-PMDMS"
}

# The app connects by private-endpoint IP, not by name, so this reads the IP
# rather than hardcoding it. See the db_host comment in the module block for
# why the FQDN cannot be used.
data "azurerm_private_endpoint_connection" "prod_db" {
  name                = "PMDMSPrivateEndpointPostgreSQL"
  resource_group_name = "RG-CanEast-PMDMS"
}

variable "subscription_id" {
  type    = string
  default = "d14f7b8e-d71d-4106-ab93-990c96df467c"
}

# Public base URL of production, no trailing slash. Feeds both PUBLIC_API_URL
# and PUBLIC_FRONT_URL, which are the same host because one jar serves the API
# and the SPA.
#
# It has a default now that the pipeline no longer runs OpenTofu: a manual
# `tofu apply` needs no TF_VAR_public_url, and the intended URL is recorded in
# reviewable code rather than only in an Azure DevOps variable. Still
# overridable with TF_VAR_public_url if the pipeline ever applies again.
#
# ⚠️ This same value is compiled INTO the SPA bundle at image build time, from
# the pipeline variable PUBLIC_URL_PROD. The two must agree, or the browser
# calls one host while being served from another. Keep them in step.
variable "public_url" {
  type    = string
  default = "https://cmms.enerkem.com"
}

# The subnet is created out of band in the shared network resource group, so
# it stays outside this config's blast radius. See infra/README.md.
variable "vnet_integration_subnet_id" {
  type = string
}

module "cmms" {
  source = "../../modules/cmms"

  environment = "prod"
  image_tag   = "prod"
  # Dedicated Premium v3: the JVM plus a cold-start Liquibase run needs the headroom.
  plan_sku       = "P1v3"
  spring_profile = "prod"

  public_url                 = var.public_url
  vnet_integration_subnet_id = var.vnet_integration_subnet_id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.shared.id

  # db-caneast-pmdms (data source above), reached through its private endpoint
  # in VNET-CanEast-Tier1/Prod-Tier1-BackEnd - currently 10.225.1.104.
  #
  # By IP, not by FQDN, and deliberately so. The server has
  # publicNetworkAccess disabled, and there is no
  # privatelink.postgres.database.azure.com private DNS zone linked to
  # VNET-CanEast-Tier1. So db-caneast-pmdms.postgres.database.azure.com
  # resolves, from inside the VNet exactly as from outside, through the
  # privatelink CNAME to the server's PUBLIC address - which then refuses the
  # connection. prod-pmdms, the app that owns this database server, addresses
  # it by this same IP for the same reason.
  #
  # If a private DNS zone is ever linked to VNET-CanEast-Tier1, switch this to
  # data.azurerm_postgresql_flexible_server.prod_db.fqdn and drop the private
  # endpoint data source.
  db_host = data.azurerm_private_endpoint_connection.prod_db.private_service_connection[0].private_ip_address
  db_name = "atlas"
  db_user = "atlas"

  mail_recipients = "cmms-admins@enerkem.com"
  # Enable once SMTP is verified end to end.
  enable_email_notifications = false
  invitation_via_email       = false

  enable_sso       = true
  oauth2_provider  = "microsoft"
  oauth2_client_id = "REPLACE-WITH-ENTRA-APP-CLIENT-ID"
  oauth2_tenant_id = "cddc5ffd-9378-428d-bdb9-f54efe98769c"
}

output "db_server" {
  description = "The existing PostgreSQL server production uses, and the private-endpoint address it is reached on."
  value = {
    name = data.azurerm_postgresql_flexible_server.prod_db.name
    fqdn = data.azurerm_postgresql_flexible_server.prod_db.fqdn
    host = data.azurerm_private_endpoint_connection.prod_db.private_service_connection[0].private_ip_address
  }
}

output "web_app_name" { value = module.cmms.web_app_name }
output "default_hostname" { value = module.cmms.default_hostname }
output "key_vault_name" { value = module.cmms.key_vault_name }
output "image" { value = module.cmms.image }
