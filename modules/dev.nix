{ config, lib, pkgs, ... }:

let
  cfg = config.features.dev;
in
{
  options.features.dev = {
    enable = lib.mkEnableOption "Developer tools and environments";
  };

  config = lib.mkIf cfg.enable {
    # Allow execution of unpatched dynamic binaries (agy, language servers, etc.)
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc.lib
        zlib
        openssl
        curl
        glibc
        libxcrypt-legacy
      ];
    };

    # Fast and automatic per-directory Nix flake environment loading
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # Development tools, editor, and CLI utilities
    environment.systemPackages = with pkgs; [
      gh
      ripgrep
      fd
      tree
      neovim
      zed-editor
      gnumake
      gcc
    ];

    # Daily automated update check for Antigravity CLI
    systemd.user.services.agy-update = {
      description = "Update Antigravity CLI (agy)";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "agy-update" ''
          if [ -x "$HOME/.local/bin/agy" ]; then
            "$HOME/.local/bin/agy" update
          fi
        '';
      };
    };

    systemd.user.timers.agy-update = {
      description = "Daily update timer for agy";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };

    # Shell aliases for development environment
    programs.zsh.shellAliases = {
      cdp = "cd /home/richard/projects";
    };
  };
}
