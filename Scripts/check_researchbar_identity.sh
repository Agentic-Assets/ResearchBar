#!/bin/bash
# Read-only guard for public ResearchBar identity after an upstream synchronization.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
IDENTITY_FILE="$ROOT/ResearchBar/branding/identity.env"

if [[ ! -f "$IDENTITY_FILE" ]]; then
  echo "ERROR: Missing branding manifest: $IDENTITY_FILE" >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$IDENTITY_FILE"

require_literal() {
  local file="$1"
  local literal="$2"
  if ! grep -Fq -- "$literal" "$file"; then
    echo "ERROR: Expected '$literal' in ${file#$ROOT/}" >&2
    return 1
  fi
}

require_literal "$ROOT/Sources/CodexBarCore/AppIdentity.swift" "$RESEARCHBAR_PRODUCT_NAME"
require_literal "$ROOT/Sources/CodexBarCore/AppIdentity.swift" "$RESEARCHBAR_BUNDLE_ID"
require_literal "$ROOT/Sources/CodexBarCore/AppIdentity.swift" "isDebugBundleID"
require_literal "$ROOT/.mac-release.env" "MAC_RELEASE_APP_NAME=$RESEARCHBAR_PRODUCT_NAME"
require_literal "$ROOT/.mac-release.env" "MAC_RELEASE_BUNDLE_ID=$RESEARCHBAR_BUNDLE_ID"
require_literal "$ROOT/Scripts/package_app.sh" 'BUNDLE_ID="$RESEARCHBAR_BUNDLE_ID"'
require_literal "$ROOT/Scripts/package_app.sh" 'BUNDLE_ID="$RESEARCHBAR_DEBUG_BUNDLE_ID"'
require_literal "$ROOT/Scripts/package_app.sh" "<string>\${RESEARCHBAR_PRODUCT_NAME}</string>"
require_literal "$ROOT/Scripts/package_app.sh" "<string>\${RESEARCHBAR_MENU_LAYOUT_UTI}</string>"

echo "ResearchBar identity guard passed."
