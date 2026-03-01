FROM mcr.microsoft.com/devcontainers/base:debian
# Install OpenTofu, Nix, and SOPS
RUN apt-get update && apt-get install -y curl gnupg software-properties-common
RUN curl -fsSL https://get.opentofu.org/opentofu.gpg | gpg --dearmor -o /etc/apt/keyrings/opentofu.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/opentofu.gpg] https://packages.opentofu.org/opentofu/main/ubuntu/ any main" > /etc/apt/sources.list.d/opentofu.list \
    && apt-get update && apt-get install -y tofu sops age nix-bin