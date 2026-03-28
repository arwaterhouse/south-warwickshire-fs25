#!/usr/bin/env bash
# ============================================================
# Red Horse Valley - Local Build Script
# ============================================================
# Builds the mod locally so you can test on Mac without CI.
#
# Run from the repo root in Git Bash (Windows) or Terminal (Mac):
#   bash build_local.sh
# ============================================================

set -e

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
RELEASE_DIR="$REPO_ROOT/_release"
OUT_MOD="$RELEASE_DIR/FS25_SouthWarwickshire"
OUT_ZIP="$RELEASE_DIR/FS25_SouthWarwickshire.zip"

echo "============================================================"
echo "Red Horse Valley - Local Build"
echo "============================================================"
echo ""

# ── Step 1: Run build.py ─────────────────────────────────────
echo "[1/2] Building mod ..."
cd "$RELEASE_DIR"
python3 build.py || python build.py
echo ""

# ── Step 2: Zip the mod folder ───────────────────────────────
echo "[2/2] Zipping ..."
cd "$RELEASE_DIR"
rm -f FS25_SouthWarwickshire.zip
zip -r FS25_SouthWarwickshire.zip FS25_SouthWarwickshire/
ZIP_SIZE=$(du -sh FS25_SouthWarwickshire.zip | cut -f1)
echo "      Zip size: $ZIP_SIZE"
echo ""

# ── Done ─────────────────────────────────────────────────────
echo "============================================================"
echo "Build complete!"
echo ""
echo "  Mod folder : $OUT_MOD"
echo "  Zip        : $OUT_ZIP"
echo ""
echo "TO TEST ON MAC:"
echo "  AirDrop (or copy) _release/FS25_SouthWarwickshire/ to:"
echo "  ~/Library/Application Support/FarmingSimulator2025/mods/"
echo ""
echo "  Then launch FS25 > Mods > Maps > Red Horse Valley"
echo "============================================================"
