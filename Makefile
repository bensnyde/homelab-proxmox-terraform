# Proxmox Homelab Automation
# Requires: OpenTofu, Nix, SOPS, and a populated .env file

# Default shell for Makefile commands
SHELL := /bin/bash

# Ensure SOPS knows to use the SSH key defined in your .env
# We clear the AGE variable to force SSH usage.
export SOPS_AGE_KEY_FILE=
export SOPS_IMPORT_PGP=false
export SOPS_SSH_KEY_PATHS=$(TF_VAR_sops_ssh_key_path)

# Define the R2 config string only if the variable is present
ifneq ($(TF_VAR_r2_account_id),)
    BACKEND_FLAGS = -backend-config="bucket=$(TF_VAR_r2_bucket)" \
                    -backend-config="endpoint=https://$(TF_VAR_r2_account_id).r2.cloudflarestorage.com" \
                    -backend-config="region=auto" \
                    -backend-config="skip_credentials_validation=true" \
                    -backend-config="skip_metadata_api_check=true" \
                    -backend-config="skip_region_validation=true" \
                    -backend-config="force_path_style=true"
    BACKEND_TYPE = "Cloudflare R2 (S3-Compatible)"
else
    BACKEND_TYPE = "Local (terraform.tfstate)"
endif

.PHONY: help bootstrap status refresh plan apply clean encrypt decrypt

help:
	@echo "Usage:"
	@echo "  make bootstrap  - Update OS versions, create dirs, and init OpenTofu"
	@echo "  make status     - Verify state backend connection and list resources"
	@echo "  make refresh    - Update local state to match the real-world Proxmox status"
	@echo "  make plan       - Show the OpenTofu deployment plan"
	@echo "  make apply      - Build ISO and deploy all VMs to Proxmox"
	@echo "  make encrypt    - Encrypt secrets.yaml using SSH key"
	@echo "  make decrypt    - Decrypt secrets.yaml for editing"

# Step 1: Prepare the environment from top to bottom
bootstrap:
	@echo "Using SOPS Key: $(TF_VAR_sops_ssh_key_path)"
	@echo "Fetching latest HAOS and NixOS versions..."
	chmod +x update_env_latest_image_urls.sh
	./update_env_latest_image_urls.sh
	@echo "Initializing Backend: $(BACKEND_TYPE)"
	mkdir -p vms/haos vms/adguard vms/portainer
	source .env && tofu init $(BACKEND_FLAGS) -reconfigure
	source .env && tofu apply -target=local_file.sops_config \
		-target=local_file.flake_nix \
		-target=local_file.nix_vars \
		-target=local_file.ha_config_yaml \
		-auto-approve

# Update local state to match the real-world Proxmox status
refresh:
	@echo "Refreshing state from Proxmox..."
	source .env && tofu refresh

# Verify connection and list managed resources
status: refresh
	@echo "Checking State Backend: $(BACKEND_TYPE)"
	source .env && tofu state list

# Step 2: Deployment
plan:
	source .env && tofu plan

apply:
	source .env && tofu apply -auto-approve

# Helper: Secret Management
encrypt:
	sops --encrypt --in-place secrets.yaml

decrypt:
	sops --decrypt --in-place secrets.yaml

# Clean up build artifacts
clean:
	rm -rf result/ .terraform/ terraform.tfstate* flake.nix .sops.yaml generated-vars.nix vms/haos/configuration.yaml