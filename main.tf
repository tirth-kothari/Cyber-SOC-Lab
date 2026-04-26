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
    user_account {
      username = "ubuntu"
      keys     = [trimspace(file("~/.ssh/id_rsa.pub"))]
    }
  }

  

  network_device {
    bridge = "vmbr1"
    firewall = true
  }
}

resource "proxmox_virtual_environment_vm" "kali_attacker" {
  count     = var.kali_count
  name      = "kali-attacker-${count.index}"
  node_name = var.target_node
  vm_id     = 300 + count.index  # Starts at 300 to keep it separate from Ubuntu (200s)

  agent {
    enabled = true
  }

  clone {
    vm_id = var.kali_template_id
    full  = true
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_account {
      username = "kali"
      keys     = [trimspace(file("~/.ssh/id_rsa.pub"))] # Ensure this matches your path
    }
  }

  network_device {
    bridge = "vmbr1"
  }
}

# 3. THE SIEM (Wazuh Server)
resource "proxmox_virtual_environment_vm" "wazuh_server" {
  name      = "wazuh-server"
  node_name = var.target_node
  vm_id     = 400

  cpu {
    cores = 2
  }

  memory {
    dedicated = 12288 # 6GB RAM
  }

  agent { enabled = true }

  clone {
    vm_id = var.template_id # Using your Ubuntu template
    full  = true
  }

  initialization {
    ip_config {
      ipv4 { address = "dhcp" }
    }
    user_account {
      username = "ubuntu"
      keys     = [trimspace(file("~/.ssh/id_rsa.pub"))]
    }
  }

  network_device { bridge = "vmbr1" }
}

# 4. THE AI ANALYST (Ollama Node)
resource "proxmox_virtual_environment_vm" "ai_analyst" {
  name      = "ai-analyst"
  node_name = var.target_node
  vm_id     = 500

  cpu {
    cores = 4 
    type  = "host" # Allows the AI to use physical CPU features for speed
  }

  memory {
    dedicated = 16384 # 8GB RAM (Bump to 12288 if you have 32GB total on host)
  }

  agent { enabled = true }

  clone {
    vm_id = var.template_id # Using your Ubuntu template
    full  = true
  }

  initialization {
    ip_config {
      ipv4 { address = "dhcp" }
    }
    user_account {
      username = "ubuntu"
      keys     = [trimspace(file("~/.ssh/id_rsa.pub"))]
    }
  }

  network_device { bridge = "vmbr1" }
}