{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  base.enable = true;
  nixpkgs.config.allowUnfree = true;

  # Disko should not manage partitions on this host
  diskConfig.enable = false;

  # Required for Mac mini 2011 (Sandy Bridge): prevents freezes and lets i915 load
  boot.kernelParams = [ "acpi_osi=Darwin" ];

  # Streaming kiosk features
  features.streaming.enable = true;
  features.kiosk.enable = true;

  # Hardware acceleration for Intel HD Graphics (Sandy Bridge)
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

  # Primary kiosk user with autologin (no sudo/wheel access)
  users.users.liam = {
    isNormalUser = true;
    description = "Liam";
    initialPassword = "changeme";
    extraGroups = [ "video" "audio" "input" ];
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = "liam";
  };
}
