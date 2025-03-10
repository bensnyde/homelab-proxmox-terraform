# Proxmox Terraform Infrastructure

This Terraform configuration automates the deployment of virtual machines on a Proxmox Virtual Environment (VE). It utilizes the `telmate/proxmox` provider to manage virtual machines (VMs).


## Usage

1.  **Clone the repository.**
2.  **Create a `terraform.tfvars` file:**
    * Set the values for the variables, including your Proxmox API credentials, SSH public key, username and password.

    ```terraform
    pm_api_url          = "https://your_proxmox_ip:8006/api2/json"
    pm_api_token_id     = "your_api_token_id"
    pm_api_token_secret = "your_api_token_secret"
    ssh_public_key      = "your_ssh_public_key"
    username            = "your_username"
    password            = "your_password"
    searchdomain        = "your.domain.com"
    ```

3.  **Initialize Terraform:**

    ```bash
    terraform init
    ```

4.  **Plan the deployment:**

    ```bash
    terraform plan
    ```

5.  **Apply the configuration:**

    ```bash
    terraform apply
    ```

6.  **Access the VM:**
    * Once the VM is deployed, you can access it using SSH with the provided public key.
