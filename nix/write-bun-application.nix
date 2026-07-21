{ lib, flake-parts-lib, ... }:
let
  inherit (flake-parts-lib) mkPerSystemOption;
  inherit (lib) mkOption types;
in
{
  options.perSystem = mkPerSystemOption {
    options.writeBunApplication = mkOption {
      description = ''
        Bun Application Builder

        Used to create an executable for a project which
        running requires:
        - A `bun install`
        - Running some command from package.json
      '';
      type = types.functionTo types.package;
    };
  };

  config.perSystem =
    { pkgs, config, ... }:
    {
      writeBunApplication = lib.extendMkDerivation {
        constructDrv = config.mkDerivation.function;

        excludeDrvArgNames = [
          "startScript"
          "runtimeInputs"
          "runtimeEnv"
          "excludeShellChecks"
          "extraShellCheckFlags"
          "bashOptions"
          "inheritPath"
        ];

        extendDrvArgs =
          _finalAttrs:
          {
            startScript,
            runtimeInputs ? [ ],
            runtimeEnv ? { },
            excludeShellChecks ? [ ],
            extraShellCheckFlags ? [ ],
            bashOptions ? [
              "errexit"
              "nounset"
              "pipefail"
            ],
            inheritPath ? true,
            nativeBuildInputs ? [ ],
            ...
          }@args:
          let
            script = pkgs.writeShellApplication {
              inherit
                runtimeEnv
                excludeShellChecks
                extraShellCheckFlags
                bashOptions
                inheritPath
                ;

              name = "bun2nix-application-startup";
              text = startScript;
              runtimeInputs = [
                (pkgs.bun.overrideAttrs {
                  passthru.sources."x86_64-linux" = pkgs.fetchurl {
                    url = "https://github.com/oven-sh/bun/releases/download/bun-v1.3.13/bun-linux-x64-baseline.zip";
                    hash = "sha256-nYokKSpwaAkCBdqsCloiP19pc29Sh+N7+I07QDHtx1A=";
                  };
                })
              ]
              ++ runtimeInputs;
            };
          in
          {
            nativeBuildInputs = [
              pkgs.makeWrapper
            ]
            ++ nativeBuildInputs;

            installPhase =
              args.installPhase or ''
                runHook preInstall

                mkdir -p \
                  "$out/share/$pname" \
                  "$out/bin"

                cp -r ./. "$out/share/$pname"

                makeWrapper ${lib.getExe script} $out/bin/$pname \
                  --chdir "$out/share/$pname"

                runHook postInstall
              '';
          };
      };
    };
}
