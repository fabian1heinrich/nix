{
  config,
  lib,
  pkgs,
  ...
}:
let
  storageCleanup = pkgs.writeShellApplication {
    name = "storage-cleanup";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      gawk
      nix
    ];
    text = builtins.readFile ../scripts/storage-cleanup.sh;
  };

  logDirectory = "${config.home.homeDirectory}/Library/Logs/storage-cleanup";
in
{
  home.packages = [ storageCleanup ];

  home.activation.ensureStorageCleanupLogDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ${lib.escapeShellArg logDirectory}
  '';

  launchd.agents.storage-cleanup = {
    enable = true;
    domain = "user";
    config = {
      ProgramArguments = [ "${storageCleanup}/bin/storage-cleanup" ];
      StartCalendarInterval = [
        {
          Day = 1;
          Hour = 10;
          Minute = 0;
        }
      ];
      ProcessType = "Background";
      LowPriorityIO = true;
      Nice = 10;
      EnvironmentVariables = {
        HOME = config.home.homeDirectory;
        PATH = "${config.home.profileDirectory}/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin";
      };
      StandardOutPath = "${logDirectory}/stdout.log";
      StandardErrorPath = "${logDirectory}/stderr.log";
    };
  };
}
