# ==========================================
# Proxmox Connection Details
# ==========================================
variable "proxmox_endpoint" {
  description = "The API URL for your Proxmox server (e.g., https://192.168.1.100:8006/)"
  type        = string
}

variable "proxmox_username" {
  description = "The Proxmox user (e.g., root@pam)"
  type        = string
}

variable "proxmox_password" {
  description = "The Proxmox user password"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "The target Proxmox node name"
  type        = string
  default     = "pve"
}

# ==========================================
# Deployment Toggles
# ==========================================
variable "deploy_haos" {
  description = "Toggle to deploy Home Assistant OS"
  type        = bool
  default     = true
}

variable "deploy_adguard" {
  description = "Toggle to deploy AdGuard Home"
  type        = bool
  default     = true
}

variable "deploy_portainer" {
  description = "Toggle to deploy Portainer"
  type        = bool
  default     = true
}

# ==========================================
# Virtual Machine Configurations
# ==========================================
variable "haos_vm_id" {
  description = "Proxmox VM ID for Home Assistant"
  type        = number
}

variable "haos_ip" {
  description = "Static IP Address for Home Assistant"
  type        = string
}

variable "adguard_vm_id" {
  description = "Proxmox VM ID for AdGuard"
  type        = number
}

variable "adguard_ip" {
  description = "Static IP Address for AdGuard"
  type        = string
}

variable "portainer_vm_id" {
  description = "Proxmox VM ID for Portainer"
  type        = number
}

variable "portainer_ip" {
  description = "Static IP Address for Portainer"
  type        = string
}

# ==========================================
# Global Network & Identity
# ==========================================
variable "network_gateway" {
  description = "The default gateway IP for the VMs"
  type        = string
}

variable "github_repo" {
  description = "The NixOS configuration repository (e.g., github:username/repo)"
  type        = string
}

variable "ssh_public_key" {
  description = "The public SSH key(s) injected into the VMs for access"
  type        = list(string) # Changed from string to list(string)
}

variable "provisioner_private_key" {
  description = "Path to the private key used by OpenTofu to run remote execution"
  type        = string
}

variable "sops_ssh_key_path" {
  description = "Path to the private key used by SOPS for decryption"
  type        = string
}

# ==========================================
# Optional Remote State Backends
# ==========================================
# These are used by the Makefile to configure the backend dynamically,
# but declaring them here prevents OpenTofu from throwing warnings.

variable "r2_account_id" {
  description = "Cloudflare R2 Account ID"
  type        = string
  default     = ""
}

variable "r2_bucket" {
  description = "Cloudflare R2 Bucket Name"
  type        = string
  default     = ""
}

variable "s3_bucket" {
  description = "Amazon S3 Bucket Name"
  type        = string
  default     = ""
}

variable "s3_region" {
  description = "Amazon S3 Region"
  type        = string
  default     = ""
}