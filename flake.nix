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

      nixpkgsOverlays = [ nix-vscode-extensions.overlays.default ];

      mkUser =
        host:
        {
          inherit (host)
            username
            primaryGroup
            homeDirectory
            homeStateVersion
            system
            ;
          inherit (owner) name email;
        }
        // lib.optionalAttrs (host ? name) { inherit (host) name; }
        // lib.optionalAttrs (host ? email) { inherit (host) email; };

      users = lib.mapAttrs (_: mkUser) hostSpecs;

      darwinHostSpecs = lib.filterAttrs (_: host: host ? darwinModules) hostSpecs;
      standaloneHomeHostSpecs = lib.filterAttrs (_: host: !(host ? darwinModules)) hostSpecs;
      systemHostSpecs = lib.filterAttrs (_: host: host ? systemModules) hostSpecs;
      systemManagerSystems = lib.unique (lib.mapAttrsToList (_: host: host.system) systemHostSpecs);

      # Helper to create pkgs for a system
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config = nixpkgsConfig;
          overlays = nixpkgsOverlays;
        };

      mkEvalCheck =
        checkSystem: name: drv:
        let
          # Force the complete derivation to evaluate without adding a foreign-
          # platform build dependency to this lightweight check.
          drvPath = builtins.unsafeDiscardStringContext drv.drvPath;
        in
        (pkgsFor checkSystem).runCommand name { } ''
          printf '%s\n' ${lib.escapeShellArg drvPath} > "$out"
        '';

      shellScripts = [
        (builtins.path {
          path = ./.envrc;
          name = "envrc.sh";
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

      mkActionlint =
        system:
        let
          pkgs = pkgsFor system;
        in
        pkgs.runCommand "actionlint" { nativeBuildInputs = [ pkgs.actionlint ]; } ''
          actionlint ${./.github/workflows/flake-check.yml}
          touch "$out"
        '';

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
            inherit sofka userConfig;
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
                  inherit sofka userConfig;
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

      darwinCheckTargets = lib.mapAttrs' (
        hostName: configuration:
        lib.nameValuePair "${hostName}-system" {
          system = hostSpecs.${hostName}.system;
          drv = configuration.config.system.build.toplevel;
        }
      ) darwinConfigurations;

      homeCheckTargets = lib.mapAttrs' (
        hostName: configuration:
        lib.nameValuePair "${hostName}-home" {
          system = hostSpecs.${hostName}.system;
          drv = configuration.activationPackage;
        }
      ) homeConfigurations;

      systemCheckTargets = lib.mapAttrs' (
        hostName: configuration:
        lib.nameValuePair "${hostName}-system" {
          system = hostSpecs.${hostName}.system;
          drv = configuration;
        }
      ) systemConfigs;

      checkTargets = darwinCheckTargets // homeCheckTargets // systemCheckTargets;

      checks = lib.genAttrs systems (
        checkSystem:
        let
          nativeTargets = lib.filterAttrs (_: target: target.system == checkSystem) checkTargets;
        in
        (lib.mapAttrs' (
          name: target: lib.nameValuePair "${name}-eval" (mkEvalCheck checkSystem "${name}-eval" target.drv)
        ) checkTargets)
        // (lib.mapAttrs' (name: target: lib.nameValuePair "${name}-build" target.drv) nativeTargets)
        // {
          actionlint = mkActionlint checkSystem;
          shellcheck = mkShellcheck checkSystem;
        }
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

      inherit
        apps
        formatter
        darwinConfigurations
        homeConfigurations
        systemConfigs
        checks
        ;
    };
}
