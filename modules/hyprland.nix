{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.features.hyprland;
in
{
  options.features.hyprland = {
    enable = lib.mkEnableOption "Hyprland desktop environment";
  };

  config = lib.mkIf cfg.enable {
    # Enable Hyprland compositor
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    # Automatically enable Waybar when Hyprland is active
    features.waybar.enable = lib.mkDefault true;

    # Enable PipeWire audio stack
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    # Enable dconf to handle desktop settings and themes
    programs.dconf = {
      enable = true;
      profiles.user.databases = [
        {
          settings = {
            "org/gnome/desktop/interface" = {
              color-scheme = "prefer-dark";
              gtk-theme = "Adwaita-dark";
            };
          };
        }
      ];
    };

    # Dark mode defaults for GTK 3 & GTK 4 applications (pavucontrol, file managers)
    environment.etc."xdg/gtk-3.0/settings.ini".text = ''
      [Settings]
      gtk-application-prefer-dark-theme=1
      gtk-theme-name=Adwaita-dark
    '';

    environment.etc."xdg/gtk-4.0/settings.ini".text = ''
      [Settings]
      gtk-application-prefer-dark-theme=1
      gtk-theme-name=Adwaita-dark
    '';

    # Automatic login directly into Hyprland
    services.greetd = {
      enable = true;
      settings = {
        initial_session = {
          command = "start-hyprland";
          user = "richard";
        };
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd start-hyprland";
          user = "greeter";
        };
      };
    };

    # Session variables for Wayland and dark theme enforcement
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
      GTK_THEME = "Adwaita:dark";
    };

    # Essential GUI tools
    environment.systemPackages = with pkgs; [
      kitty
      rofi
      swaybg
      wl-clipboard
      pavucontrol
      adwaita-icon-theme
      gnome-themes-extra
    ];

    # Hyprland base configuration
    environment.etc."xdg/hypr/hyprland.conf".text = ''
      # Autostart bar and background
      exec-once = waybar -c /etc/xdg/waybar/config.jsonc -s /etc/xdg/waybar/style.css
      exec-once = swaybg -c "#1e1e2e"

      # Monitor configuration
      monitor=,preferred,auto,1

      # Keyboard layout
      input {
        kb_layout = se,us
        follow_mouse = 1
        touchpad {
          natural_scroll = true
        }
      }

      # Window styling
      general {
        gaps_in = 4
        gaps_out = 8
        border_size = 2
        col.active_border = rgba(89b4faff) rgba(cba6f7ff) 45deg
        col.inactive_border = rgba(585b70aa)
        layout = dwindle
      }

      decoration {
        rounding = 10
        blur {
          enabled = true
          size = 3
          passes = 1
        }
      }

      # Keybindings (Super = Windows key)
      $mainMod = SUPER

      bind = $mainMod, Return, exec, kitty
      bind = $mainMod, Q, killactive,
      bind = $mainMod, M, exit,
      bind = $mainMod, Space, exec, rofi -show drun
      bind = $mainMod, F, togglefloating,

      # Focus movement
      bind = $mainMod, left, movefocus, l
      bind = $mainMod, right, movefocus, r
      bind = $mainMod, up, movefocus, u
      bind = $mainMod, down, movefocus, d

      # Workspaces 1-6
      bind = $mainMod, 1, workspace, 1
      bind = $mainMod, 2, workspace, 2
      bind = $mainMod, 3, workspace, 3
      bind = $mainMod, 4, workspace, 4
      bind = $mainMod, 5, workspace, 5
      bind = $mainMod, 6, workspace, 6

      bind = $mainMod SHIFT, 1, movetoworkspace, 1
      bind = $mainMod SHIFT, 2, movetoworkspace, 2
      bind = $mainMod SHIFT, 3, movetoworkspace, 3
      bind = $mainMod SHIFT, 4, movetoworkspace, 4

      # Mouse move & resize
      bindm = $mainMod, mouse:272, movewindow
      bindm = $mainMod, mouse:273, resizewindow
    '';
  };
}
