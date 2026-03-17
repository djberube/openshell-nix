#!/usr/bin/env bash
# Update OpenShell to the latest version
# Usage: ./scripts/update.sh [version]
# If no version is specified, fetches the latest release from GitHub

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGE_FILE="$REPO_ROOT/packages/openshell/package.nix"
CARGO_LOCK_FILE="$REPO_ROOT/packages/openshell/Cargo.lock"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*"
    exit 1
}

# Get current version from package.nix
get_current_version() {
    grep -oP 'version = "\K[^"]+' "$PACKAGE_FILE"
}

# Get latest release from GitHub
get_latest_version() {
    curl -sL https://api.github.com/repos/NVIDIA/OpenShell/releases/latest \
        | jq -r '.tag_name' \
        | sed 's/^v//'
}

# Update version in package.nix
update_version() {
    local new_version="$1"
    info "Updating version to $new_version"
    sed -i "s/version = \"[^\"]*\"/version = \"$new_version\"/" "$PACKAGE_FILE"
}

# Fetch Cargo.lock from GitHub
fetch_cargo_lock() {
    local version="$1"
    info "Fetching Cargo.lock for version $version"
    curl -sL "https://raw.githubusercontent.com/NVIDIA/OpenShell/v${version}/Cargo.lock" \
        -o "$CARGO_LOCK_FILE"

    if [ ! -s "$CARGO_LOCK_FILE" ]; then
        error "Failed to fetch Cargo.lock"
    fi
}

# Build package to get correct hash
get_correct_hash() {
    info "Building package to determine correct hash..."
    local build_output
    build_output=$(nix build "$REPO_ROOT#openshell" 2>&1 || true)

    local new_hash
    new_hash=$(echo "$build_output" | grep -oP "got:\s+\K[^\s]+" | head -1)

    if [ -z "$new_hash" ]; then
        error "Failed to extract hash from build output:\n$build_output"
    fi

    echo "$new_hash"
}

# Update hash in package.nix
update_hash() {
    local new_hash="$1"
    info "Updating hash to $new_hash"
    sed -i "s|hash = \"sha256-[^\"]*\"|hash = \"$new_hash\"|" "$PACKAGE_FILE"
}

# Verify the build works
verify_build() {
    info "Verifying build..."
    if nix build "$REPO_ROOT#openshell" --print-build-logs; then
        info "Build successful!"
        return 0
    else
        error "Build failed"
    fi
}

# Main logic
main() {
    local target_version="${1:-}"

    # Get current version
    local current_version
    current_version=$(get_current_version)
    info "Current version: $current_version"

    # Determine target version
    if [ -z "$target_version" ]; then
        info "Fetching latest release from GitHub..."
        target_version=$(get_latest_version)
    else
        # Remove 'v' prefix if present
        target_version="${target_version#v}"
    fi

    info "Target version: $target_version"

    # Check if update is needed
    if [ "$current_version" = "$target_version" ]; then
        warn "Already at version $target_version"
        exit 0
    fi

    # Create backup
    info "Creating backup of package.nix..."
    cp "$PACKAGE_FILE" "$PACKAGE_FILE.backup"

    # Update version
    update_version "$target_version"

    # Fetch Cargo.lock
    fetch_cargo_lock "$target_version"

    # Get and update hash
    local new_hash
    new_hash=$(get_correct_hash)
    update_hash "$new_hash"

    # Verify build
    if verify_build; then
        info "✅ Successfully updated to version $target_version"
        rm -f "$PACKAGE_FILE.backup"

        echo ""
        info "Next steps:"
        echo "  1. Review the changes: git diff"
        echo "  2. Commit: git add packages/openshell/package.nix packages/openshell/Cargo.lock"
        echo "  3. Commit: git commit -m 'Update OpenShell to version $target_version'"
        echo "  4. Tag: git tag v$target_version"
        echo "  5. Push: git push origin main && git push origin v$target_version"
    else
        warn "Build failed, restoring backup"
        mv "$PACKAGE_FILE.backup" "$PACKAGE_FILE"
        error "Update failed"
    fi
}

# Check dependencies
command -v nix >/dev/null 2>&1 || error "nix is not installed"
command -v jq >/dev/null 2>&1 || error "jq is not installed"
command -v curl >/dev/null 2>&1 || error "curl is not installed"

main "$@"
