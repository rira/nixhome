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

    networking.hostName = hostName;
    networking.networkmanager.enable = true;

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

    # Flakes & Store optimization
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
    };

    # Garbage collection
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
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

    # Create /var/secrets automatically for richard
    systemd.tmpfiles.rules = [
      "d /var/secrets 0750 richard wheel -"
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

    # SSH remote management
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };

    # Universal Fleet Administrator Account
    users.users.richard = {
      isNormalUser = true;
      description = "Fleet Administrator";
      initialPassword = "changeme";
      extraGroups = [
        "wheel"
        "networkmanager"
        "video"
        "audio"
        "input"
      ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBO8CcDAcZ2wt4FThIlr3Nffe6EY+6+ZNBgdKjUBWjtb richard-fleet-admin"
      ];
    };

    # Passwordless sudo for admin tasks
    security.sudo.wheelNeedsPassword = false;

    # System-wide shell setup
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
      histSize = 10000;
      setOptions = [
        "HIST_IGNORE_ALL_DUPS"
        "HIST_FIND_NO_DUPS"
        "HIST_SAVE_NO_DUPS"
        "HIST_REDUCE_BLANKS"
        "INC_APPEND_HISTORY"
        "SHARE_HISTORY"
      ];
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
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Base CLI packages
    environment.systemPackages = with pkgs; [
      git
      curl
      vim
      jq
      htop
      wl-clipboard
      xclip
      grim
      slurp
      networkmanagerapplet
      libva-utils
      psmisc
      bluez
      blueman
    ];

    system.stateVersion = "24.11";
  };
}
