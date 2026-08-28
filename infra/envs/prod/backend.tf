# Remote state in Azure Storage, shared between your machine and the pipeline
# and locked with a blob lease so two applies cannot race.
#
# The storage account must exist before `tofu init`. Create it once with
# infra/bootstrap - see infra/README.md.
terraform {
  backend "azurerm" {
    resource_group_name  = "New-Implementations"
    storage_account_name = "enkmtfstate001"
    container_name       = "tfstate"
    key                  = "cmms/prod.tfstate"
    use_azuread_auth     = true
  }
}
