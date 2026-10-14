{
  description = "Fabian's Nix Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:nix-darwin/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    system-manager.url = "github:numtide/system-manager";
    system-manager.inputs.nixpkgs.follows = "nixpkgs";
    sofka.url = "github:nklmilojevic/sofka";
    sofka.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nix-vscode-extensions,
      darwin,
      system-manager,
      sofka,
      ...
    }:
    let
      lib = nixpkgs.lib;

      owner = {
        name = "Fabian Heinrich";
        email = "fabianheinrich@aol.com";
      };

      # Adding a host should only require one entry here plus its host modules.
      hostSpecs = {
        legendre = {
          username = "fabian";
          primaryGroup = "staff";
          homeDirectory = "/Users/fabian";
          homeStateVersion = "25.11";
          system = "aarch64-darwin";
          homeModules = [ ./hosts/legendre/home.nix ];
          darwinModules = [ ./hosts/legendre/darwin.nix ];
        };
        ubuntu-dev = {
          username = "ubuntu-dev";
          primaryGroup = "ubuntu-dev";
          homeDirectory = "/home/ubuntu-dev";
          homeStateVersion = "25.11";
          system = "x86_64-linux";
          homeModules = [ ./hosts/ubuntu-dev/home.nix ];
          systemModules = [ ./hosts/ubuntu-dev/system.nix ];
        };
      };

      systems = lib.unique (lib.mapAttrsToList (_: host: host.system) hostSpecs);

      nixpkgsConfig = {
        allowUnfreePredicate =
          pkg: lib.getName pkg == "vscode" || lib.hasPrefix "vscode-extension-" (lib.getName pkg);
      };

      nixpkgsOverlays = [
        nix-vscode-extensions.overlays.default
        sofka.overlays.default
      ];

      overlays.default = lib.composeManyExtensions nixpkgsOverlays;

      # Exported as the `homeModules` output. Named differently here so it does
      # not read like each host's own `homeModules` list, which is unrelated.
      profileModules = {
        gnome = ./home-manager/profiles/gnome.nix;
        workstation = ./home-manager/profiles/workstation.nix;
      };

      mkUser = host: {
        inherit (host)
          username
          primaryGroup
          homeDirectory
          homeStateVersion
          system
          ;
        inherit (owner) name email;
      };

      users = lib.mapAttrs (_: mkUser) hostSpecs;

      darwinHostSpecs = lib.filterAttrs (_: host: host ? darwinModules) hostSpecs;
      standaloneHomeHostSpecs = lib.filterAttrs (_: host: !(host ? darwinModules)) hostSpecs;
      systemHostSpecs = lib.filterAttrs (_: host: host ? systemModules) hostSpecs;
      systemManagerSystems = lib.unique (lib.mapAttrsToList (_: host: host.system) systemHostSpecs);

      # One nixpkgs instance per system. Nix memoises thunks but not function
      # application, so this must stay an attrset: as a plain function, each of
      # the ten or so `pkgsFor` call sites re-ran the whole nixpkgs fixpoint and
      # re-applied every overlay. Measured at 35% slower (9.6s -> 13.0s on
      # `nix flake check --all-systems --no-build --no-eval-cache`), mostly from
      # re-evaluating the nix-vscode-extensions marketplace index.
      pkgsBySystem = lib.genAttrs systems (
        system:
        import nixpkgs {
          inherit system;
          config = nixpkgsConfig;
          overlays = nixpkgsOverlays;
        }
      );

      pkgsFor = system: pkgsBySystem.${system};

      checkLib = import ./checks.nix { inherit lib pkgsFor; };

      mkHomeConfiguration =
        {
          hostName,
          extraSpecialArgs ? { },
        }:
        let
          host = hostSpecs.${hostName};
          userConfig = users.${hostName};
        in
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor host.system;
          extraSpecialArgs = {
            inherit userConfig;
          }
          // extraSpecialArgs;
          modules = host.homeModules;
        };

      mkDarwinConfiguration =
        hostName: host:
        let
          userConfig = users.${hostName};
        in
        darwin.lib.darwinSystem {
          inherit (host) system;
          specialArgs = { inherit userConfig; };
          modules = host.darwinModules ++ [
            home-manager.darwinModules.home-manager
            {
              nixpkgs.config = nixpkgsConfig;
              nixpkgs.overlays = nixpkgsOverlays;

              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = {
                  inherit userConfig;
                };
                users.${host.username}.imports = host.homeModules;
              };
            }
          ];
        };

      mkSystemConfiguration =
        hostName: host:
        system-manager.lib.makeSystemConfig {
          specialArgs.userConfig = users.${hostName};
          modules = host.systemModules;
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
                actionlint
                shellcheck
                worktrunk
              ])
              ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
                system-manager.packages.${system}.default
              ];
          };
        };

      darwinConfigurations = lib.mapAttrs mkDarwinConfiguration darwinHostSpecs;

      homeConfigurations = lib.mapAttrs (
        hostName: _: mkHomeConfiguration { inherit hostName; }
      ) standaloneHomeHostSpecs;

      systemConfigs = lib.mapAttrs mkSystemConfiguration systemHostSpecs;

      # Each configuration kind differs only in its check-name suffix and where
      # its buildable derivation lives.
      mkCheckTargets =
        suffix: toplevelOf: configurations:
        lib.mapAttrs' (
          hostName: configuration:
          lib.nameValuePair "${hostName}-${suffix}" {
            system = hostSpecs.${hostName}.system;
            drv = toplevelOf configuration;
          }
        ) configurations;

      checkTargets =
        mkCheckTargets "darwin" (c: c.config.system.build.toplevel) darwinConfigurations
        // mkCheckTargets "home" (c: c.activationPackage) homeConfigurations
        // mkCheckTargets "sysmgr" lib.id systemConfigs;

      # Home Manager is nested inside the system config on darwin hosts and
      # stands alone everywhere else.
      hmConfigFor =
        hostName:
        if hostSpecs.${hostName} ? darwinModules then
          darwinConfigurations.${hostName}.config.home-manager.users.${hostSpecs.${hostName}.username}
        else
          homeConfigurations.${hostName}.config;

      zshrcTargets = lib.mapAttrsToList (hostName: host: {
        inherit (host) system;
        path = (hmConfigFor hostName).home.file.".config/zsh/.zshrc".source;
      }) hostSpecs;

      checks = lib.genAttrs systems (
        checkSystem: checkLib.forSystem { inherit checkSystem checkTargets zshrcTargets; }
      );

      apps = lib.genAttrs systems (
        system:
        {
          home-manager = {
            type = "app";
            program = "${home-manager.packages.${system}.home-manager}/bin/home-manager";
            meta.description = "Apply a Home Manager configuration from the locked flake input";
          };
        }
        // lib.optionalAttrs (lib.hasSuffix "-darwin" system) {
          darwin-rebuild = {
            type = "app";
            program = "${darwin.packages.${system}.darwin-rebuild}/bin/darwin-rebuild";
            meta.description = "Apply a nix-darwin configuration from the locked flake input";
          };
        }
        // lib.optionalAttrs (lib.elem system systemManagerSystems) {
          system-manager = {
            type = "app";
            program = "${system-manager.packages.${system}.default}/bin/system-manager";
            meta.description = "Apply a System Manager configuration from the locked flake input";
          };
        }
      );
    in
    {
      devShells = lib.genAttrs systems mkDevShells;

      homeModules = profileModules;

      inherit
        apps
        formatter
        darwinConfigurations
        homeConfigurations
        systemConfigs
        checks
        overlays
        ;
    };
}
