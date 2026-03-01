#!/bin/bash

# Fetch latest HAOS qcow2 URL
HAOS_URL=$(curl -s https://api.github.com/repos/home-assistant/operating-system/releases/latest | \
  grep "browser_download_url" | grep "haos_ova" | grep ".qcow2.xz" | cut -d '"' -f 4)

# Fetch latest NixOS stable branch (e.g., nixos-24.11)
NIXOS_VER=$(curl -s https://api.github.com/repos/NixOS/nixpkgs/branches | \
  grep "name" | grep -E "nixos-[0-9]{2}\.[0-9]{2}" | sort -V | tail -n 1 | cut -d '"' -f 4)

if [ -z "$HAOS_URL" ] || [ -z "$NIXOS_VER" ]; then
    echo "Error: Could not fetch latest versions."
    exit 1
fi

# Update .env file
# Note: This assumes the variables already exist in the file
sed -i "s|export TF_VAR_haos_image_url=.*|export TF_VAR_haos_image_url=\"$HAOS_URL\"|" .env
sed -i "s|export TF_VAR_nixos_repo=.*|export TF_VAR_nixos_repo=\"github:NixOS/nixpkgs/$NIXOS_VER\"|" .env

echo "Successfully updated .env with:"
echo "HAOS: $HAOS_URL"
echo "NixOS: $NIXOS_VER"