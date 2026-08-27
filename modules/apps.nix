{ config, lib, pkgs, ... }:

let
  cfg = config.features.apps;
in
{
  options.features.apps = {
    spotify = lib.mkEnableOption "Spotify desktop music streaming client";
    browsers = lib.mkEnableOption "Standard web browser (Firefox)";
    media = lib.mkEnableOption "Media playback utility (VLC)";
    productivity = lib.mkEnableOption "Productivity and knowledge management tools (Obsidian)";
    communication = lib.mkEnableOption "Communication tools (Discord, Slack & Telegram)";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.spotify {
      environment.systemPackages = [ pkgs.spotify ];
      networking.firewall.allowedTCPPorts = [ 57621 ];
      networking.firewall.allowedUDPPorts = [ 5353 ];
    })

    (lib.mkIf cfg.browsers {
      environment.systemPackages = [
        pkgs.firefox
      ];
    })

    (lib.mkIf cfg.media {
      environment.systemPackages = [
        pkgs.vlc
      ];
    })

    (lib.mkIf cfg.productivity {
      environment.systemPackages = [
        pkgs.obsidian
      ];
    })

    (lib.mkIf cfg.communication {
      environment.systemPackages = with pkgs; [
        discord
        slack
        telegram-desktop
      ];
    })
  ];
}
