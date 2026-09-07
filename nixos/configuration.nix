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
      "ahci"
      "xhci_pci"
      "ehci_pci"
      "usbhid"
      "usb_storage"
      "sd_mod"
      "sr_mod"
    ];
  };

  environment.systemPackages = with pkgs; [
    curl
    dig
    firefox
    file
    git
    htop
    jq
    lshw
    mesaflash
    pciutils
    python3
    rclone
    screen
    tmux
    unrar
    usbutils
    vim
    vscode
    wget
    zip
  ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-vaapi-driver # Haswell uses the legacy intel-vaapi-driver (libva-intel-driver)
      libvdpau-va-gl
    ];
  };

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

    wg-quick.interfaces = {
      wg-io = {
        autostart = true;
        address = [ "10.100.0.4/24" ];
        listenPort = 51820;
        privateKeyFile = "/private/secrets/wg-io.key";
        peers = [
          {
            publicKey = "io/aP205KKnDPV8GYWUbIfnodrjl4lwdcEFMhM9IlE4=";
            endpoint = "78.46.205.86:51820";
            allowedIPs = [
              "10.100.0.0/24"
              "192.168.10.0/24"
            ];
            persistentKeepalive = 25;
          }
        ];
      };
    };
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

    udev.extraRules = ''
      ATTRS{idVendor}=="10ce", ATTRS{idProduct}=="eb70", MODE="666", OWNER="root", GROUP="users"
    '';

    xserver = {
      enable = true;

      xkb = {
        layout = "pl";
        variant = "";
      };

      desktopManager.xfce = {
        enable = true;
        enableScreensaver = false;
      };
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
