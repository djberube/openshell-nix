# OpenShell Package Setup

This package requires some manual setup before it can be built.

## Steps to Complete the Package

### 1. Fetch the Cargo.lock File

The OpenShell repository contains a `Cargo.lock` file that needs to be copied here:

```bash
# Download the Cargo.lock from the OpenShell repository
curl -L https://raw.githubusercontent.com/NVIDIA/OpenShell/v0.0.8/Cargo.lock -o packages/openshell/Cargo.lock
```

### 2. Update the Source Hash

The package.nix file contains a placeholder hash that needs to be replaced with the actual hash:

```bash
# Try to build - it will fail with the correct hash
nix build .#openshell 2>&1 | grep "got:" | awk '{print $2}'
```

Copy the hash that's printed and replace the placeholder in `packages/openshell/package.nix`:

```nix
hash = "sha256-THE_ACTUAL_HASH_HERE";
```

### 3. Build the Package

Once the hash is updated and Cargo.lock is in place:

```bash
nix build .#openshell
```

### 4. Test the Package

```bash
# Run the built package
./result/bin/openshell --version

# Or run directly
nix run .#openshell -- --version
```

## Alternative: Use fetchCargoTarball

If you prefer to fetch the Cargo.lock automatically, you can modify the package to use `fetchCargoTarball`:

```nix
cargoLock = {
  lockFileContents = builtins.readFile (
    fetchurl {
      url = "https://raw.githubusercontent.com/NVIDIA/OpenShell/v${version}/Cargo.lock";
      hash = "sha256-...";  # You'll still need to update this hash
    }
  );
};
```

## Notes

- OpenShell requires Docker to be running for most operations
- The package builds the CLI tool using maturin, which compiles the Rust binary
- Python dependencies are managed through the Python package system
- Tests are disabled by default as they require Docker and additional setup
