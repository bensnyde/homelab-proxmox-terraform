resource "local_file" "sops_config" {
  # Notice the /.. to push the file back to the repository root
  filename = "${path.module}/../.sops.yaml"
  content  = "# Generated SOPS config..."
}

resource "local_file" "flake_nix" {
  filename = "${path.module}/../flake.nix"
  content  = "# Generated Nix Flake..."
}

resource "local_file" "ha_config_yaml" {
  # Since the vms folder moved into terraform/, this one stays local!
  filename = "${path.module}/vms/haos/configuration.yaml"
  content  = "# Generated HAOS Config..."
}

resource "local_file" "nix_vars" {
  filename = "${path.module}/../nixos/generated-vars.nix"
  content  = "# Generated Nix Vars..."
}