{
  description = "Fabian's Nix Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:nix-darwin/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    system-manager.url = "github:numtide/system-manager";
    system-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      darwin,
      system-manager,
      ...
    }:
    let
      lib = nixpkgs.lib;

      systems = [
        "aarch64-darwin"
        "x86_64-linux"
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

      shellScripts = [
        (builtins.path {
          path = ./home-manager/scripts/bw-sync-api-keys.sh;
          name = "bw-sync-api-keys.sh";
        })
      ];

      mkShellcheck =
        system:
        let
          pkgs = pkgsFor system;
        in
        pkgs.runCommand "shellcheck" { nativeBuildInputs = [ pkgs.shellcheck ]; } ''
          shellcheck ${lib.concatMapStringsSep " " (script: ''"${script}"'') shellScripts}
          touch "$out"
        '';

      mkHomeConfiguration =
        {
          system,
          username,
          homeDirectory,
          modules,
          name ? owner.name,
          email ? owner.email,
          extraSpecialArgs ? { },
          pkgs ? pkgsFor system,
        }:
        let
          userConfig = mkUser {
            inherit
              username
              homeDirectory
              system
              name
              email
              ;
          };
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit userConfig;
          }
          // extraSpecialArgs;
          modules = [
            {
              home = {
                username = lib.mkDefault userConfig.username;
                homeDirectory = lib.mkDefault userConfig.homeDirectory;
                stateVersion = lib.mkDefault "25.11";
              };
            }
          ]
          ++ modules;
        };

      mkHome =
        {
          user,
          modules,
          extraSpecialArgs ? { },
        }:
        let
          userConfig = users.${user};
        in
        mkHomeConfiguration {
          inherit
            modules
            extraSpecialArgs
            ;
          inherit (userConfig)
            system
            username
            homeDirectory
            name
            email
            ;
        };

      formatter = lib.genAttrs systems (system: (pkgsFor system).nixfmt-tree);

      mkDevShells =
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            name = "nix-config";
            packages =
              (with pkgs; [
                git
                just
                nixd
                nixfmt
                nixfmt-tree
                shellcheck
                worktrunk
              ])
              ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
                system-manager.packages.${system}.default
              ];
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

      systemConfigs = {
        ubuntu-dev = system-manager.lib.makeSystemConfig {
          modules = [
            { nixpkgs.config.allowUnfree = true; }
            ./hosts/ubuntu-dev/system.nix
          ];
        };
      };

      checkTargets = {
        legendre = darwinConfigurations.legendre.config.system.build.toplevel;
        ubuntu-dev = homeConfigurations.ubuntu-dev.activationPackage;
        ubuntu-dev-system = systemConfigs.ubuntu-dev;
      };

      nativeBuildCheckTargets = {
        aarch64-darwin = {
          legendre-system-build = darwinConfigurations.legendre.config.system.build.toplevel;
        };
        x86_64-linux = {
          ubuntu-dev-activation-build = homeConfigurations.ubuntu-dev.activationPackage;
          ubuntu-dev-system-build = systemConfigs.ubuntu-dev;
        };
      };

      checks = lib.genAttrs checkSystems (
        checkSystem:
        (lib.mapAttrs' (
          name: drv: lib.nameValuePair "${name}-eval" (mkEvalCheck checkSystem "${name}-eval" drv)
        ) checkTargets)
        // {
          shellcheck = mkShellcheck checkSystem;
        }
        // (nativeBuildCheckTargets.${checkSystem} or { })
      );
    in
    {
      devShells = lib.genAttrs systems mkDevShells;

      apps.x86_64-linux.system-manager = {
        type = "app";
        program = "${system-manager.packages.x86_64-linux.default}/bin/system-manager";
      };

      inherit
        formatter
        darwinConfigurations
        homeConfigurations
        systemConfigs
        checks
        ;
    };
}
