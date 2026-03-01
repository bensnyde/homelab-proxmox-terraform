# artifacts.tf

resource "local_file" "sops_config" {
  filename = "${path.module}/.sops.yaml"
  content  = "# Generated SOPS config..."
}

resource "local_file" "flake_nix" {
  filename = "${path.module}/flake.nix"
  content  = "# Generated Nix Flake..."
}

resource "local_file" "nix_vars" {
  filename = "${path.module}/generated-vars.nix"
  content  = "# Generated Nix Vars..."
}

resource "local_file" "ha_config_yaml" {
  filename = "${path.module}/vms/haos/configuration.yaml"
  content  = "# Generated HAOS Config..."
}