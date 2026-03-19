{
  description = "Nix package for NVIDIA OpenShell - the safe, private runtime for autonomous AI agents";

  nixConfig = {
    extra-substituters = [ ];
    extra-trusted-public-keys = [ ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      flake.overlays.default = final: prev: {
        openshell = prev.callPackage ./packages/openshell/package.nix { };
      };

      perSystem =
        {
          config,
          pkgs,
          system,
          ...
        }:
        {
          packages = {
            openshell = pkgs.callPackage ./packages/openshell/package.nix { };
            default = config.packages.openshell;
          };

          apps = {
            openshell = {
              type = "app";
              program = "${config.packages.openshell}/bin/openshell";
            };
            default = config.apps.openshell;
          };
        };
    };
}
