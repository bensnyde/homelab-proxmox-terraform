{ config, pkgs, modulesPath, ... }: 
let
  vars = import ../../generated-vars.nix;
in {
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = vars.adguardHostName;
  networking.networkmanager.enable = true;
  time.timeZone = vars.timeZone;

  sops.defaultSopsFile = ../../secrets.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ]; 
  
  sops.secrets.adguard_hash = { owner = "adguardhome"; };
  sops.secrets.os_password_hash = { neededForUsers = true; };

  services.adguardhome = {
    enable = true;
    openFirewall = true;
    
    settings = {
      # --- Filtering & Protection Settings ---
      protection_enabled = true;   # Enables overall protection
      filtering_enabled = true;    # Enables DNS request filtering based on your rule lists
      safebrowsing_enabled = true; # Blocks known malicious domains
      
      # (Optional) Enforce Safe Search on search engines like Google and DuckDuckGo
      safe_search = {
        enabled = false;
      };
      
      # (Optional) Parental control filtering
      parental_enabled = false;

      users = [{
        name = "admin";
        password = config.sops.secrets.adguard_hash.path;
      }];
    };
  };

  system.autoUpgrade = {
    enable = true;
    flake = vars.githubRepo;
    allowReboot = true;
    dates = vars.autoUpdateSchedule; 
  };

  services.openssh.enable = true;
  services.qemuGuest.enable = true;

  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPasswordFile = config.sops.secrets.os_password_hash.path; 
    openssh.authorizedKeys.keys = vars.sshKeys;
  };

  environment.systemPackages = with pkgs; [ nano wget git curl sops ];
  system.stateVersion = vars.stateVersion;
}