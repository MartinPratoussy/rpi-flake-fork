{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable-small";
    nixos-raspberrypi = {
      url = "github:nvmd/nixos-raspberrypi/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-patcher.url = "github:gepbird/nixpkgs-patcher";

    systems.url = "github:nix-systems/default";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    sure-nix = {
      url = "github:nSimonFR/sure-nix";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # needs rework
    nixpkgs-patch-add-oxicloud-module = {
      url = "https://github.com/flashonfire/nixpkgs/commit/06217a4eccbd.patch";
      flake = false;
    };
    nixpkgs-patch-fix-oxicloud-cross = {
      url = "https://github.com/flashonfire/nixpkgs/commit/f709b04c26ce.patch";
      flake = false;
    };
  };

  outputs =
    {
      flake-parts,
      agenix,
      nixpkgs-patcher,
      sure-nix,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      flake = {
        nixosConfigurations.lithium = nixpkgs-patcher.lib.nixosSystem {
          system = "x86_64-linux";
          nixpkgsPatcher.system = "x86_64-linux";

          specialArgs = inputs // {
            _utils = (import ./uku_utils.nix) { lib = inputs.nixpkgs.lib; };
            _domain_base = "lithium.ovh";
            _smtp_address = "smtp.mail.ovh.net";
          };

          modules = [
            ./configuration.nix
            agenix.nixosModules.default

            (
              { config, ... }:
              let
                nativeAarch64Pkgs = import inputs.nixpkgs {
                  system = "aarch64-linux";
                  config = config.nixpkgs.config;
                  overlays = [

                    (final: prev: {
                      sure = sure-nix.packages.aarch64-linux.sure;
                    })
                  ];
                };
              in
              {
                nixpkgs.buildPlatform = "x86_64-linux";
                # nixpkgs.config.contentAddressedByDefault = true;

                nixpkgs.overlays = [
                  (final: prev: {
                    # Force immich and immich-machine-learning to compile natively (avoids segfault on thumbnail gen)
                    immich = nativeAarch64Pkgs.immich;
                    immich-machine-learning = nativeAarch64Pkgs.immich-machine-learning;

                    # Required when using native immich
                    # vectorchord needs cross compile fix
                    postgresql_18 = nativeAarch64Pkgs.postgresql_18;
                    postgresql18Packages = nativeAarch64Pkgs.postgresql18Packages;
                    postgresql = nativeAarch64Pkgs.postgresql;

                    # These do not cross compile
                    anubis = nativeAarch64Pkgs.anubis;
                    redis = nativeAarch64Pkgs.redis;
                    sure = nativeAarch64Pkgs.sure;
                    zigbee2mqtt = nativeAarch64Pkgs.zigbee2mqtt; # Compiles but wrong arch
                    ddclient = nativeAarch64Pkgs.ddclient;

                    # Speed up compilation by leveraging cache
                    adguardhome = nativeAarch64Pkgs.adguardhome;
                  })
                ];
              }
            )
          ];
        };
      };

      perSystem =
        { pkgs, system, ... }:
        {
          devShells.default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              agenix.packages.${system}.default
              just
              nh
              dix
            ];
          };

          formatter = pkgs.nixfmt-tree;
        };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    };
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };
}
