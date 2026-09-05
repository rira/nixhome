{ config, lib, pkgs, ... }:

let
  cfg = config.features.audio;
in
{
  options.features.audio = {
    enable = lib.mkEnableOption "PipeWire audio stack with WirePlumber and ALSA/Pulse emulation";
  };

  config = lib.mkIf cfg.enable {
    # Disable PulseAudio daemon to prevent socket collisions
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };

    # CLI tools and mixer controls in PATH
    environment.systemPackages = with pkgs; [
      wireplumber # Provides wpctl
      pavucontrol
    ];
  };
}
