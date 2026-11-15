# Every top-level program module is public. Keep helpers inside program
# directories; export a directory only when it contains default.nix.
let
  entries = builtins.readDir ./.;
  modules = builtins.filter (
    name:
    (entries.${name} == "regular" && name != "default.nix" && builtins.match ".*\\.nix" name != null)
    || (entries.${name} == "directory" && builtins.pathExists (./. + "/${name}/default.nix"))
  ) (builtins.attrNames entries);
in
builtins.listToAttrs (
  map (name: {
    name =
      if entries.${name} == "directory" then
        name
      else
        builtins.substring 0 (builtins.stringLength name - 4) name;
    value = ./. + "/${name}";
  }) modules
)
