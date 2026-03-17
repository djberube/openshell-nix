{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Nix tools
    nixpkgs-fmt
    nil

    # Build tools
    rustc
    cargo
    rustfmt
    clippy

    # Python tools
    python312
    python312Packages.maturin

    # Other dependencies
    pkg-config
    openssl
    docker
    git
  ];

  shellHook = ''
    echo "OpenShell Nix Development Environment"
    echo "======================================"
    echo ""
    echo "Available commands:"
    echo "  nix build .#openshell     - Build the package"
    echo "  nix run .#openshell       - Run OpenShell"
    echo "  nix flake check           - Check flake validity"
    echo "  nix flake update          - Update dependencies"
    echo ""
    echo "See packages/openshell/SETUP.md for setup instructions"
  '';
}
