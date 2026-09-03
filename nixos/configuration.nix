{
  inputs,
  outputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./disko.nix
    (inputs.nixpkgs-linuxcnc + "/nixos/modules/programs/linuxcnc.nix")
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_6_18;
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    initrd.availableKernelModules = [
      "virtio_net"
      "virtio_pci"
      "virtio_mmio"
      "virtio_blk"
      "virtio_scsi"
      "9p"
      "9pnet_virtio"
      "qemu_fw_cfg"
    ];
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

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  system.stateVersion = "26.05";

  users = {
    users = {
      root.password = "cnc";
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
