{
  description = "Fabian's Nix Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:nix-darwin/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      darwin,
      ...
    }:
    let
      # Shared user configuration
      users = {
        fabian = {
          name = "Fabian Heinrich";
          email = "fabianheinrich@aol.com";
          username = "fabian";
          homeDirectory = "/Users/fabian";
          system = "aarch64-darwin";
        };
        ubuntu-dev = {
          name = "Fabian Heinrich";
          email = "fabianheinrich@aol.com";
          username = "ubuntu-dev";
          homeDirectory = "/home/ubuntu-dev";
          system = "x86_64-linux";
        };
        devcontainer = {
          name = "Fabian Heinrich";
          email = "fabianheinrich@aol.com";
          username = "vscode";
          homeDirectory = "/home/vscode";
          system = "x86_64-linux";
        };
      };

      # Helper to create pkgs for a system
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
    in
    {
      # Formatters for `nix fmt` (nixfmt-tree handles directories)
      formatter = {
        aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-tree;
        x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
        aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixfmt-tree;
      };

      darwinConfigurations = {
        legendre = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = {
            userConfig = users.fabian;
          };
          modules = [
            { nixpkgs.config.allowUnfree = true; }
            ./hosts/legendre/darwin.nix
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = {
                  userConfig = users.fabian;
                };
                users.fabian.imports = [
                  ./hosts/legendre/home.nix
                ];
              };
            }
          ];
        };
      };

      homeConfigurations = {
        ubuntu-dev = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor users.ubuntu-dev.system;
          extraSpecialArgs = {
            userConfig = users.ubuntu-dev;
          };
          modules = [
            ./hosts/ubuntu-dev/home.nix
          ];
        };
        devcontainer = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor users.devcontainer.system;
          extraSpecialArgs = {
            userConfig = users.devcontainer;
          };
          modules = [
            ./hosts/devcontainer/home.nix
          ];
        };
      };
    };
}
