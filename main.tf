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
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-postgres-demo"
  location = "South India"
}

resource "azurerm_postgresql_server" "pg_server" {
  name                = "pg-server-demo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  administrator_login           = "citus"
  administrator_login_password  = var.pg_password

  sku_name   = "B_Gen5_1"
  version    = "11"
  storage_mb = 5120

  backup_retention_days          = 7
  geo_redundant_backup_enabled   = false
  auto_grow_enabled              = true
  public_network_access_enabled  = true
  ssl_enforcement_enabled        = true
}

resource "azurerm_postgresql_database" "pg_database" {
  name                = "exampledb"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_postgresql_server.pg_server.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

variable "pg_password" {
  description = "PostgreSQL admin password"
  type        = string
  sensitive   = true
}

output "postgres_connection_string" {
  value     = "postgresql://citus:${var.pg_password}@${azurerm_postgresql_server.pg_server.fqdn}:5432/${azurerm_postgresql_database.pg_database.name}"
  sensitive = true
}
