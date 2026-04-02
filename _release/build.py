#!/usr/bin/env python3
"""
SW South Warwickshire - Release Builder (OPTIMIZED)
====================================================
Reads from: ../south-warwickshire-fs25/   (NEVER modified)
Writes to:  ./_release/                   (rebuilt each run)

Output layout:
  _release/
    FS25_SouthWarwickshire/   <- drop into FS25 Mods folder
    GE_Scripts/               <- copy .lua files to GE scripts folder
    FS25_SouthWarwickshire.zip <- ready for GitHub release
    INSTALL.txt

Usage:
  python build.py
"""

import os
import shutil
import json
import re
import sys
from pathlib import Path
from zipfile import ZipFile

# ── Paths ────────────────────────────────────────────────────────────────────
HERE        = Path(__file__).parent                          # _release/
WORK_ROOT   = HERE.parent                                    # south-warwickshire-fs25/
WORK_MAP    = WORK_ROOT / "map"                              # working map source
WORK_SCRIPTS= WORK_ROOT / "scripts"                         # working GE scripts

OUT_ROOT    = HERE
OUT_MOD     = OUT_ROOT / "FS25_SouthWarwickshire"
OUT_GE      = OUT_ROOT / "GE_Scripts"
OUT_ZIP     = OUT_ROOT / "FS25_SouthWarwickshire.zip"

# ── Top-level folders to exclude ──────────────────────────────────────────────
TOP_LEVEL_EXCLUDES = {
    "background",       # OBJ/PNG generation source files
    "satellite",        # source satellite imagery
    "previews",         # dev preview renders
    ".git",             # git folder
}

# ── Top-level files to exclude ────────────────────────────────────────────────
TOP_LEVEL_FILE_EXCLUDES = {
    "custom_osm.osm",
    "generation_info.json",
    "generation_logs.json",
    "generation_settings.json",
    "main_settings.json",
    "performance_report.json",
    "fs22_to_fs25_conversion_report.txt",
    "tree_custom_schema.json",
    ".DS_Store",
    "Thumbs.db",
}

# ── Files to exclude anywhere in the tree ─────────────────────────────────────
FILE_EXCLUDES_ANYWHERE = {
    "map.i3d.fs22_backup",
    "map.i3d_temp0",
    ".DS_Store",
    "Thumbs.db",
}

# ── GE scripts pattern ────────────────────────────────────────────────────────
GE_SCRIPT_PATTERN = re.compile(r'^sw_.*\.lua$')

# ─────────────────────────────────────────────────────────────────────────────

def size_mb(path: Path) -> float:
    """Calculate folder size in MB"""
    total = 0
    if path.is_file():
        return path.stat().st_size / 1_048_576
    try:
        for f in path.rglob("*"):
            if f.is_file():
                total += f.stat().st_size
    except:
        pass
    return total / 1_048_576


def strip_lua_comments(src: str) -> str:
    """Remove full-line comments and blank lines from Lua"""
    lines = src.splitlines()
    out = []
    in_block = False
    for line in lines:
        stripped = line.strip()
        if '--[[' in line:
            in_block = True
        if in_block:
            if ']]' in line:
                in_block = False
            continue
        if stripped.startswith('--') or stripped == '':
            continue
        out.append(line)
    return '\n'.join(out) + '\n'


def minify_json(src: str) -> str:
    """Minify JSON by removing whitespace"""
    try:
        return json.dumps(json.loads(src), separators=(',', ':'))
    except Exception:
        return src


def copy_file_optimised(src: Path, dst: Path):
    """Copy file with optimizations for JSON/Lua"""
    dst.parent.mkdir(parents=True, exist_ok=True)
    ext = src.suffix.lower()

    try:
        if ext == '.json':
            text = src.read_text(encoding='utf-8', errors='replace')
            dst.write_text(minify_json(text), encoding='utf-8')
        else:
            shutil.copy2(src, dst)
    except Exception as e:
        print(f"  ⚠ Error copying {src.name}: {e}")


def copy_dir_filtered(src: Path, dst: Path, level=0):
    """Recursively copy directory with filtering"""
    if not src.is_dir():
        return

    dst.mkdir(parents=True, exist_ok=True)

    try:
        for item in src.iterdir():
            # Skip excluded files/folders
            if item.name in FILE_EXCLUDES_ANYWHERE:
                continue
            if level == 0 and item.name in TOP_LEVEL_EXCLUDES:
                continue
            if level == 0 and item.name in TOP_LEVEL_FILE_EXCLUDES:
                continue

            dest_item = dst / item.name

            if item.is_dir():
                copy_dir_filtered(item, dest_item, level + 1)
            elif item.is_file():
                copy_file_optimised(item, dest_item)
    except Exception as e:
        print(f"  ⚠ Error in directory: {src}: {e}")


