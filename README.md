# Azure Data Factory Terraform Module

Deploy Azure Data Factory in an existing resource group, with optional integration runtimes,
pipelines, diagnostic settings, private endpoints, and linked services.

## Requirements

Terraform >= 1.3.0 and AzureRM >= 4.0, < 5.0.
Configure the AzureRM provider and credentials in the calling configuration.

## Usage

~~~hcl
provider "azurerm" {
  features {}
}

module "data_factory" {
  source = "../terraform-azurerm-data-factory"

  resource_group_name = "rg-data"
  datafactory_name    = "example-data-dev-df"
  tags = {
    Environment = "Development"
    Project     = "example"
  }
}
~~~

After the repository and tag are published, the Git source can be:

~~~hcl
source = "git::https://github.com/mocktar2021/terraform-azurerm-data-factory.git?ref=v1.0.0"
~~~

## Naming and tags

datafactory_name is used exactly as supplied. Otherwise nonempty project, region, env,
and df components are joined with hyphens and lowercased. For example, project example,
location eastus, and env dev produce example-eastus-dev-df.

Location defaults to the existing resource group's location. region_code can provide custom
naming abbreviations. Tags are optional; caller values override automatic Name, CreatedBy,
and Location tags.

## Optional features

- Private endpoints are disabled by default. To enable, supply enable_private_endpoint,
  private_endpoint_subnet_id, and private_dns_zone_rg. The existing DNS zone defaults to
  privatelink.datafactory.azure.net; override with private_dns_zone_name.
- Diagnostics are disabled by default. When enabled, supply a Log Analytics workspace,
  storage account, or Event Hub authorization rule destination.
- Configure either github_configuration or vsts_configuration for source control.
- Enable managed_virtual_network_enabled when using managed private endpoints.
- Linked service maps support Blob Storage, File Storage, SQL Database, Data Lake Storage
  Gen2, Databricks, and Key Vault.
- Existing lifecycle rules ignore many updates after creation. Review ignore_changes in
  main.tf before relying on Terraform to update deployed resources.
- The nested azure_integration_runtimes.rbac_authorization input is retained but unused.

## Inputs

Complex object schemas are defined in variables.tf.

| Name | Description | Default |
| --- | --- | --- |
| resource_group_name | The name of the existing resource group to deploy the resources | Required |
| location | Azure location. Defaults to the existing resource group's location. | null |
| public_network_enabled | Whether public network access is enabled for the Data Factory | true |
| managed_virtual_network_enabled | Whether to enable managed virtual network for the Data Factory | false |
| customer_managed_key_id | The ID of the customer-managed key for encryption | null |
| customer_managed_key_identity_id | The ID of the user-assigned identity associated with the customer-managed key | null |
| purview_id | The ID of the Purview account to associate with the Data Factory | null |
| identity_type | The type of managed identity (None, SystemAssigned, UserAssigned, SystemAssigned, UserAssigned) | "SystemAssigned" |
| identity_ids | List of User Assigned Identity IDs (required if identity_type is UserAssigned or SystemAssigned, UserAssigned) | [] |
| github_configuration | GitHub configuration for the Data Factory | null |
| vsts_configuration | Azure DevOps (VSTS) configuration for the Data Factory | null |
| global_parameters | List of global parameters for the Data Factory | [] |
| azure_integration_runtimes | List of Azure integration runtimes to configure | [] |
| enable_diagnostic_settings | Whether to enable diagnostic settings for the Data Factory | false |
| diagnostic_log_categories | List of log categories to enable for diagnostic settings | ["PipelineRuns", "ActivityRuns", "TriggerRuns"] |
| diagnostic_metric_categories | List of metric categories to enable for diagnostic settings | ["AllMetrics"] |
| log_analytics_destination_workspace_id | The ID of the Log Analytics Workspace for diagnostic logs | null |
| log_analytics_destination_type | The type of destination for logs (e.g., Dedicated) | "Dedicated" |
| storage_account_id | The ID of the storage account for diagnostic settings | null |
| eventhub_name | The name of the Event Hub for diagnostic settings | null |
| eventhub_authorization_rule_id | The ID of the Event Hub authorization rule for diagnostic settings | null |
| managed_private_endpoints | List of managed private endpoints to configure | [] |
| pipelines | List of pipelines to configure | [] |
| timeouts | Timeout configurations for the Data Factory | {} |
| region_code | Optional Azure location abbreviations. Unmapped locations use the Azure location name. | {} |
| tags | Optional tags. Caller values override automatic Name, CreatedBy, and Location tags. | {} |
| env | Environment component of the generated name. | "dev" |
| project | Optional project component of the generated name. | "" |
| enable_private_endpoint | Enable private endpoint for the server | false |
| private_endpoint_subnet_id | The ID of the subnet for the private endpoint | null |
| private_dns_zone_name | The name of the private DNS zone to use. | "privatelink.datafactory.azure.net" |
| private_dns_zone_rg | The resource group of the private DNS zone | null |
| linked_service_azure_blob_storage | Map of Azure Blob Storage linked services to create in the Data Factory. | {} |
| linked_service_databricks | Map of Azure Databricks linked services to create in the Data Factory. | {} |
| linked_service_azure_file_storage | Map of Azure File Storage linked services to create in the Data Factory. | {} |
| linked_service_azure_sql_database | Map of Azure SQL Database linked services to create in the Data Factory. | {} |
| linked_service_data_lake_storage_gen2 | Map of Azure Data Lake Storage Gen2 linked services to create in the Data Factory. | {} |
| linked_service_key_vault | Map of Azure Key Vault linked services to create in the Data Factory. | {} |
| datafactory_name | Exact Data Factory name. If empty, generates project-region-env-df. | "" |

## Outputs
| Name | Description |
| --- | --- |
| data_factory_id | The ID of the Azure Data Factory. |
| data_factory_name | The name of the Azure Data Factory. |
| resource_group_name | The name of the resource group where the Data Factory is deployed. |
| integration_runtime_ids | Map of Azure integration runtime names to their IDs. |
| identity_principal_id | The Principal ID associated with the Data Factory's managed identity, if enabled. |
| identity_tenant_id | The Tenant ID associated with the Data Factory's managed identity, if enabled. |
| pipeline_ids | Map of pipeline names to their IDs. |
| diagnostic_setting_id | The ID of the diagnostic setting for the Data Factory, if enabled. |
| managed_private_endpoint_ids | Map of managed private endpoint names to their IDs. |
| private_endpoint_id | The ID of the private endpoint for the Data Factory, if enabled. |
| private_endpoint_name | The name of the private endpoint for the Data Factory, if enabled. |
| linked_service_azure_blob_storage_ids | Map of Azure Blob Storage linked service names to their IDs. |
| linked_service_databricks_ids | Map of Azure Databricks linked service names to their IDs. |
| linked_service_azure_file_storage_ids | Map of Azure File Storage linked service names to their IDs. |
| linked_service_azure_sql_database_ids | Map of Azure SQL Database linked service names to their IDs. |
| linked_service_data_lake_storage_gen2_ids | Map of Azure Data Lake Storage Gen2 linked service names to their IDs. |
| linked_service_key_vault_ids | Map of Azure Key Vault linked service names to their IDs. |

## Development

Run terraform fmt -check, terraform init -backend=false, and terraform validate.

## Maintainer

Mocktar Tairou
