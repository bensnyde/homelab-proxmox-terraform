# Proxmox Homelab: Declarative Infrastructure as Code

A fully automated Proxmox homelab featuring dynamic VM provisioning and optional S3-compatible remote state backups via Cloudflare R2.

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

## 🛠️ Prerequisites
* **OpenTofu** and **Nix** installed locally.
* **SOPS** installed locally (`sudo dnf install sops age` for Fedora).
* A populated `.env` file containing your Proxmox credentials and SSH keys.

---

## 🔒 Secret Management
Secrets are locked via `age` encryption. The `.sops.yaml` rules are dynamically generated based on the SSH public key provided in your `.env`.

To encrypt your plaintext `secrets.yaml` for the first time:
```bash
make encrypt
```

To safely edit existing secrets:
```bash
make decrypt
# Edit the file in your text editor
make encrypt
```

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