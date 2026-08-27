{ pkgs, ... }:

{
  base.enable = true;
  nixpkgs.config.allowUnfree = true;

  # Target SATA SSD
  diskConfig.device = "/dev/sda";

  # Streaming kiosk features
  features.streaming.enable = true;
  features.kiosk.enable = true;

  # Hardware acceleration for Intel HD Graphics 4000
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

  # Primary kiosk user with autologin
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
