#!/usr/bin/env python3
"""
SW British Flora - Release Builder
===================================
Reads from: ../south-warwickshire-fs25/   (NEVER modified)
Writes to:  ./_release/                   (rebuilt each run)

Output layout:
  _release/
    FS25_SouthWarwickshire/   <- drop into FS25 Mods folder
    GE_Scripts/               <- copy .lua files to GE scripts folder
    INSTALL.txt

Usage:
  python build.py
"""

import os
import shutil
import json
import re
from pathlib import Path

# ── Paths ────────────────────────────────────────────────────────────────────
HERE        = Path(__file__).parent                          # _release/
WORK_ROOT   = HERE.parent                                    # south-warwickshire-fs25/
WORK_MAP    = WORK_ROOT / "map"                              # working map source
WORK_SCRIPTS= WORK_ROOT / "scripts"                         # working GE scripts

OUT_ROOT    = HERE
OUT_MOD     = OUT_ROOT / "FS25_SouthWarwickshire"
OUT_GE      = OUT_ROOT / "GE_Scripts"

# ── Top-level folders to exclude (ONLY at the root of map/) ──────────────────
# These are development/generation artefacts the game never needs.
# NOTE: "background" here refers to map/background/ (raw satellite/OSM source).
#       map/assets/background/ (background_terrain.i3d) is a game asset and
#       must NOT be excluded — it controls the terrain beyond the map boundary.
TOP_LEVEL_EXCLUDES = {
    "background",       # OBJ/PNG generation source files  (map/background/)
    "satellite",        # source satellite imagery
    "previews",         # dev preview renders
}

# ── Top-level files to exclude ───────────────────────────────────────────────
TOP_LEVEL_FILE_EXCLUDES = {
    "custom_osm.osm",
    "generation_info.json",
    "generation_logs.json",
    "generation_settings.json",
    "main_settings.json",
    "performance_report.json",
    "fs22_to_fs25_conversion_report.txt",
    "tree_custom_schema.json",
}

# ── Files to exclude anywhere in the tree ────────────────────────────────────
FILE_EXCLUDES_ANYWHERE = {
    "map.i3d.fs22_backup",
    "map.i3d_temp0",
}

# ── SW GE scripts to include in GE_Scripts/ ──────────────────────────────────
# Only our custom scripts - not the third-party FSG/community ones.
GE_SCRIPT_PATTERN = re.compile(r'^sw_.*\.lua$')

# ─────────────────────────────────────────────────────────────────────────────

def size_mb(path: Path) -> float:
    total = 0
    if path.is_file():
        return path.stat().st_size / 1_048_576
    for f in path.rglob("*"):
        if f.is_file():
            total += f.stat().st_size
    return total / 1_048_576


def strip_lua_comments(src: str) -> str:
    """
    Light optimisation: remove full-line -- comments and blank lines.
    Keeps inline comments on code lines intact so errors stay readable.
    Does NOT touch strings or block comments (--[[ ]]).
    """
    lines = src.splitlines()
    out = []
    in_block = False
    for line in lines:
        stripped = line.strip()
        # Track block comments
        if '--[[' in line:
            in_block = True
        if in_block:
            if ']]' in line:
                in_block = False
            continue  # drop block comment lines
        # Drop full-line -- comments and blank lines
        if stripped.startswith('--') or stripped == '':
            continue
        out.append(line)
    return '\n'.join(out) + '\n'


def minify_json(src: str) -> str:
    try:
        return json.dumps(json.loads(src), separators=(',', ':'))
    except Exception:
        return src  # if parse fails, return as-is


def copy_map(src: Path, dst: Path):
    """Copy src into dst, applying top-level excludes only at this level."""
    dst.mkdir(parents=True, exist_ok=True)
    skipped = []

    for item in src.iterdir():
        if item.is_dir() and item.name in TOP_LEVEL_EXCLUDES:
            skipped.append(item.name)
            continue
        if item.is_file() and item.name in TOP_LEVEL_FILE_EXCLUDES:
            skipped.append(item.name)
            continue

        dest_item = dst / item.name

        if item.is_dir():
            _copy_dir_filtered(item, dest_item)
        elif item.is_file():
            _copy_file_optimised(item, dest_item)

    return skipped


