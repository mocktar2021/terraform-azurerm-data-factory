# Output for Azure Data Factory
output "data_factory_id" {
  description = "The ID of the Azure Data Factory."
  value       = azurerm_data_factory.main.id
}

output "data_factory_name" {
  description = "The name of the Azure Data Factory."
  value       = azurerm_data_factory.main.name
}

output "resource_group_name" {
  description = "The name of the resource group where the Data Factory is deployed."
  value       = var.resource_group_name
}

# Output for Azure Integration Runtimes
output "integration_runtime_ids" {
  description = "Map of Azure integration runtime names to their IDs."
  value       = { for ir in azurerm_data_factory_integration_runtime_azure.azure : ir.name => ir.id }
}

# Output for Managed Identity
output "identity_principal_id" {
  description = "The Principal ID associated with the Data Factory's managed identity, if enabled."
  value       = var.identity_type != "None" ? azurerm_data_factory.main.identity[0].principal_id : null
}

output "identity_tenant_id" {
  description = "The Tenant ID associated with the Data Factory's managed identity, if enabled."
  value       = var.identity_type != "None" ? azurerm_data_factory.main.identity[0].tenant_id : null
}

# Output for Pipelines
output "pipeline_ids" {
  description = "Map of pipeline names to their IDs."
  value       = { for p in azurerm_data_factory_pipeline.pipelines : p.name => p.id }
}

# Output for Diagnostic Settings
output "diagnostic_setting_id" {
  description = "The ID of the diagnostic setting for the Data Factory, if enabled."
  value       = var.enable_diagnostic_settings ? azurerm_monitor_diagnostic_setting.adf[0].id : null
}

# Output for Managed Private Endpoints
output "managed_private_endpoint_ids" {
  description = "Map of managed private endpoint names to their IDs."
  value       = { for ep in azurerm_data_factory_managed_private_endpoint.endpoints : ep.name => ep.id }
}

# Output for Private Endpoint
output "private_endpoint_id" {
  description = "The ID of the private endpoint for the Data Factory, if enabled."
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.pep[0].id : null
}

output "private_endpoint_name" {
  description = "The name of the private endpoint for the Data Factory, if enabled."
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.pep[0].name : null
}

# Outputs for Linked Services
output "linked_service_azure_blob_storage_ids" {
  description = "Map of Azure Blob Storage linked service names to their IDs."
  value       = { for ls in azurerm_data_factory_linked_service_azure_blob_storage.this : ls.name => ls.id }
}

output "linked_service_databricks_ids" {
  description = "Map of Azure Databricks linked service names to their IDs."
  value       = { for ls in azurerm_data_factory_linked_service_azure_databricks.this : ls.name => ls.id }
}

output "linked_service_azure_file_storage_ids" {
  description = "Map of Azure File Storage linked service names to their IDs."
  value       = { for ls in azurerm_data_factory_linked_service_azure_file_storage.this : ls.name => ls.id }
}

output "linked_service_azure_sql_database_ids" {
  description = "Map of Azure SQL Database linked service names to their IDs."
  value       = { for ls in azurerm_data_factory_linked_service_azure_sql_database.this : ls.name => ls.id }
}

output "linked_service_data_lake_storage_gen2_ids" {
  description = "Map of Azure Data Lake Storage Gen2 linked service names to their IDs."
  value       = { for ls in azurerm_data_factory_linked_service_data_lake_storage_gen2.this : ls.name => ls.id }
}

output "linked_service_key_vault_ids" {
  description = "Map of Azure Key Vault linked service names to their IDs."
  value       = { for ls in azurerm_data_factory_linked_service_key_vault.this : ls.name => ls.id }
}
