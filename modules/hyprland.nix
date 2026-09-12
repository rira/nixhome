{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.features.hyprland;

  # Move all windows from active workspace to target workspace, sorted by screen position
  moveAllToWorkspace = pkgs.writeShellScriptBin "hypr-move-all" ''
    TARGET="$1"
    ACTIVE_WS=$(hyprctl activeworkspace -j | ${pkgs.jq}/bin/jq '.id')

    if [ "$ACTIVE_WS" -eq "$TARGET" ]; then
      exit 0
    fi

    # Retrieve and sort window addresses in left-to-right / top-to-bottom spatial order
    WINDOWS=$(hyprctl clients -j | ${pkgs.jq}/bin/jq -r --argjson ws "$ACTIVE_WS" \
      '[.[] | select(.workspace.id == $ws)] | sort_by(.at[0], .at[1]) | .[].address')

    for addr in $WINDOWS; do
      hyprctl dispatch movetoworkspacesilent "$TARGET,address:$addr"
    done

    hyprctl dispatch workspace "$TARGET"
  '';
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

    # Automatically enable Waybar and Audio when Hyprland is active
    features.waybar.enable = lib.mkDefault true;
    features.audio.enable = lib.mkDefault true;

    # Hardware permissions for brightness control and input
    services.udev.packages = [ pkgs.brightnessctl ];
    users.users.richard.extraGroups = [ "video" "audio" "input" ];

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

    # Rofi configuration with "fancy" theme & window switcher
    environment.etc."xdg/rofi/config.rasi".text = ''
      configuration {
        modi: "drun,run,window";
        show-icons: true;
        display-drun: "Apps";
        display-window: "Windows";
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
      brightnessctl
      playerctl
      adwaita-icon-theme
      gnome-themes-extra
      jq
      moveAllToWorkspace
    ];

    # Hyprland base configuration
    environment.etc."xdg/hypr/hyprland.conf".text = ''
      # Autostart environment & background services
      exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
      exec-once = waybar -c /etc/xdg/waybar/config.jsonc -s /etc/xdg/waybar/style.css
      exec-once = swaybg -c "#1e1e2e"
      exec-once = nm-applet --indicator &
      exec-once = trayscale --hide-window

      # Clamshell mode: evaluated at login and on every configuration reload
      exec = sh -c "sleep 1 && if grep -q closed /proc/acpi/button/lid/*/state 2>/dev/null; then hyprctl keyword monitor 'eDP-1, disable'; fi"

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

      dwindle {
        preserve_split = true
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

      # Window switcher menu (Alt + Tab)
      bind = ALT, Tab, exec, rofi -show window

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

      # Relative workspace switching (dynamically creates new workspaces)
      bind = CTRL ALT, right, workspace, +1
      bind = CTRL ALT, left, workspace, -1
      bind = CTRL ALT SHIFT, right, movetoworkspace, +1
      bind = CTRL ALT SHIFT, left, movetoworkspace, -1

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

      # Move all windows to workspace (Super + Ctrl + Shift + 1-6)
      bind = $mainMod CTRL SHIFT, 1, exec, hypr-move-all 1
      bind = $mainMod CTRL SHIFT, 2, exec, hypr-move-all 2
      bind = $mainMod CTRL SHIFT, 3, exec, hypr-move-all 3
      bind = $mainMod CTRL SHIFT, 4, exec, hypr-move-all 4
      bind = $mainMod CTRL SHIFT, 5, exec, hypr-move-all 5
      bind = $mainMod CTRL SHIFT, 6, exec, hypr-move-all 6

      # Audio and brightness controls
      bindel = , XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+
      bindel = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
      bindl  = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
      bindl  = , XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
      bindel = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
      bindel = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
      bindl  = , XF86AudioPlay, exec, playerctl play-pause
      bindl  = , XF86AudioNext, exec, playerctl next
      bindl  = , XF86AudioPrev, exec, playerctl previous

      # Smart Airplane mode toggle (rfkill + NetworkManager sync)
      bindl = , XF86RFKill, exec, sh -c "if rfkill list | grep -q 'Soft blocked: yes'; then rfkill unblock all && nmcli radio all on; else rfkill block all; fi"

      # Mouse window drag & resize
      bindm = $mainMod, mouse:272, movewindow
      bindm = $mainMod, mouse:273, resizewindow
    '';

    # Kitty base configuration (disables paste confirmation dialog)
    environment.etc."xdg/kitty/kitty.conf".text = ''
      paste_actions quote-urls-at-prompt,replace-dangerous-control-codes
    '';
  };
}
