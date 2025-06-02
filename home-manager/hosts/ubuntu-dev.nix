{ pkgs, ... }: {
  imports = [
    ../programs/fzf.nix
    ../programs/ghostty.nix
    ../programs/git.nix
    ../programs/lsd.nix
    ../programs/starship.nix
    ../programs/zoxide.nix
    ../programs/zsh.nix
  ];
  home = {
    username = "ubuntu-dev";
    homeDirectory = "/home/ubuntu-dev";
    stateVersion = "25.11";
    packages = with pkgs; [
      colima
      docker-buildx
      docker-client
      docker-compose
      virt-manager
      vscode
      ungoogled-chromium
    ];
  };
}
