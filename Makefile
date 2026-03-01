# Proxmox Homelab Automation
SHELL := /bin/bash

# Secret Management Exports
export SOPS_AGE_KEY_FILE=
export SOPS_IMPORT_PGP=false
export SOPS_SSH_KEY_PATHS=$(TF_VAR_sops_ssh_key_path)

# --- Backend Detection Logic ---
ifneq ($(TF_VAR_r2_account_id),)
    # Scenario 1: Cloudflare R2
    BACKEND_TYPE = "Cloudflare R2 (S3-Compatible)"
    BACKEND_FLAGS = -backend-config="bucket=$(TF_VAR_r2_bucket)" \
                    -backend-config="endpoint=https://$(TF_VAR_r2_account_id).r2.cloudflarestorage.com" \
                    -backend-config="region=auto" \
                    -backend-config="skip_credentials_validation=true" \
                    -backend-config="skip_metadata_api_check=true" \
                    -backend-config="skip_region_validation=true" \
                    -backend-config="force_path_style=true"
else ifneq ($(TF_VAR_s3_bucket),)
    # Scenario 2: Amazon S3
    BACKEND_TYPE = "Amazon S3"
    BACKEND_FLAGS = -backend-config="bucket=$(TF_VAR_s3_bucket)" \
                    -backend-config="region=$(TF_VAR_s3_region)"
else
    # Scenario 3: Local fallback
    BACKEND_TYPE = "Local (terraform.tfstate)"
    BACKEND_FLAGS = -backend-config="path=terraform.tfstate"
endif

.PHONY: help bootstrap status refresh plan apply clean encrypt decrypt

help:
	@echo "Detected Backend: $(BACKEND_TYPE)"
	@echo "Usage:"
	@echo "  make bootstrap  - Update versions and init OpenTofu with $(BACKEND_TYPE)"
	@echo "  make status     - Refresh and list managed resources"
	@echo "  make apply      - Deploy infrastructure to Proxmox"

bootstrap:
	@echo "Initializing Backend: $(BACKEND_TYPE)"
	chmod +x update_env_latest_image_urls.sh
	./update_env_latest_image_urls.sh
	mkdir -p vms/haos vms/adguard vms/portainer
	source .env && tofu init $(BACKEND_FLAGS) -reconfigure
	source .env && tofu apply -target=local_file.sops_config \
		-target=local_file.flake_nix \
		-target=local_file.nix_vars \
		-target=local_file.ha_config_yaml \
		-auto-approve

refresh:
	source .env && tofu refresh

status: refresh
	@echo "Backend: $(BACKEND_TYPE)"
	source .env && tofu state list

plan:
	source .env && tofu plan

apply:
	source .env && tofu apply -auto-approve

encrypt:
	sops --encrypt --in-place secrets.yaml

decrypt:
	sops --decrypt --in-place secrets.yaml

clean:
	rm -rf result/ .terraform/ terraform.tfstate* flake.nix .sops.yaml generated-vars.nix vms/haos/configuration.yaml