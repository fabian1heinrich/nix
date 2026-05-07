{ pkgs, ... }:
{
  home.packages = with pkgs; [
    just
    just-lsp
    just-formatter
  ];

  xdg.configFile."just/justfile".source = ../../Justfile;
}
