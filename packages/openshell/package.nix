{
  lib,
  fetchFromGitHub,
  rustPlatform,
  python312Packages,
  pkg-config,
  openssl,
}:

python312Packages.buildPythonApplication rec {
  pname = "openshell";
  version = "0.0.8";

  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "OpenShell";
    rev = "v${version}";
    hash = "sha256-Z7iuoZb/gdIkp4x4MQVQ9DTIKl8jiTIa4RpGRhga62Q=";
  };

  format = "pyproject";

  cargoDeps = rustPlatform.importCargoLock {
    lockFile = "${src}/Cargo.lock";
  };

  nativeBuildInputs = [
    rustPlatform.cargoSetupHook
    rustPlatform.maturinBuildHook
    pkg-config
  ];

  buildInputs = [
    openssl
  ];

  propagatedBuildInputs = with python312Packages; [
    cloudpickle
    grpcio
    protobuf
  ];

  # Tests require Docker and additional setup
  doCheck = false;

  # Skip imports check as it requires generated protobuf files at runtime
  pythonImportsCheck = [ ];

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
}
