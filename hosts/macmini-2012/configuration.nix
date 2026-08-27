{ pkgs, ... }:

{
  base.enable = true;
  nixpkgs.config.allowUnfree = true;

  # Target disk for internal SATA SSD
  diskConfig.device = "/dev/sda";

  # Enable streaming and kiosk features
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

  # Prevent the machine from sleeping while acting as a streaming receiver
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;
}
