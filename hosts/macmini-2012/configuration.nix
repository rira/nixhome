{ pkgs, ... }:

{
  base.enable = true;
  nixpkgs.config.allowUnfree = true;

  # Target disk for internal SATA SSD
  diskConfig.device = "/dev/sda";

  # Features
  features.streaming.enable = true;
  features.kiosk.enable = true;

  # Hardware acceleration for Intel HD Graphics 4000 (H.264 decoding for Moonlight)
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-vaapi-driver
      libvdpau-va-gl
    ];
  };

  # Allow proprietary firmware for Broadcom Wi-Fi / Bluetooth
  hardware.enableRedistributableFirmware = true;

  # Prevent machine from sleeping during streaming sessions
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # Local user for TV/Media
  users.users.media = {
    isNormalUser = true;
    description = "Media Center";
    initialPassword = "media";
    extraGroups = [ "video" "audio" "input" ];
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = "media";
  };
}
