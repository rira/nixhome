{ ... }:

{
  base.enable = true;
  nixpkgs.config.allowUnfree = true;

  # Target NVMe disk for Disko
  diskConfig.device = "/dev/nvme0n1";

  # Workstation profile with Hyprland desktop environment
  profiles.workstation.enable = true;
  features.hyprland.enable = true;
  features.dev.enable = true;
  features.streaming.enable = true;

  # Automatic login directly into Hyprland session
  services.displayManager.autoLogin = {
    enable = true;
    user = "richard";
  };
}
