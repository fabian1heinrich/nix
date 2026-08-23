{ pkgs, ... }:
let
  cacheClean = pkgs.writeShellApplication {
    name = "cache-clean";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      gawk
    ];
    text = builtins.readFile ../scripts/cache-clean.sh;
  };
in
{
  home.packages = [ cacheClean ];
}
