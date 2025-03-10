terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc6"
    }
  }
}

variable "pm_api_token_id" {
  description = "Proxmox API Token ID"
  type        = string
  sensitive   = true
}

variable "pm_api_token_secret" {
  description = "Proxmox API Token Secret"
  type        = string
  sensitive   = true
}

variable "pm_api_url" {
  description = "Proxmox API URL"
  type        = string
  sensitive   = true
}

variable "node" {
  description = "Proxmox node to deploy VMs on"
  default     = "proxmox"
}

variable "storage" {
  description = "Storage to use for VM disks"
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Network bridge to use for VMs"
  default     = "vmbr0"
}

variable "network_model" {
  description = "Network model to use for VMs"
  default     = "virtio"
}

variable "scsihw" {
  description = "SCSI HW to use for VMs"
  default     = "virtio-scsi-pci"
}

variable "template_ubuntu" {
  description = "Template ID for Ubuntu VM"
  default     = "UbuntuCloudCT"
}

variable "ssh_public_key" {
  description = "SSH public key to inject into VMs"
  type        = string
  sensitive   = true
}

variable "username" {
  description = "Local VM guest Username"
  type        = string
  sensitive   = true
}

variable "password" {
  description = "Local VM guest Password"
  type        = string
  sensitive   = true
}

variable "searchdomain" {
  description = "DNS searchdomain"
  type        = string
}

provider "proxmox" {
  pm_api_url      = var.pm_api_url
  pm_api_token_id = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure = true
}

resource "proxmox_vm_qemu" "kubernetes" {
  name = "kubernetes"
  count = 1 
  target_node = var.node
  clone = var.template_ubuntu
  full_clone  = true
  agent = 0
  os_type = "ubuntu"
  cores = 4
  sockets = 4
  memory = 8192
  scsihw = var.scsihw
  onboot = true
  automatic_reboot = true
  
  disk {
    slot      = "scsi0"
    type      = "disk"
    storage   = var.storage
    size      = 32
  }
  disk {
    slot      = "scsi1"
    type      = "cloudinit"
    storage   = var.storage
  }
  network {
    id    = 0
    model = var.network_model
    bridge = var.network_bridge
  }
  ipconfig0 = "ip=dhcp"
  searchdomain = var.searchdomain
  ciuser = var.username
  cipassword = var.password
  sshkeys = var.ssh_public_key
}
