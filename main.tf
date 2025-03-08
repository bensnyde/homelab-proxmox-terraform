terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
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
  default     = "pve"
}

variable "storage" {
  description = "Storage to use for VM disks"
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Network bridge to use for VMs"
  default     = "vmbr0"
}

variable "template_kubernetes" {
  description = "Template ID for Kubernetes VM"
  default     = "iso:vm-100-disk-0"
}

variable "template_android" {
  description = "Template ID for Android VM"
  default     = "iso:vm-101-disk-0"
}

variable "template_homeassistant" {
  description = "Template ID for Home Assistant VM"
  default     = "iso:vm-102-disk-0"
}

variable "template_fedora" {
  description = "Template ID for Fedora Aurora VM"
  default     = "iso:vm-103-disk-0"
}

variable "ssh_public_key" {
  description = "SSH public key to inject into VMs"
  type        = string
  sensitive   = true
}

resource "proxmox_vm_qemu" "kubernetes" {
  name        = "kubernetes"
  target_node = var.node
  clone       = var.template_kubernetes
  clone_wait  = 10
  cores       = 4
  sockets     = 4
  memory      = 8192
  os_type     = "l26"
  storage     = var.storage
  network {
    model   = "virtio"
    bridge  = var.network_bridge
  }
  ssh_forward_ip = "127.0.0.1"
  sshkeys = var.ssh_public_key
}

resource "proxmox_vm_qemu" "android" {
  name        = "android"
  target_node = var.node
  clone       = var.template_android
  clone_wait  = 10
  cores       = 4
  sockets     = 1
  memory      = 8192
  os_type     = "l26"
  storage     = var.storage
  network {
    model   = "virtio"
    bridge  = var.network_bridge
  }
  ssh_forward_ip = "127.0.0.1"
  sshkeys = var.ssh_public_key
}

resource "proxmox_vm_qemu" "homeassistant" {
  name        = "homeassistant"
  target_node = var.node
  clone       = var.template_homeassistant
  clone_wait  = 10
  cores       = 2
  sockets     = 2
  memory      = 8192
  os_type     = "l26"
  storage     = var.storage
  network {
    model   = "virtio"
    bridge  = var.network_bridge
  }
  ssh_forward_ip = "127.0.0.1"
  sshkeys = var.ssh_public_key
}

resource "proxmox_vm_qemu" "fedora_aurora" {
  name        = "fedora-aurora"
  target_node = var.node
  clone       = var.template_fedora
  clone_wait  = 10
  cores       = 4
  sockets     = 2
  memory      = 8192
  os_type     = "l26"
  storage     = var.storage
  network {
    model   = "virtio"
    bridge  = var.network_bridge
  }
  ssh_forward_ip = "127.0.0.1"
  sshkeys = var.ssh_public_key
}
