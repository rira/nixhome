{ config, lib, pkgs, ... }:

let
  cfg = config.features.hyprland;

  # Hyprland baseline configuration
  hyprlandDefaultConfig = pkgs.writeText "hyprland.conf" ''
    # Primary modifier: SUPER (Windows key)
    $mainMod = SUPER

    # Monitor layout
    monitor = , preferred, auto, 1

    # Input settings: Swedish keyboard layout
    input {
        kb_layout = se
        follow_mouse = 1
        touchpad {
            natural_scroll = false
        }
    }

    # Autostart essential desktop services
    exec-once = ${pkgs.waybar}/bin/waybar
    exec-once = ${pkgs.kitty}/bin/kitty
    exec-once = ${pkgs.mako}/bin/mako

    # Core window and session management
    bind = $mainMod, Q, exec, ${pkgs.kitty}/bin/kitty
    bind = $mainMod, C, killactive,
    bind = $mainMod, M, exit,
    bind = $mainMod, V, togglefloating,
    bind = $mainMod, R, exec, ${pkgs.rofi}/bin/rofi -show drun
    bind = $mainMod, F, fullscreen, 0

    # Focus navigation (Arrow keys and Vim keys)
    bind = $mainMod, left, movefocus, l
    bind = $mainMod, right, movefocus, r
    bind = $mainMod, up, movefocus, u
    bind = $mainMod, down, movefocus, d
    bind = $mainMod, H, movefocus, l
    bind = $mainMod, L, movefocus, r
    bind = $mainMod, K, movefocus, u
    bind = $mainMod, J, movefocus, d

    # Workspaces 1-5 switching
    bind = $mainMod, 1, workspace, 1
    bind = $mainMod, 2, workspace, 2
    bind = $mainMod, 3, workspace, 3
    bind = $mainMod, 4, workspace, 4
    bind = $mainMod, 5, workspace, 5

    # Move active window to workspace 1-5
    bind = $mainMod SHIFT, 1, movetoworkspace, 1
    bind = $mainMod SHIFT, 2, movetoworkspace, 2
    bind = $mainMod SHIFT, 3, movetoworkspace, 3
    bind = $mainMod SHIFT, 4, movetoworkspace, 4
    bind = $mainMod SHIFT, 5, movetoworkspace, 5
  '';
in
{
  options.features.hyprland = {
    enable = lib.mkEnableOption "Hyprland dynamic tiling Wayland compositor environment";
  };

  config = lib.mkIf cfg.enable {
    # Enable Hyprland compositor
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    # System fallback configuration
    environment.etc."xdg/hypr/hyprland.conf".source = hyprlandDefaultConfig;

    # Typography and icon glyphs
    fonts.packages = with pkgs; [
      font-awesome
      nerd-fonts.jetbrains-mono
      noto-fonts-color-emoji
    ];

    # Lightweight console login manager running the official NixOS wrapper
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd start-hyprland";
          user = "greeter";
        };
      };
    };

    # Elevation agent for GUI auth prompts
    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };

    # Essential Hyprland desktop utilities
    environment.systemPackages = with pkgs; [
      kitty
      waybar
      rofi
      mako
      hyprlock
      hypridle
      wl-clipboard
      libnotify
    ];
  };
}
