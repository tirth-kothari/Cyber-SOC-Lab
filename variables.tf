variable "proxmox_api_url" {
  type    = string
  default = "https://192.168.1.20:8006/" #your PVE IP here
}

variable "proxmox_api_token" {
  type      = string
  sensitive = true
}

variable "vm_count" {
  description = "Number of VMs to deploy"
  type        = number
  default     = 1 # Change this to n
}

variable "target_node" {
  type    = string
  default = "pve-goku"
}

variable "template_id" {
  type    = number
  default = 101
}