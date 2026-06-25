{ pkgs, ... }:
let
  version = "2.0.1";

  assets = {
    x86_64-linux = {
      platform = "linux";
      arch = "amd64";
      hash = "sha256-yLZepX8QoD8CEE677L8SScQfSZvIV3FIiCS3D2zPx2w=";
    };
    aarch64-linux = {
      platform = "linux";
      arch = "arm64";
      hash = "sha256-/+mBG7t3+EQgDwZEuYoItl7i1f/MDitJsd8xcZoKBS8=";
    };
    x86_64-darwin = {
      platform = "darwin";
      arch = "amd64";
      hash = "sha256-arNHY85vRNJc0gxuiH4d4PtPvlWw0HxfQy1yrB9QDv4=";
    };
    aarch64-darwin = {
      platform = "darwin";
      arch = "arm64";
      hash = "sha256-QBCbAU7G/Sj/il0xKPrKcyILj3ccf85iaGfnaa1M0qI=";
    };
  };

  asset = assets.${pkgs.stdenv.hostPlatform.system};

  hauler = pkgs.stdenvNoCC.mkDerivation {
    pname = "hauler";
    inherit version;

    nativeBuildInputs = [
      pkgs.installShellFiles
    ];

    src = pkgs.fetchurl {
      url = "https://github.com/hauler-dev/hauler/releases/download/v${version}/hauler_${version}_${asset.platform}_${asset.arch}.tar.gz";
      inherit (asset) hash;
    };

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall
      install -Dm755 hauler $out/bin/hauler

      $out/bin/hauler completion zsh > _hauler
      installShellCompletion --zsh _hauler

      runHook postInstall
    '';

    meta = {
      description = "Airgap Swiss Army Knife";
      homepage = "https://github.com/hauler-dev/hauler";
      license = pkgs.lib.licenses.asl20;
      mainProgram = "hauler";
      platforms = builtins.attrNames assets;
    };
  };
in
{
  home.packages = [
    hauler
  ];
}
