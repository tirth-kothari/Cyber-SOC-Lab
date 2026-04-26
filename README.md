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

ssh-keygen -R [VM_IP_ADDRESS]


## Project: Automated Security Lab (Phase 2 - Attacker Deployment)
Current Status: Active
Architecture: 3x Ubuntu SOC Nodes | 3x Kali Linux Attacker Nodes

### 🚀 Deployment Overview
This phase involved extending the Terraform-managed Proxmox environment to include a dedicated "Attacker" subnet using Kali Linux. To ensure lab stability, I utilized a Manual ISO Template approach to bypass public cloud image inconsistencies.

### 🛠️ Technical Challenges & SolutionsChallengeSolution
Proxmox Repository 401 ErrorsIdentified enterprise repository conflicts. Swapped to pve-no-subscription repositories and updated GPG keys to allow host-level tool installation (p7zip).
Cloud-Init Mirror TimeoutsPivoted from .qcow2 cloud images to a manual ISO installation to create a "Known Good" golden image.
I/O Timeout during ApplyResolved "Context Deadline Exceeded" errors by implementing -parallelism=1 and increasing Terraform resource timeouts to 30 minutes.

### 🏗️ Infrastructure as Code (Terraform)
The Kali nodes are managed as a separate resource block with a unique ID offset (300+) to prevent collisions with the SOC nodes.

# Kali Attacker Logic
resource "proxmox_virtual_environment_vm" "kali_attacker" {
  count     = 3
  vm_id     = 300 + count.index
  clone {
    vm_id = 9001 # Custom ISO Golden Image
  } # Cloud-init automates SSH key injection for immediate access
}
### 🔒 Security & AccessSSH: 
Pre-configured on Port 22 within the golden image.
Identity: machine-id wiped post-install to ensure unique DHCP assignments for clones.
Authentication: Passwordless SSH-key entry managed via Terraform user_account blocks.

# 📅 Lab Update: AI Engine & SIEM Integration Phase

This phase focused on transitioning the laboratory from raw infrastructure to a functional security stack by deploying the centralized monitoring system and the AI inference engine.

## 🚀 Key Milestones
* **LLM Node Deployment:** Successfully configured a dedicated node for **Ollama**, deploying the **Llama 3.1 (8B)** model. Verified local inference for future automated security analysis.
* **SIEM Stack Installation:** Automated the deployment of the **Wazuh Manager** (including Indexer and Dashboard) via Ansible, establishing a centralized security event plane.
* **Endpoint Enrollment:** Successfully integrated the first victim node (`soc-node-0`) into the monitoring environment, establishing a functional telemetry link between the agent and the manager.

---

## 🛠️ Technical Troubleshooting & Engineering Log
*Documenting the resolution of specific system conflicts encountered during deployment.*

### 1. Resource Handling during LLM Model Pulls
* **Challenge:** High I/O and CPU utilization during the 4.9GB Llama 3.1 download caused an SSH timeout and an `UNREACHABLE!` status in Ansible.
* **Resolution:** Optimized VM performance by switching the Proxmox CPU type to **"Host"** to support specialized instructions required for LLM processing and validated service persistence manually.

### 2. Wazuh Version Parity Conflict
* **Challenge:** Agent registration was rejected by the manager with the error: `Agent version must be lower or equal to manager version`.
* **Resolution:** Identified that the default package manager was pulling a newer agent release than the established manager version. Implemented **Strict Version Pinning** within the Ansible playbook to ensure environment compatibility.

### 3. Clearing Duplicate Agent Identities
* **Challenge:** Registration attempts for the endpoint failed with the error `Duplicate agent name: soc-node-0`.
* **Resolution:** Utilized the Wazuh `manage_agents` utility on the manager to purge stale IDs and cleared the local `client.keys` on the endpoint, allowing for a clean cryptographic handshake.

### 4. Correcting Configuration "Template Drift"
* **Challenge:** The Wazuh Agent service failed to start with the error: `Invalid server address found: 'MANAGER_IP'`.
* **Resolution:** Used `wazuh-agentd -t` (Test mode) to audit the configuration syntax. Identified a failed variable substitution and manually updated the `ossec.conf` file with the static Manager IP (`10.10.10.24`).

---

## 📊 Current System Status
| Component | Status | Role |
| :--- | :--- | :--- |
| **ai-analyst** | 🟢 Active | Llama 3.1 Inference Engine |
| **wazuh-server** | 🟢 Active | SIEM Manager & Dashboard |
| **soc-node-0** | 🟢 Active | Monitored Endpoint (Agent v4.x) |