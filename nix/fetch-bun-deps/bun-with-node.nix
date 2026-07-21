{ lib, flake-parts-lib, ... }:
let
  inherit (flake-parts-lib) mkPerSystemOption;
  inherit (lib) mkOption types;
in
{
  options.perSystem = mkPerSystemOption {
    options.fetchBunDeps.bunWithNode = mkOption {
      description = ''
        Copy of nixpkgs's bun package containing an extra
        binary `node` which aliases to the `bun` binary output
        of the original package
      '';
      type = types.functionTo types.package;
    };
  };

  config.perSystem =
    { pkgs, ... }:
    let
      bun = pkgs.bun.overrideAttrs {
          passthru.sources."x86_64-linux" = pkgs.fetchurl {
            url = "https://github.com/oven-sh/bun/releases/download/bun-v1.3.13/bun-linux-x64-baseline.zip";
            hash = "sha256-nYokKSpwaAkCBdqsCloiP19pc29Sh+N7+I07QDHtx1A=";
          };
        };
    in
    {
      fetchBunDeps.bunWithNode =
        {
          useFakeNode ? true,
          ...
        }:
        if useFakeNode then
          pkgs.stdenvNoCC.mkDerivation {
            name = "bun-with-fake-node";

            dontUnpack = true;
            dontBuild = true;

            installPhase = ''
              cp -r "${bun}/." "$out"
              chmod u+w "$out/bin"

              for node_binary in "node" "npm" "npx"; do
                ln -s "$out/bin/bun" "$out/bin/$node_binary"
              done
            '';
          }
        else
          pkgs.symlinkJoin {
            name = "bun-with-real-node";
            paths = with pkgs; [
              bun
              nodejs
            ];
          };
    };
}
