/************************************************************************************************************************************************

  Azure Synapse Analytics Proof of Concept Architecture: Terraform Template

    Create a Synapse Analytics environment based on best practices to achieve a successful proof of concept. While settings can be adjusted, 
    the major deployment differences are based on whether or not you used Private Endpoints for connectivity. If you do not already use 
    Private Endpoints for other Azure deployments, it's discouraged to use them for a proof of concept as they have many other networking 
    depandancies than what can be configured here.

    Resources:

      Synapse Analytics Workspace:
          - DW1000 Dedicated SQL Pool
          - Pipelines to automatically pause and resume the Dedicated SQL Pool on a schedule
          - Parquet Auto Ingestion pipeline to help ease and optimize data ingestion using best practices

      Azure Data Lake Storage Gen2:
          - Storage for the Synapse Analytics Workspace configuration data
          - Storage for the data that's going to be queried on-demand or ingested

      Log Analytics:
          - Logging for Synapse Analytics
          - Logging for Azure Data Lake Storage Gen2

************************************************************************************************************************************************/

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.79.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.5.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {
  use_msi = false
}

data "azurerm_client_config" "current" {}

// Add a random suffix to ensure global uniqueness among the resources created
//   Terraform: https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string
resource "random_string" "suffix" {
  length  = 3
  upper   = false
  special = false
}

/************************************************************************************************************************************************

  Outputs

        We output certain variables that need to be referenced by the configure.sh bash script.

************************************************************************************************************************************************/

output "synapse_sql_pool_name" {
  value = var.synapse_sql_pool_name
}

output "synapse_sql_administrator_login" {
  value = var.synapse_sql_administrator_login
}

output "synapse_sql_administrator_login_password" {
  value = var.synapse_sql_administrator_login_password
}

output "synapse_analytics_workspace_name" {
  value = "pocsynapseanalytics-tpcds"
}

output "synapse_analytics_workspace_resource_group" {
  value = var.resource_group_name
}

output "datalake_name" {
  value = "tpcdsacctpoc"
}


output "private_endpoints_enabled" {
  value = var.enable_private_endpoints
}


output "object_id" {
  description = "The object id of service principal. Can be used to assign roles to user."
  value       = azuread_service_principal.sp.object_id
}

output "client_id" {
  description = "The application id of AzureAD application created."
  value       = azuread_application.sp.application_id
}

output "client_secret" {
  description = "Password for service principal."
  value       = azuread_service_principal_password.sp.value
  sensitive   = true
}


/************************************************************************************************************************************************
  Service Principal
************************************************************************************************************************************************/

resource "azuread_application" "sp" {
  display_name               = var.app_spn_name
  identifier_uris            = ["http://${var.app_spn_name}"]

}

resource "azuread_service_principal" "sp" {
  application_id = azuread_application.sp.application_id

}

resource "random_string" "unique" {
  length  = 32
  special = false
  upper   = true

  keepers = {
    service_principal = azuread_service_principal.sp.id
  }
}

resource "azuread_service_principal_password" "sp" {
  service_principal_id = azuread_service_principal.sp.id
  value                = random_string.unique.result
  end_date             = var.end_date
}



