#!/usr/bin/env bash
# Regenerate Drift.xcodeproj/project.pbxproj (run from repo root or ios/ parent).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/generate_pbxproj.py"
