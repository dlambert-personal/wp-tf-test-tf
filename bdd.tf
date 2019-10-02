resource "random_id" "mysql_name" {
  byte_length = 9
}

resource "random_string" "mysql_pwd" {
  length  = 9
  special = true
}

resource "azurerm_mysql_server" "mysqlserv" {
  name                = "${random_id.mysql_name.hex}"
  location            = "${azurerm_resource_group.rgwp.location}"
  resource_group_name = "${azurerm_resource_group.rgwp.name}"

  sku {
    name     = "GP_Gen5_2"
    capacity = 2
    tier     = "GeneralPurpose"
    family   = "Gen5"
  }

  storage_profile {
    storage_mb            = 5120
    backup_retention_days = 7
    geo_redundant_backup  = "Disabled"
  }

  administrator_login          = "${random_string.mysql_login.result}"
  administrator_login_password = "${random_string.mysql_pwd.result}"
  version                      = "5.7"
  ssl_enforcement              = "disabled"
}

resource "azurerm_mysql_database" "mysqldb" {
  name                = "wpbdd"
  resource_group_name = "${azurerm_resource_group.rgwp.name}"
  server_name         = "${azurerm_mysql_server.mysqlserv.name}"
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

resource "azurerm_mysql_firewall_rule" "terraFWRULE" {
  name                = "office"
  resource_group_name = "${azurerm_resource_group.rgwp.name}"
  server_name         = "${azurerm_mysql_server.mysqlserv.name}"
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}
