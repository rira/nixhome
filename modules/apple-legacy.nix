{ config, lib, pkgs, ... }:

let
  cfg = config.hardwareFixes.appleLegacy;
in
{
  options.hardwareFixes.appleLegacy = {
    enable = lib.mkEnableOption "Hardware quirks and thermal daemons for legacy Apple machines";
  };

  config = lib.mkIf cfg.enable {
    # Allow unfree packages required for proprietary Broadcom STA drivers
    nixpkgs.config.allowUnfree = true;

    # Broadcom out-of-tree kernel module
    boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
    boot.kernelModules = [ "wl" ];

    # Blacklist conflicting in-tree open-source drivers
    boot.blacklistedKernelModules = [ "b43" "bcma" "brcmsmac" "brcmfmac" ];

    # Apple SMC fan control daemon for proper thermal curve handling
    services.mbpfan = {
      enable = true;
      settings = {
        general = {
          min_fan1_speed = 1200;
          max_fan1_speed = 6000;
          low_temp = 55;
          high_temp = 70;
          max_temp = 85;
        };
      };
    };
  };
}
