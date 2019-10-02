variable "ARM_CLIENT_ID" { type=string }
variable "ARM_CLIENT_SECRET" { type=string }
variable "ARM_SUBSCRIPTION_ID" { type=string }
variable "ARM_TENANT_ID" { type=string }
variable "ARM_REGION" { type=string }
variable "GIT_REPO" { type=string }



resource "random_id" "randwp" {
  byte_length = 9
}

resource "random_id" "randarm" {
  byte_length = 9
}

resource "random_string" "mysql_login" {
  length  = 8
  special = false
  number  = true
  upper   = true
  lower   = true
}

resource "azurerm_resource_group" "rgwp" {
  name     = "${random_id.randwp.hex}"
  location = "${var.ARM_REGION}"
  tags = { "cost center"="personal"}
}

resource "azurerm_template_deployment" "website" {
  name                = "${random_id.randwp.hex}"
  resource_group_name = "${azurerm_resource_group.rgwp.name}"
  depends_on          = ["azurerm_mysql_database.mysqldb"]

  template_body = <<DEPLOY
{
   "$schema":"http://schema.management.azure.com/schemas/2014-04-01-preview/deploymentTemplate.json#",
   "contentVersion":"1.0.0.0",
   "parameters":{
      "siteName":{
         "type":"string",
         "defaultValue":"${random_id.randarm.hex}"
      },
      "dbhost":{
        "type":"string",
        "defaultValue":"${azurerm_mysql_server.mysqlserv.name}"
      },
      "dbuser":{
        "type":"string",
        "defaultValue":"${random_string.mysql_login.result}"
      },
      "hostingPlanName":{
         "type":"string",
         "defaultValue":"hpname"
      },
      "sku":{  
         "type":"string",
         "allowedValues":[  
            "Free",
            "Shared",
            "Basic",
            "Standard",
            "Premium"
         ],
         "defaultValue":"Standard"
      },
      "workerSize":{  
         "type":"string",
         "allowedValues":[  
            "0",
            "1",
            "2"
         ],
         "defaultValue":"1"
      },
      "dbServer":{  
         "type":"string",
         "defaultValue":"${azurerm_mysql_server.mysqlserv.name}.mysql.database.azure.com:3306"
      },
      "dbName":{  
         "type":"string",
         "defaultValue":"wpbdd"
      },
      "dbAdminPassword":{  
         "type":"string",
         "defaultValue":"${random_string.mysql_pwd.result}"
      }
   },
   "variables":{  
      "connectionString":"[concat('Database=', parameters('dbName'), ';Data Source=', parameters('dbServer'), ';User Id=',parameters('dbuser'),'@',parameters('dbhost'),';Password=', parameters('dbAdminPassword'))]",
      "repoUrl":"https://github.com/dlambert-personal/wordpress-terraform.git/wordpress/",
      "account_name":"dlambert@appdev.info:dGewfdPZd68y",
      "branch":"master",
      "workerSize":"[parameters('workerSize')]",
      "sku":"[parameters('sku')]",
      "hostingPlanName":"[parameters('hostingPlanName')]"
   },
   "resources":[  
      {  
         "apiVersion":"2014-06-01",
         "name":"[variables('hostingPlanName')]",
         "type":"Microsoft.Web/serverfarms",
         "location":"[resourceGroup().location]",
         "properties":{  
            "name":"[variables('hostingPlanName')]",
            "sku":"[variables('sku')]",
            "workerSize":"[variables('workerSize')]",
            "hostingEnvironment":"",
            "numberOfWorkers":0
         }
      },
      {  
         "apiVersion":"2015-02-01",
         "name":"[parameters('siteName')]",
         "type":"Microsoft.Web/sites",
         "location":"[resourceGroup().location]",
         "tags":{  
            "[concat('hidden-related:', '/subscriptions/', subscription().subscriptionId,'/resourcegroups/', resourceGroup().name, '/providers/Microsoft.Web/serverfarms/', variables('hostingPlanName'))]":"empty"
         },
         "dependsOn":[  
            "[concat('Microsoft.Web/serverfarms/', variables('hostingPlanName'))]"
         ],
         "properties":{  
            "name":"[parameters('siteName')]",
            "serverFarmId":"[concat('/subscriptions/', subscription().subscriptionId,'/resourcegroups/', resourceGroup().name, '/providers/Microsoft.Web/serverfarms/', variables('hostingPlanName'))]",
            "hostingEnvironment":""
         },
         "resources":[  
            {  
               "apiVersion":"2015-04-01",
               "name":"connectionstrings",
               "type":"config",
               "dependsOn":[  
                  "[concat('Microsoft.Web/Sites/', parameters('siteName'))]"
               ],
               "properties":{  
                  "defaultConnection":{  
                     "value":"[variables('connectionString')]",
                     "type":"MySQL"
                  }
               }
            },
            {
               "apiVersion":"2015-04-01",
               "name":"web",
               "type":"config",
               "dependsOn":[  
                  "[concat('Microsoft.Web/Sites/', parameters('siteName'))]"
               ],
               "properties":{  
                  "phpVersion":"5.6"
               }
            },
            {  
               "apiVersion":"2015-08-01",
               "name":"web",
               "type":"sourcecontrols",
               "dependsOn":[  
                  "[resourceId('Microsoft.Web/Sites', parameters('siteName'))]",
                  "[concat('Microsoft.Web/Sites/', parameters('siteName'), '/config/connectionstrings')]",
                  "[concat('Microsoft.Web/Sites/', parameters('siteName'), '/config/web')]"
               ],
               "properties":{  
                  "RepoUrl":"[variables('repoUrl')]",
                  "branch":"[variables('branch')]",
                  "account_name":"[variables('account_name')]",
                  "IsManualIntegration":true
               }
            }
         ]
      }      
   ],
     "outputs":{
    "fqdn":{
      "type":"string",
      "value" : "[concat('https://', parameters('siteName'), '.azurewebsites.net')]"
    }
  }

}
 DEPLOY

  deployment_mode = "Incremental"
}
