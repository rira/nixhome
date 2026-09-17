{ config, lib, pkgs, ... }:

let
  cfg = config.features.dev;
in
{
  options.features.dev = {
    enable = lib.mkEnableOption "Developer tools and environments";
  };

  config = lib.mkIf cfg.enable {
    # Allow execution of unpatched dynamic binaries (agy, language servers, etc.)
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc.lib
        zlib
        openssl
        curl
        glibc
        libxcrypt-legacy
      ];
    };

    # Fast and automatic per-directory Nix flake environment loading
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # Development tools, editor, and CLI utilities
    environment.systemPackages = with pkgs; [
      gh
      ripgrep
      fd
      tree
      neovim
      zed-editor
      gnumake
      gcc
    ];
  };
}
