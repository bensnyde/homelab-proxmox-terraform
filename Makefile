# Proxmox Homelab Automation
SHELL := /bin/bash

# Secret Management Exports
export SOPS_AGE_KEY_FILE=
export SOPS_IMPORT_PGP=false
export SOPS_SSH_KEY_PATHS=$(TF_VAR_sops_ssh_key_path)

# --- Backend Detection Logic ---
ifneq ($(TF_VAR_r2_account_id),)
	BACKEND_TYPE = Cloudflare R2 S3-Compatible
	BACKEND_FLAGS = -backend-config="bucket=$(TF_VAR_r2_bucket)" \
					-backend-config="endpoint=https://$(TF_VAR_r2_account_id).r2.cloudflarestorage.com" \
					-backend-config="region=auto" \
					-backend-config="skip_credentials_validation=true" \
					-backend-config="skip_metadata_api_check=true" \
					-backend-config="skip_region_validation=true" \
					-backend-config="force_path_style=true"
else ifneq ($(TF_VAR_s3_bucket),)
	BACKEND_TYPE = Amazon S3
	BACKEND_FLAGS = -backend-config="bucket=$(TF_VAR_s3_bucket)" \
					-backend-config="region=$(TF_VAR_s3_region)"
else
	BACKEND_TYPE = Local terraform.tfstate
	BACKEND_FLAGS = -backend-config="path=terraform.tfstate"
endif

.PHONY: help bootstrap status refresh plan apply clean encrypt decrypt

help:
	@echo '============================================================'
	@echo 'PROXMOX HOMELAB AUTOMATION'
	@echo 'Detected Backend: $(BACKEND_TYPE)'
	@echo '============================================================'
	@echo 'Usage:'
	@echo '  make bootstrap  - 1. Fetches latest HAOS/NixOS image URLs'
	@echo '                    2. Initializes OpenTofu with $(BACKEND_TYPE)'
	@echo '                    3. Generates Nix/Sops/HA config artifacts'
	@echo ''
	@echo '  make status     - Reconciles state with Proxmox and lists all'
	@echo '                    active managed resources (VMs and Files)'
	@echo ''
	@echo '  make refresh    - Updates your local/remote state file to match'
	@echo '                    the current real-world status of Proxmox'
	@echo ''
	@echo '  make plan       - Calculates changes and shows the deployment'
	@echo '                    preview without making any modifications'
	@echo ''
	@echo '  make apply      - Builds the NixOS ISO and deploys all enabled'
	@echo '                    VMs (HAOS, AdGuard, Portainer) to Proxmox'
	@echo ''
	@echo '  make encrypt    - Encrypts secrets.yaml using your SSH key'
	@echo '  make decrypt    - Decrypts secrets.yaml for plaintext editing'
	@echo ''
	@echo '  make clean      - Deletes all local build artifacts, generated'
	@echo '                    configs, and temporary Terraform files'
	@echo '============================================================'

bootstrap:
	@echo 'Initializing Backend: $(BACKEND_TYPE)'
	chmod +x scripts/update_env_latest_img_urls.sh
	./scripts/update_env_latest_img_urls.sh
	mkdir -p terraform/vms/haos terraform/vms/adguard terraform/vms/portainer
	source .env && tofu -chdir=terraform init $(BACKEND_FLAGS) -reconfigure
	source .env && tofu -chdir=terraform apply -target=local_file.sops_config \
		-target=local_file.flake_nix \
		-target=local_file.nix_vars \
		-target=local_file.ha_config_yaml \
		-auto-approve

refresh:
	source .env && tofu -chdir=terraform refresh

status: refresh
	@echo 'Backend: $(BACKEND_TYPE)'
	source .env && tofu -chdir=terraform state list

plan:
	source .env && tofu -chdir=terraform plan

apply:
	@# 1. Create a temporary folder for the extra files
	mkdir -p ./tmp/etc/ssh
	
	@# 2. Copy your private key into the temporary folder
	@# Using the variable from your .env
	cp $(TF_VAR_provisioner_private_key) ./tmp/etc/ssh/ssh_host_ed25519_key
	chmod 600 ./tmp/etc/ssh/ssh_host_ed25519_key
	
	@# 3. Run OpenTofu with the extra-files flag passed to nixos-anywhere
	@# This assumes your OpenTofu code triggers nixos-anywhere
	source .env && tofu -chdir=terraform apply -auto-approve \
		-var='extra_files_dir=../tmp'
	
	@# 4. Cleanup
	rm -rf ./tmp

encrypt:
	sops --encrypt --in-place secrets.yaml

decrypt:
	sops --decrypt --in-place secrets.yaml

clean:
	rm -rf result/ .terraform/ terraform.tfstate* flake.nix .sops.yaml generated-vars.nix vms/haos/configuration.yaml