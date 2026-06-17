{
  description = "Fabian's Nix Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:nix-darwin/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      darwin,
      disko,
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

      userRegistry = import ./users.nix;
      inherit (userRegistry) owner users;

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
        (builtins.path {
          path = ./home-manager/scripts/container-context.sh;
          name = "container-context.sh";
        })
        (builtins.path {
          path = ./home-manager/scripts/container-prompt-context.sh;
          name = "container-prompt-context.sh";
        })
      ]
      ++ eulerHostPackages.shellScripts;

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
          userConfig = {
            inherit
              name
              email
              username
              homeDirectory
              system
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
            packages = with pkgs; [
              git
              just
              nixd
              nixfmt
              nixfmt-tree
              shellcheck
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

      mkEulerNixosConfiguration =
        modules:
        nixpkgs.lib.nixosSystem {
          system = users.euler.system;
          specialArgs = {
            userConfig = users.euler;
          };
          modules = [
            { nixpkgs.config.allowUnfree = true; }
            disko.nixosModules.disko
          ]
          ++ modules
          ++ [
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = {
                  userConfig = users.euler;
                };
                users.${users.euler.username}.imports = [
                  ./hosts/euler/home.nix
                ];
              };
            }
          ];
        };

      eulerVmNixosConfiguration = mkEulerNixosConfiguration [
        ./hosts/euler/vm.nix
      ];

      eulerBaremetalNixosConfiguration = mkEulerNixosConfiguration [
        ./hosts/euler/baremetal.nix
      ];

      mkEulerInstallerConfiguration =
        {
          eulerInstallerName,
          eulerSystem,
        }:
        nixpkgs.lib.nixosSystem {
          system = users.euler.system;
          specialArgs = {
            inherit
              eulerDiskoConfig
              eulerDiskoDestroyFormatMountScript
              eulerInstallDisk
              eulerInstallerName
              eulerSystem
              ;
          };
          modules = [
            ./hosts/euler/installer.nix
          ];
        };

      eulerVmInstallerConfiguration = mkEulerInstallerConfiguration {
        eulerInstallerName = "euler-installer";
        eulerSystem = eulerVmNixosConfiguration.config.system.build.toplevel;
      };

      eulerBaremetalInstallerConfiguration = mkEulerInstallerConfiguration {
        eulerInstallerName = "euler-installer";
        eulerSystem = eulerBaremetalNixosConfiguration.config.system.build.toplevel;
      };

      eulerDiskoConfigDir = ./hosts/euler;
      eulerDiskoConfig = "${eulerDiskoConfigDir}/storage-install.nix";
      eulerInstallDisk = "/dev/disk/by-id/euler-install-disk";
      eulerDiskoDestroyFormatMountScript = disko.lib._cliDestroyFormatMount (import
        ./hosts/euler/storage-install.nix
        {
          eulerDisk = eulerInstallDisk;
        }
      ) (pkgsFor users.euler.system);

      nixosConfigurations = {
        euler = eulerBaremetalNixosConfiguration;
        euler-installer = eulerBaremetalInstallerConfiguration;
        euler-vm = eulerVmNixosConfiguration;
        euler-vm-installer = eulerVmInstallerConfiguration;
        euler-baremetal = eulerBaremetalNixosConfiguration;
        euler-baremetal-installer = eulerBaremetalInstallerConfiguration;
      };

      eulerHostPackages = import ./hosts/euler/packages.nix {
        pkgs = pkgsFor users.euler.system;
        eulerBaremetalInstallerIso =
          nixosConfigurations.euler-baremetal-installer.config.system.build.isoImage;
        eulerVmInstallerIso = nixosConfigurations.euler-vm-installer.config.system.build.isoImage;
      };

      homeConfigurations = {
        ubuntu-dev = mkHome {
          user = "ubuntu-dev";
          modules = [
            ./hosts/ubuntu-dev/home.nix
          ];
        };
        euler = mkHome {
          user = "euler";
          modules = [
            ./hosts/euler/home.nix
          ];
        };
      };

      checkTargets = {
        legendre = darwinConfigurations.legendre.config.system.build.toplevel;
        ubuntu-dev = homeConfigurations.ubuntu-dev.activationPackage;
        euler-baremetal = nixosConfigurations.euler-baremetal.config.system.build.toplevel;
        euler-vm = nixosConfigurations.euler-vm.config.system.build.toplevel;
      };

      nativeBuildCheckTargets = {
        aarch64-darwin = {
          legendre-system-build = darwinConfigurations.legendre.config.system.build.toplevel;
        };
        x86_64-linux = {
          ubuntu-dev-activation-build = homeConfigurations.ubuntu-dev.activationPackage;
          euler-baremetal-system-build = nixosConfigurations.euler-baremetal.config.system.build.toplevel;
          euler-vm-system-build = nixosConfigurations.euler-vm.config.system.build.toplevel;
        };
      };

      packages = {
        x86_64-linux = eulerHostPackages.packages;
      };

      apps = {
        x86_64-linux = eulerHostPackages.apps;
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

      inherit
        formatter
        darwinConfigurations
        nixosConfigurations
        homeConfigurations
        packages
        apps
        checks
        ;
    };
}
