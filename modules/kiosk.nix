{ config, lib, pkgs, ... }:

let
  cfg = config.features.kiosk;

  # Shell wrapper script establishing Wayland runtime environment and starting Moonlight
  kioskRunner = pkgs.writeShellScriptBin "kiosk-runner" ''
    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    export WAYLAND_DISPLAY="wayland-0"
    exec ${pkgs.moonlight-qt}/bin/moonlight
  '';
in
{
  options.features.kiosk = {
    enable = lib.mkEnableOption "Dedicated Cage Wayland kiosk session for Moonlight";
    user = lib.mkOption {
      type = lib.types.str;
      default = "kiosk";
      description = "Dedicated system user account running the kiosk session";
    };
  };

  config = lib.mkIf cfg.enable {
    # Unprivileged user running the graphical interface
    users.users.${cfg.user} = {
      isNormalUser = true;
      extraGroups = [ "video" "audio" "input" ];
      initialPassword = "kiosk";
    };

    # Launch Cage compositor on tty1
    services.cage = {
      enable = true;
      user = cfg.user;
      program = "${kioskRunner}/bin/kiosk-runner";
      extraArguments = [ "-s" ]; # -s enables DPMS monitor power management
    };

    # Automatic recovery if the application exits or crashes
    systemd.services."cage-tty1".serviceConfig = {
      Restart = "always";
      RestartSec = "2s";
    };
  };
}
