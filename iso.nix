{ pkgs, modulesPath, ... }: 
let
  vars = import ./generated-vars.nix;
in {
  imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];
  services.openssh.enable = true;
  
  users.users.root.openssh.authorizedKeys.keys = vars.sshKeys;
  users.users.nixos.openssh.authorizedKeys.keys = vars.sshKeys;
  time.timeZone = vars.timeZone;
  nixpkgs.config.allowUnfree = true;
}