terraform {
  # This remains empty because the Makefile injects the R2 
  # or Local settings during 'tofu init'
  backend "s3" {}

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.69.1" 
    }
  }
}

variable "deploy_haos" { type = bool }
variable "deploy_adguard" { type = bool }
variable "deploy_portainer" { type = bool }

variable "proxmox_endpoint" { type = string }
variable "proxmox_username" { type = string }
variable "proxmox_password" { type = string, sensitive = true }

variable "nixos_repo" { type = string }
variable "sops_nix_url" { type = string }
variable "github_repo" { type = string }
variable "ssh_public_key" { type = string }
variable "sops_ssh_key_path" { type = string }
variable "provisioner_private_key" { type = string }
variable "haos_image_url" { type = string }

variable "haos_vm_id" { type = number }
variable "adguard_vm_id" { type = number }
variable "portainer_vm_id" { type = number }

variable "timezone" { type = string }
variable "auto_update_schedule" { type = string }
variable "haos_hostname" { type = string }
variable "haos_ip" { type = string }
variable "ha_name" { type = string }
variable "ha_unit_system" { type = string }
variable "ha_currency" { type = string }

variable "adguard_hostname" { type = string }
variable "adguard_ip" { type = string }
variable "portainer_hostname" { type = string }
variable "portainer_ip" { type = string }
variable "portainer_port_http" { type = number }
variable "portainer_port_https" { type = number }

variable "haos_cores" { type = number }
variable "haos_memory" { type = number }
variable "haos_disk_size" { type = number }
variable "adguard_cores" { type = number }
variable "adguard_memory" { type = number }
variable "adguard_disk_size" { type = number }
variable "portainer_cores" { type = number }
variable "portainer_memory" { type = number }
variable "portainer_disk_size" { type = number }

locals {
  nixos_state_version = regex("nixos-([0-9]{2}\\.[0-9]{2})", var.nixos_repo)[0]
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  insecure = true 
  username = var.proxmox_username
  password = var.proxmox_password
}

# --- Dynamic File Generation ---
resource "local_file" "sops_config" {
  content  = <<-EOT
    keys:
      - &admin ${var.ssh_public_key}
    creation_rules:
      - path_regex: secrets.yaml$
        key_groups:
          - age:
            - *admin
  EOT
  filename = "${path.module}/.sops.yaml"
}

resource "local_file" "flake_nix" {
  content  = <<-EOT
    {
      inputs = {
        nixpkgs.url = "${var.nixos_repo}";
        disko.url = "github:nix-community/disko";
        disko.inputs.nixpkgs.follows = "nixpkgs";
        sops-nix.url = "${var.sops_nix_url}";
        sops-nix.inputs.nixpkgs.follows = "nixpkgs";
      };

      outputs = { self, nixpkgs, disko, sops-nix, ... }: {
        nixosConfigurations = {
          custom-iso = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ ./iso.nix ];
          };
          adguard = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ 
              disko.nixosModules.disko 
              sops-nix.nixosModules.sops
              ./disk-config.nix 
              ./vms/adguard/configuration.nix 
            ];
          };
          portainer = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ 
              disko.nixosModules.disko 
              sops-nix.nixosModules.sops
              ./disk-config.nix 
              ./vms/portainer/configuration.nix 
            ];
          };
        };
      };
    }
  EOT
  filename = "${path.module}/flake.nix"
}

resource "local_file" "nix_vars" {
  content  = <<-EOT
    {
      githubRepo = "${var.github_repo}";
      sshKeys = [ "${var.ssh_public_key}" ];
      sopsSshKeyPath = "${var.sops_ssh_key_path}";
      timeZone = "${var.timezone}";
      autoUpdateSchedule = "${var.auto_update_schedule}";
      adguardHostName = "${var.adguard_hostname}";
      portainerHostName = "${var.portainer_hostname}";
      portainerPortHttp = ${var.portainer_port_http};
      portainerPortHttps = ${var.portainer_port_https};
      stateVersion = "${local.nixos_state_version}";
    }
  EOT
  filename = "${path.module}/generated-vars.nix"
}

