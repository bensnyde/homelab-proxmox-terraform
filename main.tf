terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc6"
    }
  }
}

provider "proxmox" {
  pm_api_url      = "https://<proxmox_host>:8006/api2/json"
  pm_api_token_id = "<api_token_id>"
  pm_api_token_secret = "<api_token_secret>"
  pm_tls_insecure = true
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
  description = "Local Username"
  type        = string
  sensitive   = true
}

variable "password" {
  description = "Local Password"
  type        = string
  sensitive   = true
}

variable "searchdomain" {
  description = "DNS searchdomain"
  type        = string
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
  scsihw = "virtio-scsi-pci"
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
    model = "virtio"
    bridge = var.network_bridge
  }
  ipconfig0 = "ip=dhcp"
  searchdomain = var.searchdomain
  ciuser = var.username
  cipassword = var.password
  sshkeys = var.ssh_public_key
}
