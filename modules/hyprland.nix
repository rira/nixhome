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

    # Dark mode defaults for GTK 3 & GTK 4 applications
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

    # Rofi configuration using the built-in "fancy" theme
    environment.etc."xdg/rofi/config.rasi".text = ''
      configuration {
        modi: "drun,run";
        show-icons: true;
        display-drun: "Apps";
        drun-display-format: "{name}";
      }

      @theme "fancy"
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

    # Essential GUI and hardware control tools
    environment.systemPackages = with pkgs; [
      kitty
      rofi
      swaybg
      wl-clipboard
      pavucontrol
      brightnessctl
      playerctl
      adwaita-icon-theme
      gnome-themes-extra
    ];

    # Hyprland base configuration
    environment.etc."xdg/hypr/hyprland.conf".text = ''
      # Autostart environment & background services
      exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
      exec-once = waybar -c /etc/xdg/waybar/config.jsonc -s /etc/xdg/waybar/style.css
      exec-once = swaybg -c "#1e1e2e"

      # Monitor configuration
      monitor=,preferred,auto,1

      # Keyboard layout & touchpad
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

      # System and core application controls
      bind = $mainMod, Return, exec, kitty
      bind = $mainMod, Q, killactive,
      bind = $mainMod, M, exit,
      bind = $mainMod, Space, exec, rofi -show drun
      bind = $mainMod, F, togglefloating,

      # Window focus movement
      bind = $mainMod, left, movefocus, l
      bind = $mainMod, right, movefocus, r
      bind = $mainMod, up, movefocus, u
      bind = $mainMod, down, movefocus, d

      # Relative workspace switching (Ctrl + Alt + Left/Right)
      bind = CTRL ALT, right, workspace, e+1
      bind = CTRL ALT, left, workspace, e-1

      # Move active window to next/previous workspace
      bind = CTRL ALT SHIFT, right, movetoworkspace, e+1
      bind = CTRL ALT SHIFT, left, movetoworkspace, e-1

      # Direct workspace switching (Super + 1-6)
      bind = $mainMod, 1, workspace, 1
      bind = $mainMod, 2, workspace, 2
      bind = $mainMod, 3, workspace, 3
      bind = $mainMod, 4, workspace, 4
      bind = $mainMod, 5, workspace, 5
      bind = $mainMod, 6, workspace, 6

      # Move window directly to workspace (Super + Shift + 1-6)
      bind = $mainMod SHIFT, 1, movetoworkspace, 1
      bind = $mainMod SHIFT, 2, movetoworkspace, 2
      bind = $mainMod SHIFT, 3, movetoworkspace, 3
      bind = $mainMod SHIFT, 4, movetoworkspace, 4
      bind = $mainMod SHIFT, 5, movetoworkspace, 5
      bind = $mainMod SHIFT, 6, movetoworkspace, 6

      # Volume control (PipeWire / WirePlumber)
      bindel = , XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+
      bindel = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
      bindl  = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      bindl  = , XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

      # Screen brightness control
      bindel = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
      bindel = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

      # Media playback controls
      bindl = , XF86AudioPlay, exec, playerctl play-pause
      bindl = , XF86AudioNext, exec, playerctl next
      bindl = , XF86AudioPrev, exec, playerctl previous

      # Mouse move & resize
      bindm = $mainMod, mouse:272, movewindow
      bindm = $mainMod, mouse:273, resizewindow
    '';
  };
}
