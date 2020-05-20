variable "tags" {
 description = "A map of the tags to use for the resources that are deployed"
 type        = map

 default = {
   environment = "lab"
 }
}


variable "application_port" {
   description = "The port that you want to expose to the external load balancer"
   default     = 80
}

variable "admin_user" {
   description = "User name to use as the admin account on the VMs that will be part of the VM Scale Set"
   default     = "kochadmin"
}

variable "admin_password" {
   default = "AzureLab2020"
}
