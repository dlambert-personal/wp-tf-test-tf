output "main_endpoint" {
 value = "${lookup(azurerm_template_deployment.website.outputs,"fqdn")}"
}
