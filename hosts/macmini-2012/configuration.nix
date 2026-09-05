{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  base.enable = true;
  nixpkgs.config.allowUnfree = true;

  # Disko should not manage partitions on this host
  diskConfig.enable = false;

  # Required for Mac mini 2011/2012: prevents freezes and lets i915 load
  boot.kernelParams = [ "acpi_osi=Darwin" ];

  # Streaming kiosk features
  features.streaming.enable = true;
  features.audio.enable = true;
  features.kiosk = {
    enable = true;
    user = "liam";
  };

  # Ensure graphical target is default on boot
  systemd.defaultUnit = "graphical.target";

  # Hardware acceleration for Intel HD Graphics
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-vaapi-driver
      libvdpau-va-gl
    ];
  };

  # Proprietary firmware for Broadcom Wi-Fi / Bluetooth
  hardware.enableRedistributableFirmware = true;

  # Prevent sleep during streaming sessions
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # Kiosk module handles user creation and groups; add description here
  users.users.liam.description = "Liam";
}
