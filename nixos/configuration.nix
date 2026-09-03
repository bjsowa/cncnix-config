{
  inputs,
  outputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    (inputs.nixpkgs-linuxcnc + "/nixos/modules/programs/linuxcnc.nix")
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_6_18;
  };

  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    tmux
    wget
    curl
    jq
  ];

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "C.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
      "pl_PL.UTF-8/UTF-8"
    ];
  };

  networking = {
    hostName = "cncnix";
    networkmanager.enable = true;
    firewall.enable = false;
  };

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
    ];
    config = {
      allowUnfree = true;
    };
    hostPlatform = "x86_64-linux";
  };

  programs = {
    linuxcnc.enable = true;
  };

  system.stateVersion = "26.05";

  users = {
    users = {
      cnc = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "networkmanager"
          "dialout"
        ];
        password = "cnc";
      };
    };
  };
}
