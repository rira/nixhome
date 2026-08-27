{ pkgs, ... }:

{
  base.enable = true;
  nixpkgs.config.allowUnfree = true;

  # Target disk for internal drive
  diskConfig.device = "/dev/sda";

  # Child kiosk setup: autostart streaming / media interface
  features.kiosk.enable = true;
  features.streaming.enable = true;

  # Hardware acceleration for graphics (VA-API / Mesa)
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-vaapi-driver
      libvdpau-va-gl
    ];
  };

  # Proprietary firmware for Broadcom Wi-Fi and Bluetooth
  hardware.enableRedistributableFirmware = true;

  # Prevent screen lock or suspension during use
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
}
