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
  location = "Central US"
}

resource "azurerm_postgresql_flexible_server" "pg_server" {
  name                   = "pg-server-mz-demo123"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  administrator_login    = "citus"
  administrator_password = var.pg_password

  version                = "16"
  sku_name               = "B_Standard_B1ms"
  storage_mb             = 32768
  backup_retention_days  = 7
  geo_redundant_backup_enabled = false
  zone                         = "1"

  public_network_access_enabled = true
}

resource "azurerm_postgresql_flexible_server_database" "pg_database" {
  name      = "exampledb"
  server_id = azurerm_postgresql_flexible_server.pg_server.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_local" {
  name             = "allow-local-ip"
  server_id        = azurerm_postgresql_flexible_server.pg_server.id
  start_ip_address = "172.167.147.204"
  end_ip_address   = "172.167.147.204"
}

variable "pg_password" {
  description = "PostgreSQL administrator password"
  type        = string
  sensitive   = true
}

output "postgres_connection_string" {
  value     = "postgresql://citus:${var.pg_password}@${azurerm_postgresql_flexible_server.pg_server.fqdn}:5432/${azurerm_postgresql_flexible_server_database.pg_database.name}"
  sens
