# One-time bootstrap: the storage account that holds OpenTofu state for every
# cmms environment. Chicken and egg - this config keeps its state locally,
# because there is nowhere remote to put it yet.
#
#   cd infra/bootstrap && tofu init && tofu apply
#
# Run once, by a human. The pipeline never touches it.

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

variable "subscription_id" {
  type    = string
  default = "d14f7b8e-d71d-4106-ab93-990c96df467c"
}

data "azurerm_resource_group" "shared" {
  name = "New-Implementations"
}

resource "azurerm_storage_account" "tfstate" {
  name                            = "enkmtfstate001"
  resource_group_name             = data.azurerm_resource_group.shared.name
  location                        = "canadaeast"
  account_tier                    = "Standard"
  account_replication_type        = "GRS"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  # State contains everything. Versioning makes a bad apply recoverable.
  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 30
    }
  }

  tags = {
    application = "cmms"
    purpose     = "opentofu-state"
    managed_by  = "opentofu"
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

output "storage_account_name" {
  value = azurerm_storage_account.tfstate.name
}
