{
  config,
  lib,
  pkgs,
  inputs,
  hostName,
  ...
}:

let
  cfg = config.base;
in
{
  options.base = {
    enable = lib.mkEnableOption "Core system baseline configuration" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfree = true;

    networking = {
      hostName = hostName;
      networkmanager = {
        enable = true;
        wifi.powersave = false;
      };
    };

    # Bluetooth & Blueman manager
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    services.blueman.enable = true;

    # Timezone & Localization
    time.timeZone = "Europe/Stockholm";
    i18n.defaultLocale = "en_US.UTF-8";

    # Keyboard layout
    services.xserver.xkb = {
      layout = "se";
      variant = "";
    };
    console.keyMap = "sv-latin1";

    # Hardware acceleration & Video decoding (VA-API / Moonlight)
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver
        libva-vdpau-driver
        libvdpau-va-gl
      ];
    };

    # Power management / Clamshell mode
    # Suspend on lid close only when untethered; stay awake when docked or external power is attached
    services.logind = {
      lidSwitch = "suspend";
      lidSwitchDocked = "ignore";
      lidSwitchExternalPower = "ignore";
    };

    # Enable wake-from-sleep for all USB devices and hub controllers (Thunderbolt dock wake)
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", TEST=="power/wakeup", ATTR{power/wakeup}="enabled"
    '';

    # Flakes & Store optimization
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
    };

    # Keep only the 3 latest generations in garbage collection
    systemd.services.nix-gc-by-count = {
      description = "Keep only last 3 NixOS generations and garbage collect";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "nix-gc-keep-3" ''
          /run/current-system/sw/bin/nix-env -p /nix/var/nix/profiles/system --delete-generations +3
          /run/current-system/sw/bin/nix-collect-garbage
        '';
      };
    };

    systemd.timers.nix-gc-by-count = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };

    # Automatic system upgrades
    system.autoUpgrade = {
      enable = true;
      flake = "github:rira/nixhome#${hostName}";
      operation = "boot";
      persistent = true;
      dates = "04:00";
      randomizedDelaySec = "45min";
    };

    # Thunderbolt device management daemon
    services.hardware.bolt.enable = true;

    # Tailscale mesh VPN
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client";
    };

    # Create /var/secrets automatically owned by root
    systemd.tmpfiles.rules = [
      "d /var/secrets 0750 root wheel -"
    ];

    # Trigger autoconnect-service when secrets.env gets created/updated
    systemd.paths.tailscale-autoconnect = {
      description = "Watch for Tailscale secrets file";
      wantedBy = [ "multi-user.target" ];
      pathConfig = {
        PathExists = "/var/secrets/secrets.env";
      };
    };

    systemd.services.tailscale-autoconnect = {
      description = "Tailscale automatic authentication";
      after = [
        "network-pre.target"
        "tailscale.service"
      ];
      wants = [
        "network-pre.target"
        "tailscale.service"
      ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = "-/var/secrets/secrets.env";
      };
      script = ''
        status="$(${pkgs.tailscale}/bin/tailscale status -json | ${pkgs.jq}/bin/jq -r .BackendState)"
        if [ "$status" = "NeedsLogin" ] && [ -n "$TS_AUTH_KEY" ]; then
          ${pkgs.tailscale}/bin/tailscale up --authkey="$TS_AUTH_KEY" --accept-routes
        fi
      '';
    };

    # System-wide shell setup
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
      histSize = 10000;
      shellAliases = {
        g = "git";
      };
      setOptions = [
        "HIST_IGNORE_ALL_DUPS"
        "HIST_FIND_NO_DUPS"
        "HIST_SAVE_NO_DUPS"
        "HIST_REDUCE_BLANKS"
        "INC_APPEND_HISTORY"
        "SHARE_HISTORY"
      ];
    };

    # Global Git configuration
    programs.git = {
      enable = true;
      config = {
        alias = {
          st = "status";
          ci = "commit";
          sw = "switch";
          co = "checkout";
        };
        init = {
          defaultBranch = "main";
        };
        pull = {
          rebase = false;
        };
        push = {
          autoSetupRemote = true;
        };
        core = {
          editor = "vim";
        };
      };
    };

    # Starship cross-shell prompt
    programs.starship = {
      enable = true;
      settings = {
        add_newline = false;
        format = "$all";
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[✗](bold red)";
        };
        nix_shell = {
          symbol = "❄️ ";
          format = "via [$symbol$state]($style) ";
        };
        git_branch = {
          symbol = " ";
        };
      };
    };

    # UEFI Bootloader
    boot.loader.systemd-boot = {
      enable = true;
      configurationLimit = 3;
    };
    boot.loader.efi.canTouchEfiVariables = true;

    environment.systemPackages = with pkgs; [
      git
      curl
      vim
      jq
      htop
      usbutils
      pciutils
      wl-clipboard
      xclip
      grim
      slurp
      networkmanagerapplet
      libva-utils
      psmisc
      bluez
      blueman
      trayscale
      nh
      alsa-utils
    ];

    system.stateVersion = "24.11";
  };
}
