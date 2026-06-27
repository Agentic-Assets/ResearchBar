#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "install-codexbar-cli.sh is kept as a compatibility wrapper for this fork." >&2
echo "Installing the ResearchBar CLI as 'researchbar'." >&2
exec "$SCRIPT_DIR/install-researchbar-cli.sh" "$@"
