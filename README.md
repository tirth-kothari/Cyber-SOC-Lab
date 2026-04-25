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

## 🛠️ Troubleshooting & Lessons Learned
During the initial deployment, several "real-world" infrastructure hurdles were encountered and resolved:

1. Proxmox Provider Authentication (VM.Monitor Error)
Issue: Using the telmate/proxmox provider with Proxmox 8.x resulted in a permission error: permissions for user/token root@pam are not sufficient... [VM.Monitor].

Cause: Proxmox 8 removed the VM.Monitor privilege, but the older provider still required it to initialize.

Resolution: Migrated to the modern bpg/proxmox provider, which is compatible with the Proxmox 8 privilege set.

2. DHCP IP Duplication (The Machine-ID Conflict)
Issue: All cloned VMs received the same IP address from the pfSense DHCP server, despite having unique MAC addresses.

Cause: Linux systems use /etc/machine-id as a unique identifier for DHCP requests. Cloned VMs retained the same ID, causing the DHCP server to treat them as the same device.

Resolution: "Generalised" the Ubuntu Golden Image before converting to a template by running:

Bash
sudo truncate -s 0 /etc/machine-id
sudo cloud-init clean --logs

3. Storage Constraints on Cloud-Init Images
Issue: apt update and qemu-guest-agent installation failed with No space left on device.

Cause: Default Ubuntu Cloud Images are distributed with minimal disk footprints (typically 2GB).

Resolution: 1. Resized the disk in the Proxmox Hardware tab.
            2. Used growpart and resize2fs inside the VM to expand the partition and filesystem to 20GB.

4. SSH Host Key Verification Failures
Issue: SSH connections were rejected with REMOTE HOST IDENTIFICATION HAS CHANGED.

Cause: Re-deploying VMs to the same IPs triggered SSH security warnings because the new host keys didn't match the old entries in known_hosts.

Resolution: Cleared stale keys on the management machine using:

PowerShell
ssh-keygen -R [VM_IP_ADDRESS]