variable "resource_group_name" {
  description = "The name of the existing resource group to deploy the resources"
  type        = string
}

variable "location" {
  description = "Azure location. Defaults to the existing resource group's location."
  type        = string
  default     = null
}




variable "public_network_enabled" {
  description = "Whether public network access is enabled for the Data Factory"
  type        = bool
  default     = true
}

variable "managed_virtual_network_enabled" {
  description = "Whether to enable managed virtual network for the Data Factory"
  type        = bool
  default     = false
}


variable "customer_managed_key_id" {
  description = "The ID of the customer-managed key for encryption"
  type        = string
  default     = null
}

variable "customer_managed_key_identity_id" {
  description = "The ID of the user-assigned identity associated with the customer-managed key"
  type        = string
  default     = null
}

variable "purview_id" {
  description = "The ID of the Purview account to associate with the Data Factory"
  type        = string
  default     = null
}

variable "identity_type" {
  description = "The type of managed identity (None, SystemAssigned, UserAssigned, SystemAssigned, UserAssigned)"
  type        = string
  default     = "SystemAssigned"
}

variable "identity_ids" {
  description = "List of User Assigned Identity IDs (required if identity_type is UserAssigned or SystemAssigned, UserAssigned)"
  type        = list(string)
  default     = []
}

variable "github_configuration" {
  description = "GitHub configuration for the Data Factory"
  type = object({
    account_name       = string
    branch_name        = string
    git_url            = optional(string, "https://github.com")
    repository_name    = string
    root_folder        = string
    publishing_enabled = optional(bool, true)
  })
  default = null
}

variable "vsts_configuration" {
  description = "Azure DevOps (VSTS) configuration for the Data Factory"
  type = object({
    account_name       = string
    branch_name        = string
    project_name       = string
    repository_name    = string
    root_folder        = string
    tenant_id          = string
    publishing_enabled = optional(bool, true)
  })
  default = null
}

variable "global_parameters" {
  description = "List of global parameters for the Data Factory"
  type = list(object({
    name  = string
    type  = string
    value = string
  }))
  default = []
}

variable "azure_integration_runtimes" {
  description = "List of Azure integration runtimes to configure"
  type = list(object({
    name                    = string
    compute_type            = string
    core_count              = number
    time_to_live_min        = number
    cleanup_enabled         = bool
    virtual_network_enabled = bool
    rbac_authorization = optional(object({
      resource_id = string
    }), null)
  }))
  default = []
}

variable "enable_diagnostic_settings" {
  description = "Whether to enable diagnostic settings for the Data Factory"
  type        = bool
  default     = false
}

variable "diagnostic_log_categories" {
  description = "List of log categories to enable for diagnostic settings"
  type        = list(string)
  default     = ["PipelineRuns", "ActivityRuns", "TriggerRuns"]
}

variable "diagnostic_metric_categories" {
  description = "List of metric categories to enable for diagnostic settings"
  type        = list(string)
  default     = ["AllMetrics"]
}

variable "log_analytics_destination_workspace_id" {
  description = "The ID of the Log Analytics Workspace for diagnostic logs"
  type        = string
  default     = null
}

variable "log_analytics_destination_type" {
  description = "The type of destination for logs (e.g., Dedicated)"
  type        = string
  default     = "Dedicated"
}

variable "storage_account_id" {
  description = "The ID of the storage account for diagnostic settings"
  type        = string
  default     = null
}

variable "eventhub_name" {
  description = "The name of the Event Hub for diagnostic settings"
  type        = string
  default     = null
}

variable "eventhub_authorization_rule_id" {
  description = "The ID of the Event Hub authorization rule for diagnostic settings"
  type        = string
  default     = null
}

variable "managed_private_endpoints" {
  description = "List of managed private endpoints to configure"
  type = list(object({
    name               = string
    target_resource_id = string
    subresource_name   = string
  }))
  default = []
}

variable "pipelines" {
  description = "List of pipelines to configure"
  type = list(object({
    name            = string
    activities_json = string
    parameters      = optional(map(string), {})
    description     = optional(string)
    annotations     = optional(list(string), [])
    folder          = optional(string)
  }))
  default = []
}


variable "timeouts" {
  description = "Timeout configurations for the Data Factory"
  type = object({
    create = optional(string, "30m")
    update = optional(string, "30m")
    read   = optional(string, "5m")
    delete = optional(string, "30m")
  })
  default = {}
}


variable "region_code" {
  description = "Optional Azure location abbreviations. Unmapped locations use the Azure location name."
  type        = map(string)
  default     = {}
}
variable "tags" {
  description = "Optional tags. Caller values override automatic Name, CreatedBy, and Location tags."
  type        = map(string)
  default     = {}
}
variable "env" {
  description = "Environment component of the generated name."
  type        = string
  default     = "dev"
}
variable "project" {
  description = "Optional project component of the generated name."
  type        = string
  default     = ""
}

variable "enable_private_endpoint" {
  type        = bool
  default     = false
  description = "Enable private endpoint for the server"
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "The ID of the subnet for the private endpoint"
  default     = null
}

