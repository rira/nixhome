{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.features.waybar;
in
{
  options.features.waybar = {
    enable = lib.mkEnableOption "Waybar status bar";
  };

  config = lib.mkIf cfg.enable {
    programs.waybar.enable = true;

    # Icon font packages
    fonts.packages = with pkgs; [
      nerd-fonts.symbols-only
      font-awesome
    ];

    # System utilities
    environment.systemPackages = with pkgs; [
      wireplumber
      brightnessctl
      pavucontrol
      blueman
      trayscale
    ];

    # Waybar layout configuration
    environment.etc."xdg/waybar/config.jsonc".text = ''
      {
        "layer": "top",
        "position": "top",
        "height": 34,
        "spacing": 6,
        "modules-left": ["hyprland/workspaces"],
        "modules-center": ["clock"],
        "modules-right": [
          "pulseaudio",
          "pulseaudio#microphone",
          "backlight",
          "bluetooth",
          "battery",
          "network",
          "tray"
        ],

        "hyprland/workspaces": {
          "disable-scroll": true,
          "all-outputs": true,
          "format": "{name}"
        },

        "clock": {
          "format": "{:%Y-%m-%d %H:%M}",
          "tooltip-format": "<tt><small>{calendar}</small></tt>"
        },

        "pulseaudio": {
          "format": "{icon} {volume}%",
          "format-muted": "󰝟 Muted",
          "format-icons": {
            "default": ["", "", ""]
          },
          "on-click": "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
          "on-click-right": "${pkgs.pavucontrol}/bin/pavucontrol"
        },

        "pulseaudio#microphone": {
          "format": "{format_source}",
          "format-source": " {volume}%",
          "format-source-muted": " Muted",
          "on-click": "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",
          "on-scroll-up": "${pkgs.wireplumber}/bin/wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SOURCE@ 5%+",
          "on-scroll-down": "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%-"
        },

        "backlight": {
          "format": "☀ {percent}%",
          "on-scroll-up": "${pkgs.brightnessctl}/bin/brightnessctl set 5%+",
          "on-scroll-down": "${pkgs.brightnessctl}/bin/brightnessctl set 5%-"
        },

        "bluetooth": {
          "format": " {status}",
          "format-disabled": "󰂲 Off",
          "format-connected": " {device_alias}",
          "format-connected-battery": " {device_alias} {device_battery_percentage}%",
          "tooltip-format": "{controller_alias}\t{controller_address}\n\n{num_connections} connected",
          "tooltip-format-connected": "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}",
          "tooltip-format-enumerate-connected": "{device_alias}\t{device_address}",
          "tooltip-format-enumerate-connected-battery": "{device_alias}\t{device_address}\t({device_battery_percentage}%)",
          "on-click": "blueman-manager"
        },

        "battery": {
          "bat": "BAT0",
          "interval": 30,
          "states": {
            "warning": 30,
            "critical": 15
          },
          "format": "{icon} {capacity}%",
          "format-charging": "󰂄 {capacity}%",
          "format-plugged": " {capacity}%",
          "format-icons": ["󰂃", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
        },

        "network": {
          "format-wifi": " {signalStrength}%",
          "format-ethernet": "󰈀 {ipaddr}",
          "format-disconnected": "󰤮 Disconnected",
          "tooltip-format-wifi": "{essid} ({signalStrength}%) \nIP: {ipaddr}\nGateway: {gwaddr}",
          "tooltip-format-ethernet": "{ifname} 󰈀\nIP: {ipaddr}\nGateway: {gwaddr}",
          "tooltip-format-disconnected": "Disconnected"
        },

        "tray": {
          "spacing": 10
        }
      }
    '';

    # Waybar Catppuccin styling
    environment.etc."xdg/waybar/style.css".text = ''
      * {
        font-family: "Symbols Nerd Font", "Font Awesome 6 Free", Sans-Serif;
        font-size: 13px;
        font-weight: bold;
        border: none;
        border-radius: 0;
        min-height: 0;
      }

      window#waybar {
        background-color: rgba(30, 30, 46, 0.92);
        color: #cdd6f4;
        border-bottom: 2px solid #313244;
      }

      #workspaces button {
        padding: 0 8px;
        color: #6c7086;
        background: transparent;
      }

      #workspaces button.active {
        color: #89b4fa;
        border-bottom: 2px solid #89b4fa;
      }

      #clock,
      #pulseaudio,
      #pulseaudio.microphone,
      #backlight,
      #bluetooth,
      #battery,
      #network,
      #tray {
        padding: 2px 10px;
        margin: 4px 2px;
        border-radius: 6px;
        background-color: #313244;
        color: #cdd6f4;
      }

      #bluetooth.disabled {
        background-color: #45475a;
        color: #a6adc8;
      }

      #bluetooth.connected {
        background-color: #89b4fa;
        color: #11111b;
      }

      #network.disconnected {
        background-color: #f38ba8;
        color: #11111b;
      }

      /* Microphone mute alerts */
      #pulseaudio.microphone.source-muted {
        background-color: #f38ba8;
        color: #11111b;
      }

      #battery.warning {
        background-color: #fab387;
        color: #11111b;
      }

      #battery.critical {
        background-color: #f38ba8;
        color: #11111b;
      }
    '';
  };
}
