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

  # Primary workstation user
  users.users.richard = {
    isNormalUser = true;
    description = "Richard";
    initialPassword = "changeme";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
    ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBFMhAwmth99uLCtyQx9qr/oQn1nRfQY5vpTnpLFBacL"
    ];
  };

  # Passwordless sudo for local admin tasks
  security.sudo.wheelNeedsPassword = false;

  # Automatic login directly into Hyprland session
  services.displayManager.autoLogin = {
    enable = true;
    user = "richard";
  };

  services.fprintd.enable = true;
}
