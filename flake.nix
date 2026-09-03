{
  description = "NixOS config for cncnix - a CNC lathe machine running NixOS";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-linuxcnc.url = "github:wucke13/nixpkgs/dev/wucke13/add-linuxcnc";

    # disko
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      inherit (self) outputs;
      system = "x86_64-linux";
    in
    {
      overlays = import ./overlays { inherit inputs; };
      # nixosModules = import ./modules/nixos;

      nixosConfigurations = {
        cncnix = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            inputs.disko.nixosModules.disko
            ./nixos/configuration.nix
          ];
        };
      };
    };
}
