{
  description = "Fabian's Nix Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Keep QEMU on the stable release branch while the rest of the config tracks unstable.
    nixpkgs-qemu.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager/master";
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
      lib = nixpkgs.lib;

      systems = [
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];

      # Only check systems that currently have configured hosts.
      checkSystems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];

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

      qemuPkgsFor =
        system:
        import nixpkgs-qemu {
          inherit system;
          config.allowUnfree = true;
        };

      mkEvalCheck =
        checkSystem: name: drv:
        (pkgsFor checkSystem).runCommand name { } ''
          printf '%s\n' ${lib.escapeShellArg drv.name} > "$out"
        '';

      mkHome =
        {
          user,
          modules,
          extraSpecialArgs ? { },
        }:
        let
          userConfig = users.${user};
        in
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor userConfig.system;
          extraSpecialArgs = {
            inherit userConfig catppuccin-k9s;
          }
          // extraSpecialArgs;
          inherit modules;
        };

      formatter = lib.genAttrs systems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

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
        ubuntu-dev = mkHome {
          user = "ubuntu-dev";
          extraSpecialArgs = {
            qemuPkgs = qemuPkgsFor users.ubuntu-dev.system;
          };
          modules = [
            ./hosts/ubuntu-dev/home.nix
          ];
        };
        devcontainer = mkHome {
          user = "devcontainer";
          modules = [
            ./hosts/devcontainer/home.nix
          ];
        };
        k8s-devcontainer = mkHome {
          user = "k8s-devcontainer";
          modules = [
            ./hosts/k8s-devcontainer/home.nix
          ];
        };
      };

      checkTargets = {
        legendre = darwinConfigurations.legendre.config.system.build.toplevel;
        ubuntu-dev = homeConfigurations.ubuntu-dev.activationPackage;
        devcontainer = homeConfigurations.devcontainer.activationPackage;
        k8s-devcontainer = homeConfigurations.k8s-devcontainer.activationPackage;
      };

      checks = lib.genAttrs checkSystems (
        checkSystem:
        lib.mapAttrs' (
          name: drv: lib.nameValuePair "${name}-eval" (mkEvalCheck checkSystem "${name}-eval" drv)
        ) checkTargets
      );
    in
    {
      inherit
        formatter
        darwinConfigurations
        homeConfigurations
        checks
        ;
    };
}
