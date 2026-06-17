{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixos-raspberrypi = {
      url = "github:nvmd/nixos-raspberrypi/develop"; # to be reverted once f8a380d59aa24313df6a290d3e0aac5dd8347aaa is merged in main
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-patcher.url = "github:gepbird/nixpkgs-patcher";

    systems.url = "github:nix-systems/default";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # Merged in staging
    nixpkgs-patch-fix-mypy = {
      url = "https://github.com/FlashOnFire/nixpkgs/commit/f4bc8453464ac0238fc43967d53ab600396d8674.patch";
      flake = false;
    };
    # In draft PR, depends on mypy patch
    nixpkgs-patch-fix-matter-server = {
      url = "https://github.com/FlashOnFire/nixpkgs/commit/61e6484122b2d531f127ab7c05a407a95b1c4a4b.patch";
      flake = false;
    };

    # Depends on mypy patch and needs rework
    nixpkgs-patch-fix-python-hass-chip-wheels = {
      url = "https://github.com/flashonfire/nixpkgs/commit/53cc657f8cf5a91f01bc3e5257ac8cc0fbaf8bb2.patch";
      flake = false;
    };

    # needs rework
    nixpkgs-patch-add-oxicloud-module = {
      url = "https://github.com/flashonfire/nixpkgs/commit/06217a4eccbd.patch";
      flake = false;
    };
    nixpkgs-patch-fix-oxicloud-cross = {
      url = "https://github.com/FlashOnFire/nixpkgs/commit/3731a27f20d3.patch";
      flake = false;
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        darwin.follows = "";
      };
    };
  };

  outputs =
    {
      flake-parts,
      agenix,
      nixpkgs-patcher,
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
                };
              in
              {
                nixpkgs.buildPlatform = "x86_64-linux";

                nixpkgs.overlays = [
                  (final: prev: {
                    # Force immich and immich-machine-learning to compile natively (avoids segfault on thumbnail gen)
                    immich = nativeAarch64Pkgs.immich;
                    immich-machine-learning = nativeAarch64Pkgs.immich-machine-learning;

                    # Required when using native immich
                    postgresql_18 = nativeAarch64Pkgs.postgresql_18;
                    postgresql18Packages = nativeAarch64Pkgs.postgresql18Packages;
                    postgresql = nativeAarch64Pkgs.postgresql;

                    # These do not cross compile
                    atop = nativeAarch64Pkgs.atop;
                    openblas = nativeAarch64Pkgs.openblas;
                    anubis = nativeAarch64Pkgs.anubis;
                    redis = nativeAarch64Pkgs.redis;
                    gdb = nativeAarch64Pkgs.gdb;

                    # Speed up compilation by leveraging cache
                    kitty = nativeAarch64Pkgs.kitty;
                    vaultwarden = nativeAarch64Pkgs.vaultwarden;
                    forgejo = nativeAarch64Pkgs.forgejo;
                    adguardhome = nativeAarch64Pkgs.adguardhome;
                    cinny = nativeAarch64Pkgs.cinny;
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
