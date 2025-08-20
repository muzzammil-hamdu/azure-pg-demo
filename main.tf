terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.100"
    }
  }

  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "trm-mz"

    workspaces {
      name = "azure-pg-demo"
    }
  }
}

provider "azurerm" {
  features {}

  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-postgres-demo"
  location = "South India"
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "pg_server" {
  name                   = "pg-server-mz-demo"   # <-- globally unique name
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location

  administrator_login    = "citus"
  administrator_password = var.pg_password

  version   = "11"
  sku_name  = "B_Standard_B1ms"
  storage_mb = 32768

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  zone = "1"

  public_network_access_enabled = true
}

# PostgreSQL Database inside Flexible Server
resource "azurerm_postgresql_flexible_server_database" "pg_database" {
  name      = "exampledb"
  server_id = azurerm_postgresql_flexible_server.pg_server.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}

# Variables
variable "client_id" {
  description = "Azure client ID"
  type        = string
}

variable "client_secret" {
  description = "Azure client secret"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "pg_password" {
  description = "PostgreSQL admin password"
  type        = string
  sensitive   = true
}

# Output
output "postgres_connection_string" {
  value     = "postgresql://citus:${var.pg_password}@${azurerm_postgresql_flexible_server.pg_server.fqdn}:5432/${azurerm_postgresql_flexible_server_database.pg_database.name}"
  sensitive = true
}
