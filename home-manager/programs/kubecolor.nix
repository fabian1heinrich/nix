{ lib, pkgs, ... }:
{
  programs.kubecolor = {
    enable = true;
    enableAlias = true;
    enableZshIntegration = true;
    settings = {
      kubectl = lib.getExe pkgs.kubectl;
      preset = "dark";
    };
  };
}
