{ ... }:
{
  home.file.".config/ghostty/config" = {
    force = true;
    text = ''
      theme = GitHub Dark Dimmed
      # VS Code's terminal uses the panel background, not the editor background.
      background = #1c2128
      # Match VS Code's terminal color rendering defaults.
      bold-color = bright
      minimum-contrast = 4.5
      shell-integration = zsh
      # Zsh sets repository/worktree titles consistently across terminals.
      shell-integration-features = no-title
      font-family = MesloLGS Nerd Font Mono
      font-size = 12
      # Bring macOS text strokes closer to VS Code's font rendering.
      font-thicken = true
      font-thicken-strength = 70
      keybind = alt+left=unbind
      keybind = alt+right=unbind
      keybind = cmd+c=copy_to_clipboard
      keybind = cmd+alt+c=text:\x1b[99;9u
      macos-option-as-alt = true
    '';
  };
}
