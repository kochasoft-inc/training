provider "azurerm" {
    subscription_id = "f4b2ec99-f7d1-4142-bdb8-e9b53a1795e2"
    client_id       = "5ce2d3bd-f3d7-4b96-add6-84027bc3cc92"
    client_secret   = "L62UJ1?b0hFHexLRpn]D*YWKTPys=Y:E"
    tenant_id       = "b4e848aa-20ef-4814-a34a-93fe53f3970f"
}

locals {
}

# Resource group reference
data "azurerm_resource_group" "kochasoft" {
    name     = "${var.prefix2}${var.resource_group_suffix}"
}

# Virtual network reference
data "azurerm_virtual_network" "vnet-terraform" {
    name                = "${var.prefix}${var.vnet_name_suffix}"
    resource_group_name = "eu2devinfrastructurerg"
}

# Subnet reference
data "azurerm_subnet" "sub-terraform" {
    name                 = "${var.prefix}${var.snet_name_suffix}"
    resource_group_name  = "eu2devinfrastructurerg"
    virtual_network_name = "${data.azurerm_virtual_network.vnet-terraform.name}"
}

# Network Security Group reference
data "azurerm_network_security_group" "nsg-terraform" {
    name                = "${var.prefix}${var.network_security_group_suffix}"
    resource_group_name = "eu2devinfrastructurerg"
}

# Diagnostics storage account reference
data "azurerm_storage_account" "diagstorageaccount" {
    name                = "${var.prefix2}${var.diag_storage_acct_suffix}"
    resource_group_name = "${data.azurerm_resource_group.kochasoft.name}"
}

# Create an Availibility Set
resource "azurerm_availability_set" "avset" {
    name                         = "${var.prefix2}${var.system}as"
    location                     = "${var.location}"
    resource_group_name          = "${data.azurerm_resource_group.kochasoft.name}"
    platform_fault_domain_count  = "${var.availability_set_fault_domain_count}"
    platform_update_domain_count = "${var.availability_set_update_domain_count}"
    managed                      = "${var.availability_set_managed}"
}

# Create network interface
resource "azurerm_network_interface" "nic-terraform" {
    name                      = "${var.prefix2}${var.system}${var.systemno}${var.network_interface_suffix}"
    location                  = "${var.location}"
    resource_group_name       = "${data.azurerm_resource_group.kochasoft.name}"
    network_security_group_id = "${data.azurerm_network_security_group.nsg-terraform.id}"

    ip_configuration {
        name                          = "nic-trra-conf"
        subnet_id                     = "${data.azurerm_subnet.sub-terraform.id}"
        private_ip_address_allocation = "${var.network_interface_private_ip_add_alloc}"
    }

    tags     = "${var.tags}"
}

# Create virtual machine
resource "azurerm_virtual_machine" "vm-terraform" {
    name                  = "${var.prefix2}${var.system}${var.systemno}"
    location              = "${var.location}"
    resource_group_name   = "${data.azurerm_resource_group.kochasoft.name}"
    network_interface_ids = ["${azurerm_network_interface.nic-terraform.id}"]
    availability_set_id   = "${azurerm_availability_set.avset.id}"
    vm_size               = "${var.vm_size}"

    storage_os_disk {
        name              = "${var.prefix2}${var.system}${var.systemno}${var.os_disk_name_suffix}_dummy"
        caching           = "${var.os_disk_caching}"
        create_option     = "${var.os_disk_create_option}"
        managed_disk_type = "${var.os_disk_managed_disk_type}"
        disk_size_gb      = "${var.os_disk_size_gb}"
    }

    storage_image_reference {
        publisher = "${var.image_reference_publisher}"
        offer     = "${var.image_reference_offer}"
        sku       = "${var.image_reference_sku}"
        version   = "${var.image_reference_version}"
    }

    os_profile {
        computer_name  = "${var.prefix}${var.system}${var.systemno}"
        admin_username = "${var.admin_username}"
        admin_password = "${var.admin_user_password}"
    }

    os_profile_linux_config {
        disable_password_authentication = "${var.disable_password_authentication}"
    }

    boot_diagnostics {
        enabled     = "true"
        storage_uri = "${data.azurerm_storage_account.diagstorageaccount.primary_blob_endpoint}"
    }

    tags     = "${var.tags}"
}

resource "azurerm_managed_disk" "external1" {
  count                = "${var.number_of_disk1}"
  name                 = "${var.prefix2}${var.system}${var.systemno}disk${format("%02d",2+count.index)}_dummy"
  location             = "${var.location}"
  resource_group_name  = "${data.azurerm_resource_group.kochasoft.name}"
  storage_account_type = "${var.disk1_storage_account_type}"
  create_option        = "${var.disk1_create_option}"
  disk_size_gb         = "${var.disk1_size_gb}"
}

