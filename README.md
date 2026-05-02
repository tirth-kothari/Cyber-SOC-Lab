# 🛡️ Personal SOC Lab Infrastructure
**Automated deployment of a cybersecurity lab using Proxmox and Terraform.**

## 🏗️ Architecture & Tech Stack
This environment simulates an enterprise Security Operations Center (SOC) using a segmented network for attack and defense simulation.

*   **Hypervisor:** Proxmox VE 8.x
*   **IaC:** Terraform (bpg/proxmox provider)
*   **Config Management:** Ansible
*   **SIEM:** Wazuh (Indexer, Dashboard, Manager)
*   **AI Engine:** Ollama (Llama 3.1 8B)
*   **OS:** Ubuntu 22.04 (Cloud-Init) & Kali Linux
*   **Networking:** pfSense (Internal Lab Bridge)

---

## 🛠️ Troubleshooting & Lessons Learned
During the deployment, several real-world infrastructure hurdles were encountered and resolved:

### 1. Proxmox Provider Authentication (VM.Monitor Error)
*   **Issue:** Using the `telmate/proxmox` provider with Proxmox 8.x resulted in permission errors because the `VM.Monitor` privilege was removed in version 8.
*   **Resolution:** Migrated to the modern **`bpg/proxmox`** provider, which is compatible with the Proxmox 8 privilege set.

### 2. DHCP IP Duplication (The Machine-ID Conflict)
*   **Issue:** All cloned VMs received the same IP address from the pfSense DHCP server.
*   **Cause:** Linux systems use `/etc/machine-id` as a unique identifier. Cloned VMs retained the same ID, causing DHCP conflicts.
*   **Resolution:** "Generalized" the Ubuntu Golden Image before converting to a template by running:
    ```bash
    sudo truncate -s 0 /etc/machine-id
    sudo cloud-init clean --logs
    ```

### 3. Storage Constraints & I/O Timeouts
*   **Issue:** `apt update` failed with "No space left on device" due to minimal 2GB cloud-init image footprints.
*   **Resolution:** Resized the disk in the Proxmox Hardware tab and used `growpart` and `resize2fs` inside the VM to expand to 20GB.
*   **Issue:** Terraform "Context Deadline Exceeded" errors during deployment.
*   **Resolution:** Implemented `-parallelism=1` and increased resource timeouts to 30 minutes.

### 4. SIEM & AI Node Integration
*   **Issue:** Resource exhaustion during 4.9GB Llama 3.1 model pulls.
*   **Resolution:** Optimized VM performance by switching the Proxmox CPU type to **"Host"** to support specialized instructions required for LLM processing.
*   **Issue:** Wazuh Agent version mismatch errors.
*   **Resolution:** Implemented **Strict Version Pinning** in Ansible playbooks to ensure the Agent version is lower than or equal to the Manager version.
*   **Issue:** Agent service failed to start due to "Invalid server address found: 'MANAGER_IP'".
*   **Resolution:** Used `wazuh-agentd -t` to identify failed variable substitutions and manually updated `ossec.conf` with the static Manager IP (10.10.10.24).

---

## 🚀 How To Use This Repo

### 1. Prerequisites
*   Proxmox VE 8.x host.
*   Terraform and Ansible installed on your management machine.
*   A pre-configured Ubuntu 22.04 Cloud-Init template.

### 2. Deployment
1.  **Terraform:** Initialize and apply the infrastructure.
    ```bash
    terraform init
    terraform apply
    ```
2.  **Ansible:** Configure the SOC stack.
    ```bash
    ansible-playbook -i inventory.ini setup_soc_lab.yml
    ```

### 3. Verification
*   Log into the **Wazuh Dashboard** (Port 443).
*   Verify `soc-node-0` appears as **Active**.
*   Test the AI node by running `ollama run llama3.1` on the `ai-analyst` VM.

---

## 📊 Current System Status
| Component | Status | Role |
| :--- | :--- | :--- |
| **ai-analyst** | 🟢 Active | Llama 3.1 Inference Engine |
| **wazuh-server** | 🟢 Active | SIEM Manager & Dashboard |
| **soc-node-0** | 🟢 Active | Monitored Endpoint (Agent v4.x) |