variable "private_dns_zone_name" {
  type        = string
  description = "The name of the private DNS zone to use."
  default     = "privatelink.datafactory.azure.net"
}

variable "private_dns_zone_rg" {
  type        = string
  description = "The resource group of the private DNS zone"
  default     = null
}

variable "linked_service_azure_blob_storage" {
  description = "Map of Azure Blob Storage linked services to create in the Data Factory."
  type = map(object({
    name                       = string
    additional_properties      = optional(map(string), {})
    annotations                = optional(list(string), [])
    connection_string          = optional(string)
    connection_string_insecure = optional(string)
    description                = optional(string)
    integration_runtime_name   = optional(string)
    parameters                 = optional(map(string), {})
    sas_uri                    = optional(string)
    service_endpoint           = optional(string)
    service_principal_id       = optional(string)
    service_principal_key      = optional(string)
    storage_kind               = optional(string)
    tenant_id                  = optional(string)
    use_managed_identity       = optional(bool, false)
    key_vault_sas_token = optional(object({
      linked_service_name = string
      secret_name         = string
    }))
    service_principal_linked_key_vault_key = optional(object({
      linked_service_name = string
      secret_name         = string
    }))
  }))
  default = {}
}

variable "linked_service_databricks" {
  description = "Map of Azure Databricks linked services to create in the Data Factory."
  type = map(object({
    name                       = string
    adb_domain                 = string
    access_token               = optional(string)
    additional_properties      = optional(map(string), {})
    annotations                = optional(list(string), [])
    description                = optional(string)
    existing_cluster_id        = optional(string)
    integration_runtime_name   = optional(string)
    msi_work_space_resource_id = optional(string)
    parameters                 = optional(map(string), {})
    instance_pool = optional(object({
      cluster_version       = string
      instance_pool_id      = string
      max_number_of_workers = optional(number)
      min_number_of_workers = optional(number)
    }))
    key_vault_password = optional(object({
      linked_service_name = string
      secret_name         = string
    }))
    new_cluster_config = optional(object({
      cluster_version             = string
      node_type                   = string
      custom_tags                 = optional(map(string), {})
      driver_node_type            = optional(string)
      init_scripts                = optional(list(string), [])
      log_destination             = optional(string)
      max_number_of_workers       = optional(number)
      min_number_of_workers       = optional(number)
      spark_config                = optional(map(string), {})
      spark_environment_variables = optional(map(string), {})
    }))
  }))
  default = {}
}

variable "linked_service_azure_file_storage" {
  description = "Map of Azure File Storage linked services to create in the Data Factory."
  type = map(object({
    name                     = string
    connection_string        = optional(string)
    additional_properties    = optional(map(string), {})
    annotations              = optional(list(string), [])
    description              = optional(string)
    file_share               = optional(string)
    host                     = optional(string)
    integration_runtime_name = optional(string)
    parameters               = optional(map(string), {})
    password                 = optional(string)
    user_id                  = optional(string)
    key_vault_password = optional(object({
      linked_service_name = string
      secret_name         = string
    }))
  }))
  default = {}
}

variable "linked_service_azure_sql_database" {
  description = "Map of Azure SQL Database linked services to create in the Data Factory."
  type = map(object({
    name                     = string
    additional_properties    = optional(map(string), {})
    annotations              = optional(list(string), [])
    connection_string        = optional(string)
    description              = optional(string)
    integration_runtime_name = optional(string)
    parameters               = optional(map(string), {})
    service_principal_id     = optional(string)
    service_principal_key    = optional(string)
    tenant_id                = optional(string)
    use_managed_identity     = optional(bool, false)
    key_vault_connection_string = optional(object({
      linked_service_name = string
      secret_name         = string
    }))
    key_vault_password = optional(object({
      linked_service_name = string
      secret_name         = string
    }))
  }))
  default = {}
}

variable "linked_service_data_lake_storage_gen2" {
  description = "Map of Azure Data Lake Storage Gen2 linked services to create in the Data Factory."
  type = map(object({
    name                     = string
    url                      = string
    additional_properties    = optional(map(string), {})
    annotations              = optional(list(string), [])
    description              = optional(string)
    integration_runtime_name = optional(string)
    parameters               = optional(map(string), {})
    service_principal_id     = optional(string)
    service_principal_key    = optional(string)
    storage_account_key      = optional(string)
    tenant                   = optional(string)
    use_managed_identity     = optional(bool, false)
  }))
  default = {}
}

variable "linked_service_key_vault" {
  description = "Map of Azure Key Vault linked services to create in the Data Factory."
  type = map(object({
    name                     = string
    key_vault_id             = string
    additional_properties    = optional(map(string), {})
    annotations              = optional(list(string), [])
    description              = optional(string)
    integration_runtime_name = optional(string)
    parameters               = optional(map(string), {})
  }))
  default = {}
}

variable "datafactory_name" {
  description = "Exact Data Factory name. If empty, generates project-region-env-df."
  type        = string
  default     = ""
}
