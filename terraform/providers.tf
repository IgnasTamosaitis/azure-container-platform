terraform {
  required_version = ">= 1.5.0"

  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stignastf120112287"
    container_name       = "tfstate"
    key                  = "azure-container-platform.tfstate"

    use_azuread_auth = true # local runs use `az login`; CI uses OIDC via ARM_* env vars
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.7"
    }
  }
}

provider "azurerm" {
  features {}
}
