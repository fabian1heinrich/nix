# macOS desktop profile
{ ... }:
{
  imports = [
    ./desktop.nix
    ../home-manager/programs/bitwarden-secrets.nix
  ];
}
