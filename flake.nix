{
  description = "Central NixOS fleet configuration monorepo";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-hardware,
      disko,
      ...
    }@inputs:
    let
      system = "x86_64-linux";

      mkHost =
        {
          name,
          extraModules ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            hostName = name;
          };
          modules = [
            disko.nixosModules.disko
            ./modules/disko-luks.nix
            ./modules/base.nix
            ./modules/users.nix
            ./modules/dev.nix
            ./modules/apps.nix
            ./modules/profiles.nix
            ./modules/hyprland.nix
            ./modules/waybar.nix
            ./modules/gnome.nix
            ./modules/streaming.nix
            ./modules/kiosk.nix
            ./modules/apple-legacy.nix
            ./hosts/${name}/configuration.nix
          ]
          ++ extraModules;
        };
    in
    {
      nixosConfigurations = {
        # HP EliteBook x360 (Hyprland Workstation)
        elitebook = mkHost {
          name = "elitebook";
        };

        # MacBook Pro 13" 2020 (GNOME Workstation)
        macbook-2020 = mkHost {
          name = "macbook-2020";
        };

        # Mac Mini 2012 A1347 (Moonlight Kiosk)
        macmini-2012 = mkHost {
          name = "macmini-2012";
        };

        # iMac 2015 (Retina GNOME Workstation)
        imac-2015 = mkHost {
          name = "imac-2015";
        };
      };
    };
}
