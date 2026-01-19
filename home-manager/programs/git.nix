{ pkgs, userConfig, ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        email = userConfig.email;
        name = userConfig.name;
      };
      init = {
        defaultBranch = "main";
      };
      credential = {
        # Use secure credential storage:
        # - macOS: osxkeychain (stores in Keychain)
        # - Linux: libsecret (stores in GNOME Keyring or similar)
        helper =
          if pkgs.stdenv.isDarwin then
            "osxkeychain"
          else
            "${pkgs.gitFull}/bin/git-credential-libsecret";
      };
      # Useful defaults
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.autocrlf = "input";
    };
  };
}