resource "local_file" "ha_config_yaml" {
  content  = <<-EOT
    # Core Home Assistant Configuration
    homeassistant:
      name: "${var.ha_name}"
      unit_system: "${var.ha_unit_system}"
      currency: "${var.ha_currency}"
      time_zone: "${var.timezone}"

    # Basic UI and Discoverability
    default_config:
    frontend:
    history:
    logbook:
    zeroconf:
    ssdp:
  EOT
  filename = "${path.module}/vms/haos/configuration.yaml"
}

# --- Infrastructure Deployment ---
resource "proxmox_virtual_environment_download_file" "haos_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve"
  url          = var.haos_image_url
}

resource "proxmox_virtual_environment_file" "custom_nixos_iso" {
  depends_on   = [null_resource.build_custom_iso] 
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve"
  source_file  = "${path.module}/result/iso/nixos-minimal-${local.nixos_state_version}-x86_64-linux.iso" 
}

resource "null_resource" "build_custom_iso" {
  depends_on = [local_file.flake_nix, local_file.nix_vars]
  provisioner "local-exec" {
    command = "nix build .#nixosConfigurations.custom-iso.config.system.build.isoImage"
  }
}

# --- HAOS Deployment ---
resource "proxmox_virtual_environment_vm" "haos" {
  count     = var.deploy_haos ? 1 : 0
  name      = var.haos_hostname
  node_name = "pve"
  vm_id     = var.haos_vm_id
  machine   = "q35"
  bios      = "ovmf"
  cpu { cores = var.haos_cores }
  memory { dedicated = var.haos_memory }
  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.haos_image.id
    size         = var.haos_disk_size
    interface    = "scsi0"
  }
  network_device { bridge = "vmbr0" }
}

resource "null_resource" "haos_initial_config" {
  count      = var.deploy_haos ? 1 : 0
  depends_on = [proxmox_virtual_environment_vm.haos, local_file.ha_config_yaml]

  provisioner "file" {
    source      = local_file.ha_config_yaml.filename
    destination = "/config/configuration.yaml"
  }

  connection {
    type        = "ssh"
    user        = "root"
    host        = var.haos_ip
    private_key = file(pathexpand(var.provisioner_private_key))
  }
}

# --- AdGuard Deployment ---
resource "proxmox_virtual_environment_vm" "nixos_adguard" {
  count     = var.deploy_adguard ? 1 : 0
  name      = var.adguard_hostname
  node_name = "pve"
  vm_id     = var.adguard_vm_id
  cpu { cores = var.adguard_cores }
  memory { dedicated = var.adguard_memory }
  disk {
    datastore_id = "local-lvm"
    size         = var.adguard_disk_size
    interface    = "scsi0"
  }
  cdrom {
    enabled   = true
    file_id   = proxmox_virtual_environment_file.custom_nixos_iso.id
    interface = "ide2"
  }
  network_device { bridge = "vmbr0" }
}

resource "null_resource" "deploy_adguard" {
  count      = var.deploy_adguard ? 1 : 0
  depends_on = [proxmox_virtual_environment_vm.nixos_adguard]
  provisioner "local-exec" {
    command = "sleep 60 && nix run github:numtide/nixos-anywhere -- --flake .#adguard root@${var.adguard_ip}"
  }
}

# --- Portainer Deployment ---
resource "proxmox_virtual_environment_vm" "nixos_portainer" {
  count     = var.deploy_portainer ? 1 : 0
  name      = var.portainer_hostname
  node_name = "pve"
  vm_id     = var.portainer_vm_id
  cpu { cores = var.portainer_cores }
  memory { dedicated = var.portainer_memory }
  disk {
    datastore_id = "local-lvm"
    size         = var.portainer_disk_size
    interface    = "scsi0"
  }
  cdrom {
    enabled   = true
    file_id   = proxmox_virtual_environment_file.custom_nixos_iso.id
    interface = "ide2"
  }
  network_device { bridge = "vmbr0" }
}

resource "null_resource" "deploy_portainer" {
  count      = var.deploy_portainer ? 1 : 0
  depends_on = [proxmox_virtual_environment_vm.nixos_portainer]
  provisioner "local-exec" {
    command = "sleep 60 && nix run github:numtide/nixos-anywhere -- --flake .#portainer root@${var.portainer_ip}"
  }
}