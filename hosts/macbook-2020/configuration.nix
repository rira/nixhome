{ ... }:

{
  # Enabled features for MacBook Pro
  features.gnome.enable = true;
  features.streaming.enable = true;

  # Standard user account
  users.users.sambo = {
    isNormalUser = true;
    extraGroups = [ "video" "audio" "networkmanager" ];
    description = "Sambo";
  };

  # File system mounts (dummy definitions for build evaluation in WSL)
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };
}
