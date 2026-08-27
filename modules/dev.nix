{ config, lib, pkgs, ... }:

let
  cfg = config.features.dev;
in
{
  options.features.dev = {
    enable = lib.mkEnableOption "Developer tools and environments";
  };

  config = lib.mkIf cfg.enable {
    # Snabb och automatisk laddning av Nix-flakemiljöer per katalog
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # Utvecklingsverktyg och CLI-hjälpmedel
    environment.systemPackages = with pkgs; [
      gh
      ripgrep
      fd
      tree
      neovim
      gnumake
      gcc
    ];
  };
}
