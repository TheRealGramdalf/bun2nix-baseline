{ lib, flake-parts-lib, ... }:
let
  inherit (flake-parts-lib) mkPerSystemOption;
  inherit (lib) mkOption types;
in
{
  options.perSystem = mkPerSystemOption {
    options.mkDerivation.hook = mkOption {
      description = ''
        Genric setup hook for building `bun2nix`
        packages.

        Requires that `bunDeps` be set to
        the output of `fetchBunDeps`, then
        sets up bun's cache to be ready for 
        building in the nix sandbox.
      '';
      type = types.package;
    };
  };

  config.perSystem =
    { pkgs, config, ... }:
    {
      mkDerivation.hook = pkgs.makeSetupHook {
        name = "bun2nix-hook";
        propagatedBuildInputs = with config; [
          mkDerivation.bun2nixNoOp
          (pkgs.bun.overrideAttrs {
            passthru.sources."x86_64-linux" = pkgs.fetchurl {
              url = "https://github.com/oven-sh/bun/releases/download/bun-v1.3.13/bun-linux-x64-baseline.zip";
              hash = "sha256-nYokKSpwaAkCBdqsCloiP19pc29Sh+N7+I07QDHtx1A=";
            };
          })
          pkgs.yq-go
        ];
        substitutions = {
          resolveCatalogTs = ./resolve-catalog.ts;
          bunDefaultInstallFlags =
            if pkgs.stdenv.hostPlatform.isDarwin then
              [
                "--linker=isolated"
                "--backend=symlink"
              ]
            else
              [
                "--linker=isolated"
              ];
        };
      } ./hook.sh;
    };
}
