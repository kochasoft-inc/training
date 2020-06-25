provider "azurerm" {
  version = "=2.0.0"
  features {}
}

data "azurerm_resource_group" "vmss" {
 name     = "automation_lab"
}

resource "random_string" "fqdn" {
 length  = 6
 special = false
 upper   = false
 number  = false
}

resource "azurerm_virtual_network" "vmss" {
 name                = ""
 address_space       = ["10.x.0.0/16"]
 location            = "eastus"
 resource_group_name = data.azurerm_resource_group.vmss.name
 tags                = var.tags
}

resource "azurerm_subnet" "vmss" {
 name                 = "x-snet"
 resource_group_name  = data.azurerm_resource_group.vmss.name
 virtual_network_name = azurerm_virtual_network.vmss.name
 address_prefix       = "10.x.2.0/24"
}

resource "azurerm_public_ip" "vmss" {
 name                         = ""
 location                     = "eastus"
 resource_group_name          = data.azurerm_resource_group.vmss.name
 allocation_method = "Static"
 domain_name_label            = random_string.fqdn.result
 tags                         = var.tags
}

resource "azurerm_lb" "vmss" {
 name                = ""
 location            = "eastus"
 resource_group_name = data.azurerm_resource_group.vmss.name

 frontend_ip_configuration {
   name                 = ""
   public_ip_address_id = azurerm_public_ip.vmss.id
 }

 tags = var.tags
}

resource "azurerm_lb_backend_address_pool" "bpepool" {
 resource_group_name = data.azurerm_resource_group.vmss.name
 loadbalancer_id     = azurerm_lb.vmss.id
 name                = ""
}

resource "azurerm_lb_probe" "vmss" {
 resource_group_name = data.azurerm_resource_group.vmss.name
 loadbalancer_id     = azurerm_lb.vmss.id
 name                = ""
 port                = 8000
}

resource "azurerm_lb_rule" "lbnatrule" {
   resource_group_name            = data.azurerm_resource_group.vmss.name
   loadbalancer_id                = azurerm_lb.vmss.id
   name                           = ""
   protocol                       = "Tcp"
   frontend_port                  = 80
   backend_port                   = 8000
   backend_address_pool_id        = azurerm_lb_backend_address_pool.bpepool.id
   frontend_ip_configuration_name = ""
   probe_id                       = azurerm_lb_probe.vmss.id
}

resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
 name                = ""
 location            = "eastus"
 resource_group_name = data.azurerm_resource_group.vmss.name
 admin_username      = "kochadmin"
 admin_password      = "AzureLab2020"
 disable_password_authentication = "false"
 instances           = "2"
 upgrade_mode         = "Manual"
 sku                 = "Standard_DS1_v2"

 source_image_id="/subscriptions/2685fa83-2d89-40dc-b9e3-8b35cb7eda9e/resourceGroups/AZURELAB/providers/Microsoft.Compute/images/wdserver"
 os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
 network_interface {
    name    = ""
    primary = true 
  ip_configuration {
      name                                   = ""
      subnet_id                              = azurerm_subnet.vmss.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id]
      primary = true
  }
 }
 tags = var.tags
}
resource "azurerm_virtual_machine_scale_set_extension" "vmss" {
  name                         = "hostnamescript"
  virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.vmss.id
  publisher                    = "Microsoft.Azure.Extensions"
  type                         = "CustomScript"
  type_handler_version         = "2.0"
  auto_upgrade_minor_version   = true
  force_update_tag             = true
  settings = jsonencode({"fileUris" =  ["https://raw.githubusercontent.com/kochasoft-inc/training/master/Automation%20Lab/hostname.sh"], "commandToExecute" = "sh hostname.sh"}
  )
 }


resource "azurerm_public_ip" "jumpbox" {
 name                         = ""
 location                     = "eastus"
 resource_group_name          = data.azurerm_resource_group.vmss.name
 allocation_method = "Static"
 domain_name_label            = "${random_string.fqdn.result}-ssh"
 tags                         = var.tags
}

resource "azurerm_network_interface" "jumpbox" {
 name                = ""
 location            = "eastus"
 resource_group_name = data.azurerm_resource_group.vmss.name

 ip_configuration {
   name                          = ""
   subnet_id                     = azurerm_subnet.vmss.id
   private_ip_address_allocation = "dynamic"
   public_ip_address_id          = azurerm_public_ip.jumpbox.id
 }

 tags = var.tags
}

resource "azurerm_virtual_machine" "jumpbox" {
 name                  = ""
 location              = "eastus"
 resource_group_name   = data.azurerm_resource_group.vmss.name
 network_interface_ids = [azurerm_network_interface.jumpbox.id]
 vm_size               = "Standard_DS1_v2"

 storage_image_reference {
   publisher = "Canonical"
   offer     = "UbuntuServer"
   sku       = "16.04-LTS"
   version   = "latest"
 }

 storage_os_disk {
   name              = ""
   caching           = "ReadWrite"
   create_option     = "FromImage"
   managed_disk_type = "Standard_LRS"
 }

 os_profile {
   computer_name  = "jumpbox"
   admin_username = var.admin_user
   admin_password = var.admin_password
 }

 os_profile_linux_config {
   disable_password_authentication = false
 }

 tags = var.tags
}
