locals {
  resource_group_name = var.resource_group_name
  location            = var.location != null ? var.location : data.azurerm_resource_group.existing.location
  region              = lookup(var.region_code, local.location, local.location)
  base_name           = lower(join("-", compact([var.project, local.region, var.env, "df"])))
  data_factory_name   = var.datafactory_name != "" ? var.datafactory_name : local.base_name
}

data "azurerm_resource_group" "existing" {
  name = var.resource_group_name
}

data "azurerm_private_dns_zone" "dnszone" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = var.private_dns_zone_name
  resource_group_name = var.private_dns_zone_rg
}

# Azure Data Factory
resource "azurerm_data_factory" "main" {
  name                             = local.data_factory_name
  resource_group_name              = local.resource_group_name
  location                         = local.location
  public_network_enabled           = var.public_network_enabled
  managed_virtual_network_enabled  = var.managed_virtual_network_enabled
  customer_managed_key_id          = var.customer_managed_key_id
  customer_managed_key_identity_id = var.customer_managed_key_identity_id
  purview_id                       = var.purview_id

  # Managed Identity
  dynamic "identity" {
    for_each = var.identity_type != "None" ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.identity_ids : null
    }
  }

  # GitHub Configuration
  dynamic "github_configuration" {
    for_each = var.github_configuration != null ? [var.github_configuration] : []
    content {
      account_name       = github_configuration.value.account_name
      branch_name        = github_configuration.value.branch_name
      git_url            = github_configuration.value.git_url
      repository_name    = github_configuration.value.repository_name
      root_folder        = github_configuration.value.root_folder
      publishing_enabled = github_configuration.value.publishing_enabled
    }
  }

  # Azure DevOps (VSTS) Configuration
  dynamic "vsts_configuration" {
    for_each = var.vsts_configuration != null ? [var.vsts_configuration] : []
    content {
      account_name       = vsts_configuration.value.account_name
      branch_name        = vsts_configuration.value.branch_name
      project_name       = vsts_configuration.value.project_name
      repository_name    = vsts_configuration.value.repository_name
      root_folder        = vsts_configuration.value.root_folder
      tenant_id          = vsts_configuration.value.tenant_id
      publishing_enabled = vsts_configuration.value.publishing_enabled
    }
  }

  # Global Parameters
  dynamic "global_parameter" {
    for_each = var.global_parameters
    content {
      name  = global_parameter.value.name
      type  = global_parameter.value.type
      value = global_parameter.value.value
    }
  }

  tags = merge(
    {
      "Name"      = "${local.data_factory_name}"
      "CreatedBy" = "Terraform"
      "Location"  = "${local.region}"
    },
    var.tags,
  )

  lifecycle {
    ignore_changes = [tags, public_network_enabled, managed_virtual_network_enabled, customer_managed_key_id,
    customer_managed_key_identity_id, identity, github_configuration, vsts_configuration, global_parameter]
  }

  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    read   = var.timeouts.read
    delete = var.timeouts.delete
  }
}

# Azure Integration Runtime
resource "azurerm_data_factory_integration_runtime_azure" "azure" {
  for_each = { for ir in var.azure_integration_runtimes : ir.name => ir }

  name                    = each.value.name
  data_factory_id         = azurerm_data_factory.main.id
  location                = local.location
  compute_type            = each.value.compute_type
  core_count              = each.value.core_count
  time_to_live_min        = each.value.time_to_live_min
  cleanup_enabled         = each.value.cleanup_enabled
  virtual_network_enabled = each.value.virtual_network_enabled


  lifecycle {
    ignore_changes = all
  }

}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "adf" {
  count = var.enable_diagnostic_settings ? 1 : 0

  name                           = "${local.data_factory_name}-diagnostics"
  target_resource_id             = azurerm_data_factory.main.id
  log_analytics_workspace_id     = var.log_analytics_destination_workspace_id
  storage_account_id             = var.storage_account_id
  eventhub_name                  = var.eventhub_name
  eventhub_authorization_rule_id = var.eventhub_authorization_rule_id

  dynamic "enabled_log" {
    for_each = var.diagnostic_log_categories
    content {
      category = enabled_log.value
    }
  }

  dynamic "enabled_metric" {
    for_each = var.diagnostic_metric_categories
    content {
      category = enabled_metric.value
    }
  }

  lifecycle {
    ignore_changes = all
  }

  log_analytics_destination_type = var.log_analytics_destination_type
}

