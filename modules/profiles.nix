{ config, lib, ... }:

let
  cfg = config.profiles;
in
{
  options.profiles = {
    workstation = {
      enable = lib.mkEnableOption "Standard interactive workstation profile";
    };
    kiosk = {
      enable = lib.mkEnableOption "Dedicated fullscreen streaming client profile";
    };
  };

  config = lib.mkMerge [
    # Workstation profile
    (lib.mkIf cfg.workstation.enable {
      features.apps = {
        browsers = lib.mkDefault true;
        spotify = lib.mkDefault true;
        media = lib.mkDefault true;
        productivity = lib.mkDefault true;
        communication = lib.mkDefault true;
      };
    })

    # Kiosk profile
    (lib.mkIf cfg.kiosk.enable {
      features.kiosk.enable = lib.mkDefault true;
      features.streaming.enable = lib.mkDefault true;
    })
  ];
}
