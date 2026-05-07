{
  description = "Fabian's Nix Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
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
      };

      # Helper to create pkgs for a system
      pkgsFor =
        system:
        import nixpkgs {
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
            inherit userConfig;
          }
          // extraSpecialArgs;
          inherit modules;
        };

      formatter = lib.genAttrs systems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      mkDevShells =
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              git
              just
              nixfmt-tree
            ];
          };

          kubernetes = pkgs.mkShell {
            packages = with pkgs; [
              just
              kind
              kubectl
              kubernetes-helm
              kustomize
            ];
          };
        };

      homeManagerModules = {
        profiles = {
          base = ./profiles/base.nix;
          desktop = ./profiles/desktop.nix;
        };

        stacks = {
          development = ./home-manager/stacks/development.nix;
          containers = ./home-manager/stacks/containers.nix;
          kubernetes = ./home-manager/stacks/kubernetes.nix;
          terminal = ./home-manager/stacks/terminal.nix;
        };
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
                backupFileExtension = "backup";
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
        ubuntu-dev = mkHome {
          user = "ubuntu-dev";
          modules = [
            ./hosts/ubuntu-dev/home.nix
          ];
        };
      };

      checkTargets = {
        legendre = darwinConfigurations.legendre.config.system.build.toplevel;
        ubuntu-dev = homeConfigurations.ubuntu-dev.activationPackage;
      };

      mkModuleCheckTargets =
        checkSystem:
        let
          pkgs = pkgsFor checkSystem;
          userConfig = mkUser {
            username = "module-check";
            homeDirectory = if pkgs.stdenv.isDarwin then "/Users/module-check" else "/home/module-check";
            system = checkSystem;
          };
          mkModuleActivation =
            module:
            (home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              extraSpecialArgs = {
                inherit userConfig;
              };
              modules = [
                {
                  home = {
                    username = userConfig.username;
                    homeDirectory = userConfig.homeDirectory;
                    stateVersion = "25.11";
                  };
                }
                module
              ];
            }).activationPackage;
        in
        {
          module-profile-base = mkModuleActivation homeManagerModules.profiles.base;
          module-profile-desktop = mkModuleActivation homeManagerModules.profiles.desktop;
          module-stack-containers = mkModuleActivation homeManagerModules.stacks.containers;
          module-stack-development = mkModuleActivation homeManagerModules.stacks.development;
          module-stack-kubernetes = mkModuleActivation homeManagerModules.stacks.kubernetes;
          module-stack-terminal = mkModuleActivation homeManagerModules.stacks.terminal;
        };

      checks = lib.genAttrs checkSystems (
        checkSystem:
        let
          targets = checkTargets // (mkModuleCheckTargets checkSystem);
        in
        lib.mapAttrs' (
          name: drv: lib.nameValuePair "${name}-eval" (mkEvalCheck checkSystem "${name}-eval" drv)
        ) targets
      );
    in
    {
      devShells = lib.genAttrs systems mkDevShells;

      inherit
        formatter
        darwinConfigurations
        homeConfigurations
        homeManagerModules
        checks
        ;
    };
}
