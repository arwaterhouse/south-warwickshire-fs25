#!/usr/bin/env bash
# ============================================================
# SW South Warwickshire - Local Build Script
# ============================================================
# Replicates what the GitHub Actions release pipeline does,
# so you can build and test the mod locally without CI.
#
# Run from the repo root:
#   bash build_local.sh
#
# On Windows: run in Git Bash (comes with Git for Windows)
# On Mac:     run in Terminal
# ============================================================

set -e

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
RELEASE_DIR="$REPO_ROOT/_release"
OUT_MOD="$RELEASE_DIR/FS25_SouthWarwickshire"
OUT_ZIP="$RELEASE_DIR/FS25_SouthWarwickshire.zip"

echo "============================================================"
echo "SW Local Build"
echo "============================================================"
echo "Repo : $REPO_ROOT"
echo ""

# ── Step 1: Pull LFS files ───────────────────────────────────
# The large binary files (map.i3d, .shapes, .dds textures) are
# stored in Git LFS. Without this step the game files are just
# tiny pointer stubs and the game will fail to load the map.
echo "[1/3] Pulling LFS objects for map/ and scripts/ ..."
cd "$REPO_ROOT"
git lfs install --skip-repo 2>/dev/null || git lfs install
git lfs pull --include="map/,scripts/"
echo "      LFS pull complete."
echo ""

# ── Step 2: Run build.py ────────────────────────────────────
echo "[2/3] Running build.py ..."
cd "$RELEASE_DIR"
python3 build.py || python build.py
echo ""

# ── Step 3: Zip the mod folder ──────────────────────────────
echo "[3/3] Zipping mod folder ..."
cd "$RELEASE_DIR"
rm -f FS25_SouthWarwickshire.zip
zip -r FS25_SouthWarwickshire.zip FS25_SouthWarwickshire/
ZIP_SIZE=$(du -sh FS25_SouthWarwickshire.zip | cut -f1)
echo "      Zip size: $ZIP_SIZE"
echo ""

# ── Done ────────────────────────────────────────────────────
echo "============================================================"
echo "Build complete!"
echo ""
echo "  Mod zip : $OUT_ZIP"
echo "  Mod dir : $OUT_MOD"
echo ""
echo "TO TEST ON MAC:"
echo "  1. Copy _release/FS25_SouthWarwickshire/ to your Mac's mods folder:"
echo "     ~/Library/Application Support/FarmingSimulator2025/mods/"
echo "     (or use AirDrop / shared folder / USB)"
echo ""
echo "  2. Launch FS25 on Mac, go to Mods > Maps and select"
echo "     'South Warwickshire'"
echo ""
echo "GE SCRIPTS (optional):"
echo "  Copy _release/GE_Scripts/*.lua to your GE scripts folder."
echo "============================================================"
