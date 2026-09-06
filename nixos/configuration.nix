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

      "processor.max_cstate=0" # Disable ACPI processor C-states
      "intel_idle.max_cstate=0" # Disable Intel driver C-states (or amd_iommu=off if AMD)
      "idle=poll" # Never sleep the CPU (keeps polling instead of sleeping)
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
    mesaflash
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

  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in
    {
      settings = {
        experimental-features = "nix-command flakes";
        flake-registry = "";
      };

      # Opinionated: disable channels
      channel.enable = false;

      # Make flake registry and nix path match flake inputs
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };

  # Lock CPU to max frequency (performance governor)
  powerManagement.cpuFreqGovernor = "performance";

  programs = {
    linuxcnc.enable = true;
  };

  security.pam.loginLimits = [
    {
      domain = "@wheel";
      item = "rtprio";
      type = "-";
      value = "99";
    }
    {
      domain = "@wheel";
      item = "memlock";
      type = "-";
      value = "unlimited";
    }
    {
      domain = "@wheel";
      item = "nice";
      type = "-";
      value = "-20";
    }
  ];

  services = {
    displayManager = {
      autoLogin = {
        enable = true;
        user = "cnc";
      };
    };

    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = true;
      };
    };

    xserver = {
      enable = true;

      xkb = {
        layout = "pl";
        variant = "";
      };

      desktopManager.xfce.enable = true;
      displayManager.lightdm.enable = true;

      # Prevent screen blanking and DPMS sleep in X11
      serverFlagsSection = ''
        Option "BlankTime" "0"
        Option "StandbyTime" "0"
        Option "SuspendTime" "0"
        Option "OffTime" "0"
      '';
    };
  };

  system.stateVersion = "26.05";

  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  time.timeZone = "Europe/Warsaw";

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
