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

    monitors = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "eDP-1, preferred, auto, 1"
        ", preferred, auto, 1"
      ];
      description = "List of monitor rule lines passed directly to hyprland.conf";
    };
  };

  config = lib.mkIf cfg.enable {
    # Kernel parameters: disable Intel display power-saving throttles
    boot.kernelParams = [
      "i915.enable_psr=0"
      "i915.enable_dc=0"
      "i915.enable_fbc=0"
    ];

    # Enable Hyprland compositor
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    # Automatically enable Waybar when Hyprland is active
    features.waybar.enable = lib.mkDefault true;

    # Hardware permissions for brightness control and audio
    services.udev.packages = [ pkgs.brightnessctl ];
    users.users.richard.extraGroups = [ "video" "audio" "input" ];

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

    # Rofi configuration with "fancy" theme
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

    # Session variables: Wayland, Dark Theme, and Touchscreen gesture support
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
      GTK_THEME = "Adwaita:dark";

      # Touchscreen smooth scrolling & pinch-to-zoom
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_USE_XINPUT2 = "1";
      GDK_BACKEND = "wayland,x11";
      QT_QPA_PLATFORM = "wayland;xcb";
    };

    # Essential GUI tools and hardware utilities
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
      exec-once = nm-applet --indicator &
      exec-once = trayscale --hide-window

      # Clamshell mode at login: check if lid is already closed when booting docked
      exec-once = sh -c "if grep -q closed /proc/acpi/button/lid/*/state 2>/dev/null; then hyprctl keyword monitor 'eDP-1, disable'; fi"

      # --- Monitor Configuration ---
      ${lib.concatMapStringsSep "\n" (m: "monitor = ${m}") cfg.monitors}

      # --- Clamshell Mode Transitions ---
      # Turn off internal display when lid is closed, re-enable when opened
      bindl = , switch:on:Lid Switch, exec, hyprctl keyword monitor "eDP-1, disable"
      bindl = , switch:off:Lid Switch, exec, hyprctl keyword monitor "eDP-1, preferred, auto, 1"

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

      # Screenshot to clipboard
      bind = $mainMod SHIFT, S, exec, grim -g "$(slurp)" - | wl-copy --type image/png

      # System and core application controls
      bind = $mainMod, Return, exec, kitty
      bind = $mainMod, Q, killactive,
      bind = $mainMod, M, exit,
      bind = $mainMod, Space, exec, rofi -show drun

      # System sleep / suspend shortcut
      bind = $mainMod SHIFT, Z, exec, systemctl suspend

      # Fullscreen and floating controls
      bind = $mainMod, F, fullscreen, 0
      bind = $mainMod SHIFT, F, togglefloating,

      # Window focus movement
      bind = $mainMod, left, movefocus, l
      bind = $mainMod, right, movefocus, r
      bind = $mainMod, up, movefocus, u
      bind = $mainMod, down, movefocus, d

      # Window movement
      bind = $mainMod SHIFT, left, movewindow, l
      bind = $mainMod SHIFT, right, movewindow, r
      bind = $mainMod SHIFT, up, movewindow, u
      bind = $mainMod SHIFT, down, movewindow, d

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

      # Smart Airplane mode toggle (rfkill + NetworkManager sync)
      bindl = , XF86RFKill, exec, sh -c "if rfkill list | grep -q 'Soft blocked: yes'; then rfkill unblock all && nmcli radio all on; else rfkill block all; fi"

      # Mouse move & resize
      bindm = $mainMod, mouse:272, movewindow
      bindm = $mainMod, mouse:273, resizewindow
    '';
  };
}