# Managed Private Endpoints
resource "azurerm_data_factory_managed_private_endpoint" "endpoints" {
  for_each = { for ep in var.managed_private_endpoints : ep.name => ep }

  name               = each.value.name
  data_factory_id    = azurerm_data_factory.main.id
  target_resource_id = each.value.target_resource_id
  subresource_name   = each.value.subresource_name

  lifecycle {
    ignore_changes = all
  }

}

# Example Pipeline (Optional)
resource "azurerm_data_factory_pipeline" "pipelines" {
  for_each = { for p in var.pipelines : p.name => p }

  name            = each.value.name
  data_factory_id = azurerm_data_factory.main.id
  activities_json = each.value.activities_json
  parameters      = each.value.parameters
  description     = each.value.description
  annotations     = each.value.annotations
  folder          = each.value.folder

  lifecycle {
    ignore_changes = all
  }

}

# Private Endpoint
resource "azurerm_private_endpoint" "pep" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${local.data_factory_name}-PE"
  location            = local.location
  resource_group_name = local.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${local.data_factory_name}-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_data_factory.main.id
    subresource_names              = ["dataFactory"]
  }

  private_dns_zone_group {
    name                 = "${local.data_factory_name}-dns"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.dnszone[0].id]
  }

  depends_on = [
    azurerm_data_factory.main,
    data.azurerm_private_dns_zone.dnszone
  ]

  tags = merge(
    {
      "Name"      = "${local.data_factory_name}-PE"
      "CreatedBy" = "Terraform"
      "Location"  = "${local.region}"
    },
    var.tags,
  )

  lifecycle {
    ignore_changes = all
  }
}



# Azure Blob Storage Linked Service
resource "azurerm_data_factory_linked_service_azure_blob_storage" "this" {
  for_each = var.linked_service_azure_blob_storage

  data_factory_id            = azurerm_data_factory.main.id
  name                       = each.value.name
  additional_properties      = each.value.additional_properties
  annotations                = each.value.annotations
  connection_string          = each.value.connection_string
  connection_string_insecure = each.value.connection_string_insecure
  description                = each.value.description
  integration_runtime_name   = each.value.integration_runtime_name
  parameters                 = each.value.parameters
  sas_uri                    = each.value.sas_uri
  service_endpoint           = each.value.service_endpoint
  service_principal_id       = each.value.service_principal_id
  service_principal_key      = each.value.service_principal_key
  storage_kind               = each.value.storage_kind
  tenant_id                  = each.value.tenant_id
  use_managed_identity       = each.value.use_managed_identity

  dynamic "key_vault_sas_token" {
    for_each = each.value.key_vault_sas_token != null ? [each.value.key_vault_sas_token] : []

    content {
      linked_service_name = key_vault_sas_token.value.linked_service_name
      secret_name         = key_vault_sas_token.value.secret_name
    }
  }
  dynamic "service_principal_linked_key_vault_key" {
    for_each = each.value.service_principal_linked_key_vault_key != null ? [each.value.service_principal_linked_key_vault_key] : []

    content {
      linked_service_name = service_principal_linked_key_vault_key.value.linked_service_name
      secret_name         = service_principal_linked_key_vault_key.value.secret_name
    }
  }

  lifecycle {
    ignore_changes = all
  }
}

# Azure Databricks Linked Service
resource "azurerm_data_factory_linked_service_azure_databricks" "this" {
  for_each = var.linked_service_databricks

  adb_domain                 = each.value.adb_domain
  data_factory_id            = azurerm_data_factory.main.id
  name                       = each.value.name
  access_token               = each.value.access_token
  additional_properties      = each.value.additional_properties
  annotations                = each.value.annotations
  description                = each.value.description
  existing_cluster_id        = each.value.existing_cluster_id
  integration_runtime_name   = each.value.integration_runtime_name
  msi_work_space_resource_id = each.value.msi_work_space_resource_id
  parameters                 = each.value.parameters

  dynamic "instance_pool" {
    for_each = each.value.instance_pool != null ? [each.value.instance_pool] : []

    content {
      cluster_version       = instance_pool.value.cluster_version
      instance_pool_id      = instance_pool.value.instance_pool_id
      max_number_of_workers = instance_pool.value.max_number_of_workers
      min_number_of_workers = instance_pool.value.min_number_of_workers
    }
  }
  dynamic "key_vault_password" {
    for_each = each.value.key_vault_password != null ? [each.value.key_vault_password] : []

    content {
      linked_service_name = key_vault_password.value.linked_service_name
      secret_name         = key_vault_password.value.secret_name
    }
  }
  dynamic "new_cluster_config" {
    for_each = each.value.new_cluster_config != null ? [each.value.new_cluster_config] : []

    content {
      cluster_version             = new_cluster_config.value.cluster_version
      node_type                   = new_cluster_config.value.node_type
      custom_tags                 = new_cluster_config.value.custom_tags
      driver_node_type            = new_cluster_config.value.driver_node_type
      init_scripts                = new_cluster_config.value.init_scripts
      log_destination             = new_cluster_config.value.log_destination
      max_number_of_workers       = new_cluster_config.value.max_number_of_workers
      min_number_of_workers       = new_cluster_config.value.min_number_of_workers
      spark_config                = new_cluster_config.value.spark_config
      spark_environment_variables = new_cluster_config.value.spark_environment_variables
    }
  }

  lifecycle {
    ignore_changes = all
  }
}

