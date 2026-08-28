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

variable "subscription_id" {
  type    = string
  default = "d14f7b8e-d71d-4106-ab93-990c96df467c"
}

# Supplied by the pipeline as TF_VAR_public_url. It has to come from there
# rather than from this file: Create React App compiles it into the SPA at
# image build time, which happens before this config is applied.
variable "public_url" {
  type = string
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

  # Shared server reached through its private endpoint in
  # VNET-CanEast-Tier1/Prod-Tier1-BackEnd, the same one the budget app uses.
  # Database and role are created out of band.
  db_host = "10.225.1.107"
  db_name = "atlasprod"
  db_user = "atlasprod"

  mail_recipients = "cmms-admins@enerkem.com"
  # Enable once SMTP is verified end to end.
  enable_email_notifications = false
  invitation_via_email       = false

  enable_sso       = true
  oauth2_provider  = "microsoft"
  oauth2_client_id = "REPLACE-WITH-ENTRA-APP-CLIENT-ID"
  oauth2_tenant_id = "cddc5ffd-9378-428d-bdb9-f54efe98769c"
}

output "web_app_name" { value = module.cmms.web_app_name }
output "default_hostname" { value = module.cmms.default_hostname }
output "key_vault_name" { value = module.cmms.key_vault_name }
output "image" { value = module.cmms.image }
