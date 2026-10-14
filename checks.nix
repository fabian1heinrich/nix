# Flake check construction. `flake.nix` owns the host inventory and decides
# what to check; this file decides how.
#
# Paths here are relative to the repository root, so this file must stay there.
{
  lib,
  pkgsFor,
}:
let
  # Shell scripts linted by ShellCheck.
  shellScripts = [
    (builtins.path {
      path = ./.envrc;
      name = "envrc.sh";
    })
  ];

  # Workflow files linted by actionlint, which also runs ShellCheck over the
  # `run:` blocks when shellcheck is on PATH.
  workflows = builtins.path {
    path = ./.github/workflows;
    name = "workflows";
  };

  justfile = builtins.path {
    path = ./Justfile;
    name = "Justfile";
  };

  # Forcing `drvPath` evaluates the derivation completely: every module, option,
  # and package reference. `seq` forces it without interpolating it into the
  # builder, so no string context is created and the check never gains a
  # dependency on a derivation this platform cannot build.
  mkEvalCheck =
    checkSystem: name: drv:
    (pkgsFor checkSystem).runCommand name { } (builtins.seq drv.drvPath ''touch "$out"'');

  mkShellcheck =
    system:
    let
      pkgs = pkgsFor system;
    in
    pkgs.runCommand "shellcheck" { nativeBuildInputs = [ pkgs.shellcheck ]; } ''
      shellcheck ${lib.escapeShellArgs shellScripts}
      touch "$out"
    '';

  mkActionlint =
    system:
    let
      pkgs = pkgsFor system;
    in
    pkgs.runCommand "actionlint"
      {
        nativeBuildInputs = [
          pkgs.actionlint
          pkgs.shellcheck
        ];
      }
      ''
        actionlint ${workflows}/*
        touch "$out"
      '';

  mkJustCheck =
    system:
    let
      pkgs = pkgsFor system;
    in
    pkgs.runCommand "just" { nativeBuildInputs = [ pkgs.just ]; } ''
      just --justfile ${justfile} --working-directory . --fmt --check
      touch "$out"
    '';

  # `zsh -n` parses the generated zshrc without sourcing it, which covers the
  # hand-written ZLE widgets and functions in programs/zsh.nix.
  mkZshCheck =
    system: zshrcs:
    let
      pkgs = pkgsFor system;
    in
    pkgs.runCommand "zsh-syntax" { nativeBuildInputs = [ pkgs.zsh ]; } ''
      ${lib.concatMapStringsSep "\n" (rc: "zsh -n ${rc}") zshrcs}
      touch "$out"
    '';
in
{
  # All checks exposed for one system.
  #
  # checkTargets :: { <name> = { system; drv; }; }  host configurations
  # zshrcTargets :: [ { system; path; } ]           generated zshrc files
  #
  # Native hosts are built, since a foreign-platform derivation cannot be
  # realised here. Foreign hosts get the lightweight eval check instead, so a
  # plain `nix flake check` on one platform still evaluates every host; adding
  # it for a native host would only duplicate that host's build check. The
  # generated zshrc is likewise built by its own host's pkgs.
  forSystem =
    {
      checkSystem,
      checkTargets,
      zshrcTargets,
    }:
    let
      nativeTargets = lib.filterAttrs (_: target: target.system == checkSystem) checkTargets;
      foreignTargets = lib.filterAttrs (_: target: target.system != checkSystem) checkTargets;
      nativeZshrcs = map (target: target.path) (
        lib.filter (target: target.system == checkSystem) zshrcTargets
      );
    in
    (lib.mapAttrs' (
      name: target: lib.nameValuePair "${name}-eval" (mkEvalCheck checkSystem "${name}-eval" target.drv)
    ) foreignTargets)
    // (lib.mapAttrs' (name: target: lib.nameValuePair "${name}-build" target.drv) nativeTargets)
    // {
      shellcheck = mkShellcheck checkSystem;
      actionlint = mkActionlint checkSystem;
      just = mkJustCheck checkSystem;
    }
    // lib.optionalAttrs (nativeZshrcs != [ ]) {
      zsh-syntax = mkZshCheck checkSystem nativeZshrcs;
    };
}
