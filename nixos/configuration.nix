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
    kernelPackages = pkgs.linuxPackagesFor (
      pkgs.linux_6_18.override {
        structuredExtraConfig = with lib.kernel; {
          EXPERT = yes;
          PREEMPT_RT = yes;
          RT_GROUP_SCHED = no;
        };
        ignoreConfigErrors = true;
      }
    );
    kernelParams = [
      "isolcpus=1"
      "nohz_full=1"
      "rcu_nocbs=1"
      "irqaffinity=0" # Routes all routeable hardware interrupts to Core 0
    ];
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
    curl
    firefox
    git
    htop
    jq
    tmux
    wget
    vim
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

  services.xserver = {
    enable = true;
    desktopManager.xfce.enable = true;
    displayManager.lightdm.enable = true;
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
