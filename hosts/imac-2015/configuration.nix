{ pkgs, ... }:

{
  base.enable = true;
  nixpkgs.config.allowUnfree = true;

  # Target disk for internal drive
  diskConfig.device = "/dev/sda";

  # Features
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

  # Local user for child kiosk
  users.users.barn = {
    isNormalUser = true;
    description = "Barn";
    initialPassword = "barn";
    extraGroups = [ "video" "audio" "input" ];
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = "barn";
  };
}
