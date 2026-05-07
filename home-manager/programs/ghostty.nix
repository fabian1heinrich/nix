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
      keybind = cmd+c=text:\x1b[99;9u
      macos-option-as-alt = true
    '';
  };
}
