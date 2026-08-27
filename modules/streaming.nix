{ config, lib, pkgs, ... }:

let
  cfg = config.features.streaming;
in
{
  options.features.streaming = {
    enable = lib.mkEnableOption "Moonlight game streaming client and low-latency audio stack";
  };

  config = lib.mkIf cfg.enable {
    # Hardware video decoding acceleration (VA-API / Intel QuickSync)
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver   # Broadwell and newer (EliteBook, iMac 2015, MacBook 2020)
        intel-vaapi-driver   # Ivy Bridge and Haswell (Mac Mini 2012)
        libvdpau-va-gl
      ];
    };

    # Low-latency PipeWire audio stack with real-time priority
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    environment.systemPackages = [ pkgs.moonlight-qt ];
  };
}
