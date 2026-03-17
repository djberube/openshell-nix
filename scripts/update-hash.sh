#!/usr/bin/env bash
# Script to fetch and update package hashes for Nix packages

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 <package-path>"
    echo "Example: $0 packages/openshell/package.nix"
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

PACKAGE_PATH="$1"
FULL_PATH="$PROJECT_ROOT/$PACKAGE_PATH"

if [ ! -f "$FULL_PATH" ]; then
    echo -e "${RED}Error: Package file not found: $FULL_PATH${NC}"
    exit 1
fi

echo -e "${YELLOW}Fetching hash for package: $PACKAGE_PATH${NC}"

# Try to build the package with a dummy hash to get the actual hash
# Nix will fail and tell us the correct hash
TEMP_OUTPUT=$(mktemp)
trap 'rm -f $TEMP_OUTPUT' EXIT

# Run nix build and capture output
if nix build ".#$(basename $(dirname "$PACKAGE_PATH"))" --no-link 2>&1 | tee "$TEMP_OUTPUT"; then
    echo -e "${GREEN}Package built successfully! Hash is already correct.${NC}"
    exit 0
fi

# Extract the actual hash from the error message
ACTUAL_HASH=$(grep -oP "got:\s+\K(sha256-[A-Za-z0-9+/=]+)" "$TEMP_OUTPUT" | head -1)

if [ -z "$ACTUAL_HASH" ]; then
    echo -e "${RED}Could not extract hash from build output.${NC}"
    echo "Build output saved to: $TEMP_OUTPUT"
    trap - EXIT  # Don't delete temp file
    exit 1
fi

echo -e "${GREEN}Found hash: $ACTUAL_HASH${NC}"

# Update the package file with the correct hash
# Look for lines with placeholder hash or TODO
sed -i.bak -E "s|hash = \"sha256-[A-Za-z0-9+/=]+\";.*|hash = \"$ACTUAL_HASH\";|g" "$FULL_PATH"

# Remove backup file
rm -f "$FULL_PATH.bak"

echo -e "${GREEN}Updated hash in $PACKAGE_PATH${NC}"
echo -e "${YELLOW}Verifying build...${NC}"

# Try building again to verify
if nix build ".#$(basename $(dirname "$PACKAGE_PATH"))" --no-link 2>&1; then
    echo -e "${GREEN}Success! Package builds correctly with new hash.${NC}"
else
    echo -e "${RED}Build still failing. Please check the package manually.${NC}"
    exit 1
fi
