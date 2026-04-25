terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.66.1" # The modern, active provider
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = var.proxmox_api_token
  insecure  = true
}


resource "proxmox_virtual_environment_vm" "lab_nodes" {
  # This is the 'n' variable
  count     = var.vm_count 
  
  # Names will be: soc-node-0, soc-node-1, etc.
  name      = "soc-node-${count.index}" 
  node_name = var.target_node
  
  # IDs will start at 200 and go up (200, 201...) to avoid conflicts
  vm_id     = 200 + count.index 

  # THIS ENABLES THE GUEST AGENT
  agent {
    enabled = true
  }

  clone {
    vm_id = var.template_id # Your Ubuntu template ID
    full = true
  }

  initialization {
    type = "nocloud"
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  network_device {
    bridge = "vmbr1"
    firewall = true
  }
}

