# openshell-nix

Nix package for [NVIDIA OpenShell](https://github.com/NVIDIA/OpenShell) - the safe, private runtime for autonomous AI agents.

## What is OpenShell?

OpenShell provides sandboxed execution environments that protect your data, credentials, and infrastructure — governed by declarative YAML policies that prevent unauthorized file access, data exfiltration, and uncontrolled network activity.

OpenShell is built agent-first and supports agents like:
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
- [OpenCode](https://opencode.ai/)
- [Codex](https://developers.openai.com/codex)
- [OpenClaw](https://openclaw.ai/)

## Installation

### Using Nix Flakes

Run OpenShell directly without installing:

```bash
nix run github:YOURUSERNAME/openshell-nix
```

Or add to your system configuration:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    openshell-nix.url = "github:YOURUSERNAME/openshell-nix";
  };

  outputs = { nixpkgs, openshell-nix, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [{
        environment.systemPackages = [
          openshell-nix.packages.x86_64-linux.openshell
        ];
      }];
    };
  };
}
```

### Using the Overlay

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    openshell-nix.url = "github:YOURUSERNAME/openshell-nix";
  };

  outputs = { nixpkgs, openshell-nix, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [{
        nixpkgs.overlays = [ openshell-nix.overlays.default ];
        environment.systemPackages = [ pkgs.openshell ];
      }];
    };
  };
}
```

## Quickstart

### Prerequisites

- **Docker** — Docker Desktop (or a Docker daemon) must be running
- **Nix** with flakes enabled

### Create a Sandbox

```bash
openshell sandbox create -- claude  # or opencode, codex
```

A gateway is created automatically on first use.

### See Network Policy in Action

Every sandbox starts with **minimal outbound access**. You open additional access with a short YAML policy:

```bash
# 1. Create a sandbox (starts with minimal outbound access)
openshell sandbox create

# 2. Inside the sandbox — blocked
sandbox$ curl -sS https://api.github.com/zen
curl: (56) Received HTTP code 403 from proxy after CONNECT

# 3. Back on the host — apply a read-only GitHub API policy
sandbox$ exit
openshell policy set demo --policy examples/sandbox-policy-quickstart/policy.yaml --wait

# 4. Reconnect — GET allowed, POST blocked by L7
openshell sandbox connect demo
sandbox$ curl -sS https://api.github.com/zen
Anything added dilutes everything else.
```

## License

OpenShell is licensed under the Apache License 2.0. See the [LICENSE](https://github.com/NVIDIA/OpenShell/blob/main/LICENSE) file for details.

## Credits

This Nix packaging was inspired by [numtide/llm-agents.nix](https://github.com/numtide/llm-agents.nix). Special thanks to the numtide team for their work on making AI development tools accessible through Nix.

## Automatic Updates

This repository automatically checks for new OpenShell releases **hourly** via GitHub Actions. When a new version is detected:

1. The package version is updated
2. The Cargo.lock file is fetched
3. The source hash is recalculated
4. A new commit and tag are created
5. A GitHub release is published

You can also manually trigger an update:

```bash
# Update to latest version
./scripts/update.sh

# Update to specific version
./scripts/update.sh 0.0.9
```

The automation workflow can be found in [`.github/workflows/update-openshell.yml`](.github/workflows/update-openshell.yml).

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## Resources

- [OpenShell Documentation](https://docs.nvidia.com/openshell/latest/)
- [OpenShell GitHub Repository](https://github.com/NVIDIA/OpenShell)
- [OpenShell Community](https://github.com/NVIDIA/OpenShell-Community)
- [numtide/llm-agents.nix](https://github.com/numtide/llm-agents.nix) - Inspiration for this packaging
