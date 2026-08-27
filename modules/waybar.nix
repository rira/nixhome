{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.features.waybar;

  # Script to detect any active WireGuard interface
  wireguardStatusScript = pkgs.writeShellScript "waybar-wireguard-status" ''
    WG_DEV=$(${pkgs.iproute2}/bin/ip -br link show type wireguard 2>/dev/null | ${pkgs.gawk}/bin/awk '{print $1}' | head -n 1)
    if [ -n "$WG_DEV" ]; then
      WG_IP=$(${pkgs.iproute2}/bin/ip -br addr show dev "$WG_DEV" 2>/dev/null | ${pkgs.gawk}/bin/awk '{print $3}')
      echo "{\"text\":\"󰖂 VPN\",\"class\":\"connected\",\"tooltip\":\"WireGuard ($WG_DEV): $WG_IP\"}"
    else
      echo "{\"text\":\"\",\"class\":\"disconnected\",\"tooltip\":\"WireGuard: Disconnected\"}"
    fi
  '';
in
{
  options.features.waybar = {
    enable = lib.mkEnableOption "Waybar status bar configuration";
  };

  config = lib.mkIf cfg.enable {
    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      font-awesome
    ];

    programs.waybar = {
      enable = true;
      package = pkgs.waybar;
    };

    # Waybar JSONC configuration
    environment.etc."xdg/waybar/config.jsonc".text = builtins.toJSON {
      layer = "top";
      position = "top";
      height = 36;
      spacing = 6;
      margin-top = 6;
      margin-left = 10;
      margin-right = 10;

      modules-left = [
        "hyprland/workspaces"
        "hyprland/window"
      ];

      modules-center = [
        "clock"
      ];

      modules-right = [
        "pulseaudio"
        "network"
        "custom/wireguard"
        "cpu"
        "memory"
        "battery"
        "tray"
      ];

      "hyprland/workspaces" = {
        disable-scroll = true;
        all-outputs = true;
        format = "{name}";
        on-click = "activate";
      };

      "hyprland/window" = {
        max-length = 40;
        separate-outputs = true;
      };

      "clock" = {
        format = " {:%H:%M}";
        format-alt = " {:%Y-%m-%d   %H:%M}";
        tooltip-format = "<tt><small>{calendar}</small></tt>";
      };

      "cpu" = {
        format = " {usage}%";
        tooltip = true;
        interval = 2;
      };

      "memory" = {
        format = " {}%";
        interval = 2;
      };

      "battery" = {
        states = {
          good = 95;
          warning = 30;
          critical = 15;
        };
        format = "{icon} {capacity}%";
        format-charging = " {capacity}%";
        format-plugged = " {capacity}%";
        format-alt = "{icon} {capacity}% ({time})";
        format-icons = [ "󰁺" "󰁼" "󰁾" "󰂀" "󰂂" ];
        tooltip-format = "{timeTo}\nPower draw: {power}W\nHealth: {health}%";
        interval = 5;
      };

      "network" = {
        format-wifi = " {signalStrength}%";
        format-ethernet = "󰈀 {ipaddr}";
        format-disconnected = "⚠ Disconnected";
        tooltip-format = "{ifname} via {gwaddr}";
      };

      # Custom dynamic WireGuard indicator
      "custom/wireguard" = {
        exec = "${wireguardStatusScript}";
        return-type = "json";
        interval = 3;
        format = "{}";
      };

      "pulseaudio" = {
        format = "{icon} {volume}%";
        format-muted = "󰝟 Muted";
        format-icons = {
          default = [ "" "" "" ];
        };
        on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
      };

      "tray" = {
        icon-size = 18;
        spacing = 10;
      };
    };

    # Capsule styling
    environment.etc."xdg/waybar/style.css".text = ''
      * {
        border: none;
        border-radius: 0;
        font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free", sans-serif;
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background-color: transparent;
        color: #cdd6f4;
      }

      #workspaces {
        background-color: rgba(30, 30, 46, 0.85);
        margin: 0 4px;
        padding: 2px 6px;
        border-radius: 12px;
      }

      #workspaces button {
        padding: 0 8px;
        color: #6c7086;
        border-radius: 8px;
      }

      #workspaces button.active {
        color: #cdd6f4;
        background-color: rgba(137, 180, 250, 0.25);
      }

      #workspaces button.urgent {
        color: #f38ba8;
      }

      #window,
      #clock,
      #pulseaudio,
      #network,
      #custom-wireguard,
      #cpu,
      #memory,
      #battery,
      #tray {
        background-color: rgba(30, 30, 46, 0.85);
        padding: 4px 12px;
        margin: 0 4px;
        border-radius: 12px;
      }

      #clock {
        color: #cdd6f4;
        font-weight: bold;
      }

      #custom-wireguard {
        color: #a6e3a1;
      }

      #battery {
        color: #a6e3a1;
      }

      #battery.warning {
        color: #fab387;
      }

      #battery.critical {
        color: #f38ba8;
      }

      #battery.charging,
      #battery.plugged {
        color: #94e2d5;
      }

      #pulseaudio {
        color: #89b4fa;
      }

      #network {
        color: #94e2d5;
      }

      #cpu {
        color: #f9e2af;
      }

      #memory {
        color: #cba6f7;
      }
    '';
  };
}
