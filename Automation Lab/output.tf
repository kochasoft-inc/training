#update when webdispatcher
#output "image_id" {
#  value = "/subscriptions/4f5c9f2a-3584-4bbd-a26e-bbf69ffbfbe6/resourceGroups/RG-EASTUS-SPT-PLATFORM/providers/Microsoft.Compute/images/AZLXSPTDEVOPS01_Image"
#}
output "vmss_public_ip" {
     value = azurerm_public_ip.vmss.fqdn
}
 
output "jumpbox_public_ip" {
   value = azurerm_public_ip.jumpbox.fqdn
}