resource "azurerm_virtual_machine_data_disk_attachment" "external1" {
  count              = "${var.number_of_disk1}"
  managed_disk_id    = "${azurerm_managed_disk.external1.*.id[count.index]}"
  virtual_machine_id = "${azurerm_virtual_machine.vm-terraform.id}"
  lun                = "${10+count.index}"
  caching            = "${var.disk1_caching}"
}

resource "azurerm_managed_disk" "external2" {
  count                = "${var.number_of_disk2}"
  name                 = "${var.prefix2}${var.system}${var.systemno}disk${format("%02d",var.number_of_disk1+2+count.index)}_dummy"
  location             = "${var.location}"
  resource_group_name  = "${data.azurerm_resource_group.kochasoft.name}"
  storage_account_type = "${var.disk2_storage_account_type}"
  create_option        = "${var.disk2_create_option}"
  disk_size_gb         = "${var.disk2_size_gb}"
}

resource "azurerm_virtual_machine_data_disk_attachment" "external2" {
  count              = "${var.number_of_disk2}"
  managed_disk_id    = "${azurerm_managed_disk.external2.*.id[count.index]}"
  virtual_machine_id = "${azurerm_virtual_machine.vm-terraform.id}"
  lun                = "${var.number_of_disk1+10+count.index}"
  caching            = "${var.disk2_caching}"
}

resource "azurerm_managed_disk" "external3" {
  count                = "${var.number_of_disk3}"
  name                 = "${var.prefix2}${var.system}${var.systemno}disk${format("%02d",var.number_of_disk1+var.number_of_disk2+2+count.index)}_dummy"
  location             = "${var.location}"
  resource_group_name  = "${data.azurerm_resource_group.kochasoft.name}"
  storage_account_type = "${var.disk3_storage_account_type}"
  create_option        = "${var.disk3_create_option}"
  disk_size_gb         = "${var.disk3_size_gb}"
}

resource "azurerm_virtual_machine_data_disk_attachment" "external3" {
  count              = "${var.number_of_disk3}"
  managed_disk_id    = "${azurerm_managed_disk.external3.*.id[count.index]}"
  virtual_machine_id = "${azurerm_virtual_machine.vm-terraform.id}"
  lun                = "${var.number_of_disk1+var.number_of_disk2+10+count.index}"
  caching            = "${var.disk3_caching}"
}

resource "azurerm_managed_disk" "external4" {
  count                = "${var.number_of_disk4}"
  name                 = "${var.prefix2}${var.system}${var.systemno}disk${format("%02d",var.number_of_disk1+var.number_of_disk2+var.number_of_disk3+2+count.index)}_dummy"
  location             = "${var.location}"
  resource_group_name  = "${data.azurerm_resource_group.kochasoft.name}"
  storage_account_type = "${var.disk4_storage_account_type}"
  create_option        = "${var.disk4_create_option}"
  disk_size_gb         = "${var.disk4_size_gb}"
}

resource "azurerm_virtual_machine_data_disk_attachment" "external4" {
  count              = "${var.number_of_disk4}"
  managed_disk_id    = "${azurerm_managed_disk.external4.*.id[count.index]}"
  virtual_machine_id = "${azurerm_virtual_machine.vm-terraform.id}"
  lun                = "${var.number_of_disk1+var.number_of_disk2+var.number_of_disk3+10+count.index}"
  caching            = "${var.disk4_caching}"
}

resource "azurerm_managed_disk" "external5" {
  count                = "${var.number_of_disk5}"
  name                 = "${var.prefix2}${var.system}${var.systemno}disk${format("%02d",var.number_of_disk1+var.number_of_disk2+var.number_of_disk3+var.number_of_disk4+2+count.index)}_dummy"
  location             = "${var.location}"
  resource_group_name  = "${data.azurerm_resource_group.kochasoft.name}"
  storage_account_type = "${var.disk5_storage_account_type}"
  create_option        = "${var.disk5_create_option}"
  disk_size_gb         = "${var.disk5_size_gb}"
}

resource "azurerm_virtual_machine_data_disk_attachment" "external5" {
  count              = "${var.number_of_disk5}"
  managed_disk_id    = "${azurerm_managed_disk.external5.*.id[count.index]}"
  virtual_machine_id = "${azurerm_virtual_machine.vm-terraform.id}"
  lun                = "${var.number_of_disk1+var.number_of_disk2+var.number_of_disk3+var.number_of_disk4+10+count.index}"
  caching            = "${var.disk5_caching}"
}

