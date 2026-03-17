{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  python312,
  python312Packages,
  maturin,
  pkg-config,
  openssl,
  docker,
  git,
  versionCheckHook,
}:

let
  version = "0.0.8";
  pname = "openshell";

  # Build the Rust CLI binary
  rustPackage = rustPlatform.buildRustPackage {
    inherit pname version;

    src = fetchFromGitHub {
      owner = "NVIDIA";
      repo = "OpenShell";
      rev = "v${version}";
      hash = "sha256-Z7iuoZb/gdIkp4x4MQVQ9DTIKl8jiTIa4RpGRhga62Q=";
    };

    cargoLock = {
      lockFile = ./Cargo.lock;
    };

    nativeBuildInputs = [
      pkg-config
      maturin
    ];

    buildInputs = [
      openssl
    ];

    # Build only the CLI crate
    buildAndTestSubdir = "crates/openshell-cli";

    meta = {
      description = "OpenShell CLI - safe, private runtime for autonomous AI agents";
      homepage = "https://github.com/NVIDIA/OpenShell";
      license = lib.licenses.asl20;
      mainProgram = "openshell";
    };
  };

  # Build the Python package with the Rust binary
  pythonPackage = python312Packages.buildPythonApplication {
    inherit pname version;

    src = rustPackage.src;

    pyproject = true;

    nativeBuildInputs = [
      maturin
      python312Packages.setuptools-scm
    ];

    propagatedBuildInputs = with python312Packages; [
      cloudpickle
      grpcio
      protobuf
    ];

    buildInputs = [
      openssl
    ];

    nativeCheckInputs = with python312Packages; [
      pytestCheckHook
      pytest-asyncio
      pytest-cov
      pytest-xdist
    ];

    # Set maturin build options
    maturinBuildFlags = [
      "--bindings"
      "bin"
    ];

    # Tests require Docker and additional setup
    doCheck = false;

    pythonImportsCheck = [ "openshell" ];

    postInstall = ''
      # Ensure the binary is in the output
      if [ ! -f "$out/bin/openshell" ]; then
        echo "Warning: openshell binary not found in expected location"
      fi
    '';

    meta = {
      description = "OpenShell - safe, private runtime for autonomous AI agents";
      longDescription = ''
        OpenShell provides sandboxed execution environments that protect your data,
        credentials, and infrastructure — governed by declarative YAML policies that
        prevent unauthorized file access, data exfiltration, and uncontrolled network
        activity. Built agent-first with support for Claude Code, OpenCode, Codex, and
        other AI agents.
      '';
      homepage = "https://github.com/NVIDIA/OpenShell";
      documentation = "https://docs.nvidia.com/openshell/latest/";
      changelog = "https://github.com/NVIDIA/OpenShell/releases";
      license = lib.licenses.asl20;
      maintainers = [ ];
      mainProgram = "openshell";
      platforms = lib.platforms.unix;
    };
  };
in
pythonPackage
