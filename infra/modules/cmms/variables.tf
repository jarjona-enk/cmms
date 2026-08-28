variable "environment" {
  description = "Environment short name. Becomes part of every resource name."
  type        = string
  validation {
    condition     = contains(["test", "prod"], var.environment)
    error_message = "environment must be \"test\" or \"prod\"."
  }
}

variable "location" {
  description = "Azure region for the web app and storage. Enerkem apps live in canadaeast."
  type        = string
  default     = "canadaeast"
}

variable "resource_group_name" {
  description = "Existing shared resource group. Read, never created or destroyed by this config."
  type        = string
  default     = "New-Implementations"
}

variable "plan_sku" {
  description = "App Service Plan SKU. The JVM plus Liquibase on boot needs real memory; B1 is not enough."
  type        = string
}

variable "acr_name" {
  description = "Existing shared container registry. Read, never managed here."
  type        = string
  default     = "enerkem"
}

variable "acr_resource_group_name" {
  description = "Resource group holding the shared registry."
  type        = string
  default     = "New-Implementations"
}

variable "image_repository" {
  description = "Repository inside the registry."
  type        = string
  default     = "cmms"
}

variable "image_tag" {
  description = "Moving tag this environment tracks (test or prod). The pipeline also pushes an immutable version tag for rollback."
  type        = string
}

variable "vnet_integration_subnet_id" {
  description = <<-EOT
    Resource id of a subnet delegated to Microsoft.Web/serverFarms, used for
    regional VNet integration so the app can reach the private database.

    NOT created here: it lives in RG-CanEast-Tier1, outside this config's
    blast radius. It must be a /28 or larger in VNET-CanEast-Tier1 (canadaeast,
    same region as the app - regional integration cannot cross regions), which
    is where the database's private endpoint lives. This mirrors how the budget
    app reaches the same server, via Dev-Tier1-PMOProject.
  EOT
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Existing shared Log Analytics workspace for container logs."
  type        = string
}

# ── Database ─────────────────────────────────────────────────────────────
# The server itself is not managed here. Databases are created out of band.

variable "db_host" {
  description = <<-EOT
    Host of the PostgreSQL server, as reached from the integrated subnet.

    This is the private-endpoint IP rather than a name, matching how the other
    Enerkem apps on this server address it. pgJDBC defaults to sslmode=prefer,
    so the connection is still encrypted and an IP does not break certificate
    validation the way sslmode=verify-full would.
  EOT
  type        = string
}

variable "db_name" {
  description = "Database on that server for this environment."
  type        = string
}

variable "db_user" {
  description = "Database user. Needs DDL rights: Liquibase runs the changelog on every boot."
  type        = string
}

# ── Public URL ───────────────────────────────────────────────────────────

variable "public_url" {
  description = <<-EOT
    Public base URL of this environment, no trailing slash. Used for both
    PUBLIC_API_URL and PUBLIC_FRONT_URL, which are the same host because one
    jar serves the API and the SPA.

    This value is ALSO compiled into the JavaScript bundle at image build
    time, so the image is specific to the environment named here.
  EOT
  type        = string
}

# ── Mail ─────────────────────────────────────────────────────────────────

variable "mail_recipients" {
  description = "Comma-separated addresses for system notifications. Required even when mail is off; application.yml gives it no default."
  type        = string
}

variable "mail_type" {
  description = "SMTP or SENDGRID."
  type        = string
  default     = "SMTP"
}

variable "smtp_host" {
  type    = string
  default = "smtp.office365.com"
}

variable "smtp_port" {
  type    = string
  default = "587"
}

variable "smtp_user" {
  type    = string
  default = ""
}

variable "smtp_from" {
  description = "Envelope From. Falls back to smtp_user when blank."
  type        = string
  default     = ""
}

variable "enable_email_notifications" {
  type    = bool
  default = false
}

variable "invitation_via_email" {
  description = "Requires working mail. Turning this on with broken SMTP locks new users out."
  type        = bool
  default     = false
}

# ── SSO ──────────────────────────────────────────────────────────────────

variable "enable_sso" {
  type    = bool
  default = true
}

variable "oauth2_provider" {
  type    = string
  default = "microsoft"
}

variable "oauth2_client_id" {
  description = "Application (client) id of the Entra app registration. Not a secret."
  type        = string
}

variable "oauth2_tenant_id" {
  description = "Entra directory (tenant) id. Required for a single-tenant registration, which rejects the /common authority with AADSTS50194."
  type        = string
}

# ── Misc ─────────────────────────────────────────────────────────────────

variable "spring_profile" {
  type    = string
  default = "prod"
}

variable "allowed_organization_admins" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