def _copy_dir_filtered(src: Path, dst: Path):
    """Recursively copy a directory, skipping only FILE_EXCLUDES_ANYWHERE."""
    dst.mkdir(parents=True, exist_ok=True)
    for item in src.iterdir():
        if item.name in FILE_EXCLUDES_ANYWHERE:
            continue
        dest_item = dst / item.name
        if item.is_dir():
            _copy_dir_filtered(item, dest_item)
        elif item.is_file():
            _copy_file_optimised(item, dest_item)


def _copy_file_optimised(src: Path, dst: Path):
    ext = src.suffix.lower()
    if ext == '.json':
        try:
            text = src.read_text(encoding='utf-8', errors='replace')
            dst.write_text(minify_json(text), encoding='utf-8')
            return
        except Exception:
            pass
    # All other files: straight copy (binary safe)
    shutil.copy2(src, dst)


def copy_ge_scripts(src: Path, dst: Path):
    dst.mkdir(parents=True, exist_ok=True)
    copied = []
    for f in src.iterdir():
        if f.is_file() and GE_SCRIPT_PATTERN.match(f.name):
            text = f.read_text(encoding='utf-8', errors='replace')
            optimised = strip_lua_comments(text)
            (dst / f.name).write_text(optimised, encoding='utf-8')
            copied.append(f.name)
    return copied


def write_install_txt(dst: Path, ge_scripts: list):
    lines = [
        "SW South Warwickshire - FS25 Release",
        "=====================================",
        "",
        "INSTALL INSTRUCTIONS",
        "--------------------",
        "",
        "1. MAP MOD  ->  copy the entire FS25_SouthWarwickshire/ folder into:",
        "   Windows : C:\\Users\\<you>\\Documents\\My Games\\FarmingSimulator2025\\mods\\",
        "   Mac     : ~/Library/Application Support/FarmingSimulator2025/mods/",
        "",
        "2. GE SCRIPTS  ->  copy the contents of GE_Scripts/ into:",
        "   C:\\Program Files\\GIANTS Software\\GIANTS_Editor_10.0.9\\scripts\\",
        "",
        "   Scripts included:",
    ]
    for s in sorted(ge_scripts):
        lines.append(f"     - {s}")
    lines += [
        "",
        "3. To rebuild this release folder at any time, run:",
        "   python build.py",
        "",
        "NOTE: The source working folder (south-warwickshire-fs25/) is NEVER",
        "modified by this script. All output is written here only.",
    ]
    (dst / "INSTALL.txt").write_text('\n'.join(lines), encoding='utf-8')


# ── Main ─────────────────────────────────────────────────────────────────────

def main():
    print("=" * 60)
    print("SW Release Builder")
    print("=" * 60)
    print(f"  Source : {WORK_ROOT}")
    print(f"  Output : {OUT_ROOT}")
    print()

    # Wipe and recreate output mod folder (NOT the whole _release dir,
    # so build.py itself is never deleted)
    if OUT_MOD.exists():
        shutil.rmtree(OUT_MOD)
    if OUT_GE.exists():
        shutil.rmtree(OUT_GE)

    # ── Copy map mod ──────────────────────────────────────────────────
    print("Copying map mod files...")
    before_mb = size_mb(WORK_MAP)
    skipped = copy_map(WORK_MAP, OUT_MOD)
    after_mb = size_mb(OUT_MOD)
    print(f"  Source size : {before_mb:,.0f} MB")
    print(f"  Release size: {after_mb:,.0f} MB  (saved {before_mb - after_mb:,.0f} MB)")
    print(f"  Excluded    : {', '.join(skipped)}")
    print()

    # ── Copy GE scripts ───────────────────────────────────────────────
    print("Copying GE scripts...")
    ge_scripts = copy_ge_scripts(WORK_SCRIPTS, OUT_GE)
    print(f"  Scripts     : {', '.join(ge_scripts)}")
    print()

    # ── Install instructions ──────────────────────────────────────────
    write_install_txt(OUT_ROOT, ge_scripts)

    print("=" * 60)
    print(f"Release ready in: {OUT_ROOT}")
    print()
    print("  FS25_SouthWarwickshire/  ->  drop into FS25 mods folder")
    print("  GE_Scripts/              ->  copy to GE scripts folder")
    print("  INSTALL.txt              ->  full instructions")
    print("=" * 60)


if __name__ == "__main__":
    main()
