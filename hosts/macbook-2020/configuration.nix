{ ... }:

{
  base.enable = true;
  nixpkgs.config.allowUnfree = true;

  # Target NVMe disk for Disko
  diskConfig.device = "/dev/nvme0n1";

  # Workstation profile with GNOME desktop environment
  profiles.workstation.enable = true;
  features.gnome.enable = true;
  features.dev.enable = true;
  features.streaming.enable = true;

  # Primary desktop user
  users.users.natasha = {
    isNormalUser = true;
    description = "Natasha";
    extraGroups = [ "networkmanager" "video" "audio" "input" ];
  };

  # Automatic login into GNOME session
  services.displayManager.autoLogin = {
    enable = true;
    user = "natasha";
  };
}
