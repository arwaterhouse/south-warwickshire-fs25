#!/usr/bin/env bash
# ============================================================
# South Warwickshire FS25 — Local Build Script
# ============================================================
# Regenerates pipeline outputs, builds the mod zip, and
# optionally commits + pushes everything to git.
#
# Usage:
#   bash build_local.sh           # build only
#   bash build_local.sh --push    # build + commit + push
# ============================================================

set -e

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
RELEASE_DIR="$REPO_ROOT/_release"
OUT_MOD="$RELEASE_DIR/FS25_SouthWarwickshire"
OUT_ZIP="$RELEASE_DIR/FS25_SouthWarwickshire.zip"
PUSH=false

for arg in "$@"; do
  [[ "$arg" == "--push" ]] && PUSH=true
done

echo "============================================================"
echo "  South Warwickshire FS25 — Local Build"
echo "============================================================"
echo ""

# ── Step 1: Regenerate pipeline splines ──────────────────────
echo "[1/3] Regenerating i3d splines ..."
cd "$REPO_ROOT"
python3 pipeline/geojson_to_i3d_splines.py
echo ""

# ── Step 2: Build mod ────────────────────────────────────────
echo "[2/3] Building mod ..."
cd "$RELEASE_DIR"
python3 build.py || python build.py
echo ""

# ── Step 3: Zip ──────────────────────────────────────────────
echo "[3/3] Zipping ..."
cd "$RELEASE_DIR"
rm -f FS25_SouthWarwickshire.zip
zip -r FS25_SouthWarwickshire.zip FS25_SouthWarwickshire/
ZIP_SIZE=$(du -sh FS25_SouthWarwickshire.zip | cut -f1)
echo "      Zip size: $ZIP_SIZE"
echo ""

# ── Optional: commit + push outputs ──────────────────────────
if [ "$PUSH" = true ]; then
  echo "Committing and pushing to git ..."
  cd "$REPO_ROOT"
  git add outputs/sw_hedge_splines.i3d \
          outputs/sw_road_hedge_splines.i3d \
          outputs/sw_road_splines.i3d \
          outputs/sw_field_splines.i3d \
          outputs/sw_water_splines.i3d \
          outputs/sw_forest_splines.i3d
  git diff --cached --quiet && echo "  No changes to commit." || \
    git commit -m "Regenerate pipeline splines [build_local.sh --push]" && \
    git push
  echo ""
fi

# ── Done ─────────────────────────────────────────────────────
echo "============================================================"
echo "  Build complete!"
echo ""
echo "  Mod folder : $OUT_MOD"
echo "  Zip        : $OUT_ZIP"
echo ""
echo "  TO TEST ON MAC:"
echo "  Copy _release/FS25_SouthWarwickshire/ to:"
echo "  ~/Library/Application Support/FarmingSimulator2025/mods/"
echo "  Then launch FS25 > Mods > Maps > South Warwickshire"
echo ""
echo "  TO PUSH TO GIT: bash build_local.sh --push"
echo "============================================================"
