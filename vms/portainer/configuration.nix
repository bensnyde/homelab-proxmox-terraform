{ config, pkgs, modulesPath, ... }: 
let
  vars = import ../../generated-vars.nix;
in {
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = vars.portainerHostName;
  networking.networkmanager.enable = true;
  time.timeZone = vars.timeZone;

  sops.defaultSopsFile = ../../secrets.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  
  sops.secrets.portainer_password = {};
  sops.secrets.os_password_hash = { neededForUsers = true; };

  sops.templates."portainer.env".content = ''
    ADMIN_PASSWORD=''${config.sops.placeholder.portainer_password}
  '';

  virtualisation.docker.enable = true;
  virtualisation.oci-containers.containers."portainer" = {
    image = "portainer/portainer-ce:latest";
    ports = [ 
      "${toString vars.portainerPortHttp}:8000" 
      "${toString vars.portainerPortHttps}:9443" 
    ];
    volumes = [ 
      "/var/run/docker.sock:/var/run/docker.sock" 
      "portainer_data:/data" 
    ];
    environmentFiles = [ config.sops.templates."portainer.env".path ]; 
  };

  system.autoUpgrade = {
    enable = true;
    flake = vars.githubRepo;
    allowReboot = true;
    dates = vars.autoUpdateSchedule; 
  };

  networking.firewall.allowedTCPPorts = [ vars.portainerPortHttp vars.portainerPortHttps ];
  services.openssh.enable = true;
  services.qemuGuest.enable = true;

  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    hashedPasswordFile = config.sops.secrets.os_password_hash.path; 
    openssh.authorizedKeys.keys = vars.sshKeys;
  };

  environment.systemPackages = with pkgs; [ nano wget git curl docker-compose sops ];
  system.stateVersion = vars.stateVersion;
}