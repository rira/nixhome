{ pkgs, ... }:

{
  base.enable = true;
  hardware.enableRedistributableFirmware = true;
  nixpkgs.config.allowUnfree = true;

  # Target NVMe disk for Disko
  diskConfig.device = "/dev/nvme0n1";

  # Workstation profile and feature flags
  profiles.workstation.enable = true;
  features.dev.enable = true;
  features.streaming.enable = true;

  # Hyprland setup with host-specific monitor layout
  features.hyprland = {
    enable = true;
    monitors = [
      # External LG UltraGear display locked to 1440p @ 144Hz via EDID description
      "desc:LG Electronics LG ULTRAGEAR 109NTHM7G001, 2560x1440@144, 0x0, 1"

      # Internal laptop display (active when lid is open)
      "eDP-1, preferred, auto, 1"

      # Fallback for unlisted displays
      ", preferred, auto, 1"
    ];
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Automatic login directly into Hyprland session
  services.displayManager.autoLogin = {
    enable = true;
    user = "richard";
  };

  services.fprintd.enable = true;
}
