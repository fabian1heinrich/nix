{
  description = "Fabian's Nix Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-qemu.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:nix-darwin/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    catppuccin-k9s = {
      url = "github:catppuccin/k9s";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-qemu,
      home-manager,
      darwin,
      catppuccin-k9s,
      ...
    }:
    let
      owner = {
        name = "Fabian Heinrich";
        email = "fabianheinrich@aol.com";
      };

      mkUser =
        {
          username,
          homeDirectory,
          system,
          name ? owner.name,
          email ? owner.email,
        }:
        {
          inherit
            name
            email
            username
            homeDirectory
            system
            ;
        };

      # User configurations
      users = {
        fabian = mkUser {
          username = "fabian";
          homeDirectory = "/Users/fabian";
          system = "aarch64-darwin";
        };
        ubuntu-dev = mkUser {
          username = "ubuntu-dev";
          homeDirectory = "/home/ubuntu-dev";
          system = "x86_64-linux";
        };
        devcontainer = mkUser {
          username = "vscode";
          homeDirectory = "/home/vscode";
          system = "x86_64-linux";
        };
        k8s-devcontainer = mkUser {
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

      qemuPkgsFor = system: import nixpkgs-qemu {
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
            inherit catppuccin-k9s;
          };
          modules = [
            { nixpkgs.config.allowUnfree = true; }
            ./hosts/legendre/darwin.nix
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                overwriteBackup = true;
                extraSpecialArgs = {
                  userConfig = users.fabian;
                  inherit catppuccin-k9s;
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
            qemuPkgs = qemuPkgsFor users.ubuntu-dev.system;
            inherit catppuccin-k9s;
          };
          modules = [
            ./hosts/ubuntu-dev/home.nix
          ];
        };
        devcontainer = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor users.devcontainer.system;
          extraSpecialArgs = {
            userConfig = users.devcontainer;
            inherit catppuccin-k9s;
          };
          modules = [
            ./hosts/devcontainer/home.nix
          ];
        };
        k8s-devcontainer = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor users.k8s-devcontainer.system;
          extraSpecialArgs = {
            userConfig = users.k8s-devcontainer;
            inherit catppuccin-k9s;
          };
          modules = [
            ./hosts/k8s-devcontainer/home.nix
          ];
        };
      };
    };
}
