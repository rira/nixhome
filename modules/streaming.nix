{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.features.streaming;
in
{
  options.features.streaming = {
    enable = lib.mkEnableOption "Streaming and pro-audio processing suite";
  };

  config = lib.mkIf cfg.enable {
    # Packages for mic processing, DSP routing, and broadcast
    environment.systemPackages = with pkgs; [
      moonlight-qt  # Game streaming client for duo/sunshine
      easyeffects   # DSP effects (noise gate, compressor, EQ for Elgato Wave XLR)
      qpwgraph      # Visual PipeWire patchbay for audio routing
      obs-studio    # Video recording and live streaming
      pavucontrol   # PulseAudio/PipeWire volume control interface
    ];
  };
}
