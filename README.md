# Proxmox Homelab: Declarative Infrastructure as Code

A fully automated Proxmox homelab featuring dynamic VM provisioning and optional S3-compatible remote state backups.

## 🚀 Services Deployed
* **Home Assistant OS (HAOS)**
* **AdGuard Home**
* **Portainer**

---

## ⚙️ Feature Toggles
You can control which VMs are active by modifying the following booleans in your `.env` file:
- `TF_VAR_deploy_haos="true"`
- `TF_VAR_deploy_adguard="true"`
- `TF_VAR_deploy_portainer="true"`

Setting a value to `"false"` will cause OpenTofu to securely skip its creation or gracefully destroy the VM if it already exists in Proxmox.

---

## 🔱 Customizing NixOS Configurations (Bring Your Own Repo)
The NixOS VMs deployed by this project pull their final configurations directly from GitHub. You are strongly encouraged to fork this repository and point the deployment to your own code.

In your `.env` file, update the repository variable:
```bash
export TF_VAR_github_repo="github:YourUsername/homelab-proxmox-terraform"
```
By defining your own repository, you gain full control over the NixOS configurations. This allows you to safely test out new services using feature branching and deploy updates through standard code merging workflows, entirely independent of the upstream template.

---

## 💾 Optional Cloud Backup (Cloudflare R2)
This project uses the **S3-compatible backend** to support remote state backups via Cloudflare R2. 

To activate:
1. Create an R2 bucket in Cloudflare.
2. Generate an R2 API Token (Edit permissions).
3. Fill out the R2 section of your `.env`.

If R2 credentials are not detected in `.env` during `make bootstrap`, OpenTofu will default to a local `terraform.tfstate`.

---

## 📁 Project Architecture
* `main.tf`: The core orchestration logic. Generates temporary configuration files based on your `.env`.
* `Makefile`: Wraps complex setup and deployment commands into simple `make` targets.
* `vms/`: Directory containing app-specific configurations (HAOS YAML and NixOS modules).
* `.env`: *(Git-ignored)* The single source of truth for all VM IDs, network IPs, identities, and SSH keys.
* `secrets.yaml`: Encrypted SOPS file containing hashed passwords.

---

## 🚀 Quick Start (Dev Container)
This project is optimized for **VS Code Dev Containers**.
1. Ensure `TF_VAR_sops_ssh_key_path` in your `.env` points to your private SSH key.
2. Open in VS Code -> **"Reopen in Container"**.
3. The container automatically mounts your SSH key for SOPS decryption.

---

## 🛠️ Manual Prerequisites
* **OpenTofu**, **Nix**, and **SOPS** installed locally.
* A populated `.env` file containing your Proxmox credentials and SSH keys.

---

## 🔒 Secret Management
Secrets are tied to your SSH Host Key.
* **Encrypt:** `make encrypt`
* **Decrypt:** `make decrypt`

---

## 🏗️ Deployment Workflow

### 1. Bootstrap the Environment
Fetches the latest OS images, creates necessary folders, initializes the backend, and generates config artifacts.
```bash
make bootstrap
```

### 2. Verify Connection
Check if your state file is accessible (especially if using R2).
```bash
make status
```

### 3. Review & Deploy
Builds the custom NixOS ISO, provisions the hardware on Proxmox, and bootstraps the operating systems via SSH.
```bash
make plan
make apply
```

---

## 🛠️ Maintenance
- **Reconcile State:** If you make manual changes in Proxmox, run `make refresh` to sync your state file.
- **Secrets:** Use `make decrypt` to edit `secrets.yaml` and `make encrypt` before committing.