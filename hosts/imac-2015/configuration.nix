{ pkgs, ... }:

{
  base.enable = true;
  nixpkgs.config.allowUnfree = true;

  # Target SATA disk
  diskConfig.device = "/dev/sda";

  # Child kiosk setup
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

  # Primary kiosk user with autologin
  users.users.leo = {
    isNormalUser = true;
    description = "Leo";
    initialPassword = "changeme";
    extraGroups = [ "video" "audio" "input" ];
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = "leo";
  };
}
