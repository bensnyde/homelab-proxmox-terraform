# vms.tf

module "haos" {
  source = "./vms/haos"
  count  = var.deploy_haos ? 1 : 0

  proxmox_node = var.proxmox_node
  vm_id        = var.haos_vm_id
  ip_address   = var.haos_ip
  gateway      = var.network_gateway
}

module "adguard" {
  source = "./vms/adguard"
  count  = var.deploy_adguard ? 1 : 0

  proxmox_node   = var.proxmox_node
  vm_id          = var.adguard_vm_id
  ip_address     = var.adguard_ip
  gateway        = var.network_gateway
  ssh_public_key = var.ssh_public_key
}

module "portainer" {
  source = "./vms/portainer"
  count  = var.deploy_portainer ? 1 : 0

  proxmox_node   = var.proxmox_node
  vm_id          = var.portainer_vm_id
  ip_address     = var.portainer_ip
  gateway        = var.network_gateway
  ssh_public_key = var.ssh_public_key
}