# Azure File Storage Linked Service
resource "azurerm_data_factory_linked_service_azure_file_storage" "this" {
  for_each = var.linked_service_azure_file_storage

  connection_string        = each.value.connection_string
  data_factory_id          = azurerm_data_factory.main.id
  name                     = each.value.name
  additional_properties    = each.value.additional_properties
  annotations              = each.value.annotations
  description              = each.value.description
  file_share               = each.value.file_share
  host                     = each.value.host
  integration_runtime_name = each.value.integration_runtime_name
  parameters               = each.value.parameters
  password                 = each.value.password
  user_id                  = each.value.user_id

  dynamic "key_vault_password" {
    for_each = each.value.key_vault_password != null ? [each.value.key_vault_password] : []

    content {
      linked_service_name = key_vault_password.value.linked_service_name
      secret_name         = key_vault_password.value.secret_name
    }
  }

  lifecycle {
    ignore_changes = all
  }
}

# Azure SQL Database Linked Service
resource "azurerm_data_factory_linked_service_azure_sql_database" "this" {
  for_each = var.linked_service_azure_sql_database

  data_factory_id          = azurerm_data_factory.main.id
  name                     = each.value.name
  additional_properties    = each.value.additional_properties
  annotations              = each.value.annotations
  connection_string        = each.value.connection_string
  description              = each.value.description
  integration_runtime_name = each.value.integration_runtime_name
  parameters               = each.value.parameters
  service_principal_id     = each.value.service_principal_id
  service_principal_key    = each.value.service_principal_key
  tenant_id                = each.value.tenant_id
  use_managed_identity     = each.value.use_managed_identity

  dynamic "key_vault_connection_string" {
    for_each = each.value.key_vault_connection_string != null ? [each.value.key_vault_connection_string] : []

    content {
      linked_service_name = key_vault_connection_string.value.linked_service_name
      secret_name         = key_vault_connection_string.value.secret_name
    }
  }
  dynamic "key_vault_password" {
    for_each = each.value.key_vault_password != null ? [each.value.key_vault_password] : []

    content {
      linked_service_name = key_vault_password.value.linked_service_name
      secret_name         = key_vault_password.value.secret_name
    }
  }

  lifecycle {
    ignore_changes = all
  }
}

# Azure Data Lake Storage Gen2 Linked Service
resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "this" {
  for_each = var.linked_service_data_lake_storage_gen2

  data_factory_id          = azurerm_data_factory.main.id
  name                     = each.value.name
  url                      = each.value.url
  additional_properties    = each.value.additional_properties
  annotations              = each.value.annotations
  description              = each.value.description
  integration_runtime_name = each.value.integration_runtime_name
  parameters               = each.value.parameters
  service_principal_id     = each.value.service_principal_id
  service_principal_key    = each.value.service_principal_key
  storage_account_key      = each.value.storage_account_key
  tenant                   = each.value.tenant
  use_managed_identity     = each.value.use_managed_identity

  lifecycle {
    ignore_changes = all
  }
}

# Azure Key Vault Linked Service
resource "azurerm_data_factory_linked_service_key_vault" "this" {
  for_each = var.linked_service_key_vault

  data_factory_id          = azurerm_data_factory.main.id
  key_vault_id             = each.value.key_vault_id
  name                     = each.value.name
  additional_properties    = each.value.additional_properties
  annotations              = each.value.annotations
  description              = each.value.description
  integration_runtime_name = each.value.integration_runtime_name
  parameters               = each.value.parameters

  lifecycle {
    ignore_changes = all
  }
}
