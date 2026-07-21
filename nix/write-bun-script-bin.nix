{ lib, flake-parts-lib, ... }:
let
  inherit (flake-parts-lib) mkPerSystemOption;
  inherit (lib) mkOption types;
in
{
  options.perSystem = mkPerSystemOption {
    options.writeBunScriptBin = mkOption {
      description = ''
        Bun $ Shell Script Writer

        Similar to `pkgs.writeScriptBin`, but instead
        of a bash script, creates a
        [bun $ shell](https://bun.com/docs/runtime/shell)
        script.
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
      writeBunScriptBin =
        {
          name,
          text,
        }:
        pkgs.writeTextFile {
          inherit name;
          text = ''
            #!${bun}/bin/bun
            ${text}
          '';
          executable = true;
          destination = "/bin/${name}";
        };
    };
}
