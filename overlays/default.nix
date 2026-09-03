{ inputs, ... }:

{
  additions =
    final: _prev:
    let
      linuxcnc-pkgs = import inputs.nixpkgs-linuxcnc {
        inherit (final.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };
    in
    {
      inherit (linuxcnc-pkgs)
        linuxcnc
        mesaflash
        blt
        ;

      pythonPackagesExtensions = (_prev.pythonPackagesExtensions or [ ]) ++ [
        (_pythonFinal: _pythonPrev: {
          inherit (linuxcnc-pkgs.python3Packages) yapps;
        })
      ];
    };
}
