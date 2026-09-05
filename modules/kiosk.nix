{ config, lib, pkgs, ... }:

let
  cfg = config.features.kiosk;

  kioskRunner = pkgs.writeShellScriptBin "kiosk-runner" ''
    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
    export QT_QPA_PLATFORM="wayland"
    export SDL_VIDEODRIVER="wayland"
    export NO_AT_BRIDGE=1

    # Wait briefly for Cage compositor socket to become available
    while [ -z "$WAYLAND_DISPLAY" ] || [ ! -e "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]; do
      sleep 0.1
    done

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
    users.users.${cfg.user} = {
      isNormalUser = true;
      extraGroups = [ "video" "audio" "input" ];
      initialPassword = "kiosk";
    };

    services.cage = {
      enable = true;
      user = cfg.user;
      program = "${kioskRunner}/bin/kiosk-runner";
      extraArguments = [ "-s" ];
    };

    # Direct logs to journald and keep kiosk running
    systemd.services."cage-tty1".serviceConfig = {
      StandardOutput = "journal";
      StandardError = "journal";
      Restart = "always";
      RestartSec = "2s";
    };
  };
}
