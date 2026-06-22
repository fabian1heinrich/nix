{ ... }:
let
  commandLineToolsPath = "/Library/Developer/CommandLineTools";
in
{
  system.activationScripts.xcodeCommandLineTools.text = ''
    if [ -d /Applications/Xcode.app ]; then
      echo "warning: Full Xcode.app is installed. Remove it manually if you want a Command Line Tools-only setup." >&2
    fi

    if [ ! -d '${commandLineToolsPath}' ]; then
      echo "warning: Xcode Command Line Tools are missing. Install them with: xcode-select --install" >&2
    else
      current_path="$(/usr/bin/xcode-select -p 2>/dev/null || true)"
      if [ "$current_path" != '${commandLineToolsPath}' ]; then
        /usr/bin/xcode-select --switch '${commandLineToolsPath}'
      fi
    fi
  '';
}
