{ config, lib, pkgs, ... }:

let
  cfg = config.features.gnome;
in
{
  options.features.gnome = {
    enable = lib.mkEnableOption "GNOME Desktop Environment on Wayland";
  };

  config = lib.mkIf cfg.enable {
    # Display manager (GDM) and Desktop manager (GNOME) on Wayland
    services.xserver.enable = true;
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;

    # Exclude default bloat applications if desired
    environment.gnome.excludePackages = with pkgs; [
      gnome-tour
      geary
      epiphany
    ];
  };
}
