{ ... }:

{
  base.enable = true;
  nixpkgs.config.allowUnfree = true;

  # Målhårddisk för installationen
  diskConfig.device = "/dev/nvme0n1";

  # Aktiverade profiler och miljöer
  profiles.workstation.enable = true;
  features.hyprland.enable = true;
  features.dev.enable = true;
  features.streaming.enable = true;
}
