{ config, lib, pkgs, inputs, hostName, ... }:

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

    # Timezone & Localization
    time.timeZone = "Europe/Stockholm";
    i18n.defaultLocale = "en_US.UTF-8";

    # Keyboard layout
    services.xserver.xkb = {
      layout = "se";
      variant = "";
    };
    console.keyMap = "sv-latin1";

    # Flakes & Store optimization
    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
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

    # Tailscale mesh VPN
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client";
    };

    systemd.services.tailscale-autoconnect = {
      description = "Tailscale automatic authentication";
      after = [ "network-pre.target" "tailscale.service" ];
      wants = [ "network-pre.target" "tailscale.service" ];
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
      extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [
        # Lägg till din publika SSH-nyckel här
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
    ];

    system.stateVersion = "24.11";
  };
}
