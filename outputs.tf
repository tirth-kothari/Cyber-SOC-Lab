output "vm_ips" {
  description = "The IP addresses of the deployed VMs"
  value = {
    for vm in proxmox_virtual_environment_vm.lab_nodes :
    vm.name => vm.ipv4_addresses[1][0] # Captures the first non-loopback IP
  }
}