def create_zip(src: Path, dst: Path):
    """Create optimized zip file"""
    print(f"Creating ZIP file: {dst.name}")

    try:
        with ZipFile(dst, 'w') as zf:
            for file in src.rglob('*'):
                if file.is_file():
                    arcname = file.relative_to(src.parent)
                    zf.write(file, arcname)

        zip_size = dst.stat().st_size / 1_048_576
        print(f"  ✓ ZIP created: {zip_size:,.0f} MB")
        return True
    except Exception as e:
        print(f"  ✗ ZIP creation failed: {e}")
        return False


def copy_ge_scripts(src: Path, dst: Path):
    """Copy and optimize GE scripts"""
    if not src.exists():
        return []

    dst.mkdir(parents=True, exist_ok=True)
    copied = []

    try:
        for f in src.iterdir():
            if f.is_file() and GE_SCRIPT_PATTERN.match(f.name):
                text = f.read_text(encoding='utf-8', errors='replace')
                optimised = strip_lua_comments(text)
                (dst / f.name).write_text(optimised, encoding='utf-8')
                copied.append(f.name)
    except Exception as e:
        print(f"  ⚠ Error copying scripts: {e}")

    return copied


def write_install_txt(dst: Path, ge_scripts: list):
    """Write installation instructions"""
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


def clean_old_releases():
    """Remove old release folders to prevent permission issues"""
    if OUT_MOD.exists():
        try:
            shutil.rmtree(OUT_MOD, ignore_errors=True)
        except Exception as e:
            print(f"  ⚠ Could not remove old mod folder: {e}")

    if OUT_GE.exists():
        try:
            shutil.rmtree(OUT_GE, ignore_errors=True)
        except Exception as e:
            print(f"  ⚠ Could not remove old scripts folder: {e}")


def main():
    print("=" * 70)
    print("  SW South Warwickshire - Release Builder (OPTIMIZED)")
    print("=" * 70)
    print(f"  Source : {WORK_ROOT}")
    print(f"  Output : {OUT_ROOT}")
    print()

    # Clean old releases
    print("Cleaning old release...")
    clean_old_releases()
    print()

    # Copy map mod
    print("Copying map mod files...")
    before_mb = size_mb(WORK_MAP)
    copy_dir_filtered(WORK_MAP, OUT_MOD)
    after_mb = size_mb(OUT_MOD)
    saved_mb = before_mb - after_mb
    print(f"  ✓ Source size : {before_mb:,.0f} MB")
    print(f"  ✓ Release size: {after_mb:,.0f} MB")
    print(f"  ✓ Saved       : {saved_mb:,.0f} MB ({saved_mb/before_mb*100:.0f}%)")
    print()

    # Copy GE scripts
    print("Copying GE scripts...")
    ge_scripts = copy_ge_scripts(WORK_SCRIPTS, OUT_GE)
    if ge_scripts:
        print(f"  ✓ Copied {len(ge_scripts)} scripts")
        for s in sorted(ge_scripts):
            print(f"    - {s}")
    else:
        print("  ℹ No scripts found")
    print()

    # Write installation instructions
    print("Writing installation instructions...")
    write_install_txt(OUT_ROOT, ge_scripts)
    print("  ✓ INSTALL.txt created")
    print()

    # Create ZIP file
    print("Creating release package...")
    if OUT_ZIP.exists():
        OUT_ZIP.unlink()

    if create_zip(OUT_MOD, OUT_ZIP):
        print()
        print("=" * 70)
        print("  ✅ RELEASE BUILD COMPLETE!")
        print("=" * 70)
        print()
        print("  Next steps:")
        print(f"  1. Verify files in: {OUT_MOD}/")
        print(f"  2. Upload to GitHub:")
        print(f"     gh release create v1.0.20 \\")
        print(f"       --title 'South Warwickshire FS25 v1.0.20' \\")
        print(f"       --notes 'Fixed selling points and placeables' \\")
        print(f"       '{OUT_ZIP}'")
        print()
        print(f"  Files ready for release:")
        print(f"    - {OUT_MOD.name}/  (optimized mod folder)")
        print(f"    - {OUT_ZIP.name}  (ready for download)")
        print("=" * 70)
        return 0
    else:
        print("=" * 70)
        print("  ✗ ZIP creation failed")
        print("=" * 70)
        return 1


if __name__ == "__main__":
    sys.exit(main())
