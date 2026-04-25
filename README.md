# Personal SOC Lab Infrastructure
Automated deployment of a cybersecurity lab using Proxmox and Terraform.

## Tech Stack
- **Hypervisor:** Proxmox VE 8.x
- **IaC:** Terraform (BPG Provider)
- **Networking:** pfSense (Internal Lab Bridge)
- **OS:** Ubuntu 22.04 (Cloud-Init)

## Features
- Scalable deployment via `vm_count` variable.
- Automated SSH key injection.
- QEMU Guest Agent integration for IP reporting.