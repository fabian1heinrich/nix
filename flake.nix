{
  description = "Fabian's Nix Configuration";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-stable.url = "nixpkgs/nixos-24.11";
  };
  outputs =
    {
      nixpkgs,
      home-manager,
      darwin,
      ...
    }:
    {
      darwinConfigurations = {
        legendre = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          pkgs = import nixpkgs {
            system = "aarch64-darwin";
            config.allowUnfree = true;
            config.allowBroken = true;
          };
          modules = [
            ./darwin
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.fabian.imports = [
                  ./home-manager/default.nix
                  ./home-manager/hosts/legendre.nix
                ];
              };
            }
          ];
        };
      };
      homeConfigurations = {
        ubuntu-dev = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
          modules = [
            ./home-manager/default.nix
            ./home-manager/hosts/ubuntu-dev.nix
          ];
        };
        devcontainer-minimal-aarch64-linux = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs { system = "aarch64-linux"; };
          modules = [
            ./home-manager/hosts/devcontainer-minimal.nix
          ];
        };
        devcontainer-minimal-x86_64-linux = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs { system = "x86_64-linux"; };
          modules = [
            ./home-manager/hosts/devcontainer-minimal.nix
          ];
        };
        devcontainer-aarch64-linux = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs { system = "aarch64-linux"; };
          modules = [
            ./home-manager/default.nix
            ./home-manager/hosts/devcontainer.nix
          ];
        };
        devcontainer-x86_64-linux = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs { system = "x86_64-linux"; };
          modules = [
            ./home-manager/default.nix
            ./home-manager/hosts/devcontainer.nix
          ];
        };
      };
    };
}
