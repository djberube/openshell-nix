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
  version = "0.0.13";

  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "OpenShell";
    rev = "v${version}";
    hash = "sha256-fBoUBZIRse5EDM3LG5kDC8TouJEpJNLqSnnm61W3K9k=";
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
