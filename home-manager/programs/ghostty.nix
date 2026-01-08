{ ... }:
{
  home.file.".config/ghostty/config" = {
    force = true;
    text = ''
      theme = GitHub Dark
      shell-integration = zsh
      font-family = MesloLGM Nerd Font Mono
      keybind = alt+left=unbind
      keybind = alt+right=unbind
      macos-option-as-alt = true
    '';
  };
}
