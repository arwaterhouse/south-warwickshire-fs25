#!/usr/bin/env python3
"""
prepare_ge_assets.py — South Warwickshire FS25
===============================================
Run this AFTER scan_my_buildings.py.

For every building in config/fs25_buildings_schema_uk.json it:
  1. Copies the .i3d file + all referenced textures / shapes files into
       outputs/ge_ready/<building_name>/
  2. Rewrites any absolute texture / shape paths inside the .i3d so they are
     relative — Giants Editor can then open the file cleanly without any
     missing-file errors.

The result is a set of self-contained folders you can open directly in GE:
  File → Import → I3D → outputs/ge_ready/<building_name>/<building_name>.i3d

Usage:
    python3 runners/prepare_ge_assets.py
"""

import os, sys, re, shutil, json
import xml.etree.ElementTree as ET
from pathlib import Path

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR  = Path(__file__).resolve().parent
ROOT_DIR    = SCRIPT_DIR.parent
SCHEMA_PATH = ROOT_DIR / "config" / "fs25_buildings_schema_uk.json"
OUTPUT_DIR  = ROOT_DIR / "outputs" / "ge_ready"

# Extensions to copy alongside the i3d
ASSET_EXTS = {".png", ".dds", ".jpg", ".jpeg", ".tga",
              ".shapes", ".i3d.shapes", ".xml", ".lua"}

ET.register_namespace("", "")  # keep GE-style namespace-less XML


# ── Helpers ───────────────────────────────────────────────────────────────────

def find_i3d_on_disk(i3d_name: str, search_root: str) -> str | None:
    """Search search_root recursively for a file named i3d_name."""
    for dirpath, _, filenames in os.walk(search_root):
        if i3d_name in filenames:
            return os.path.join(dirpath, i3d_name)
    return None


def collect_referenced_files(i3d_path: str) -> list[str]:
    """
    Parse the i3d XML and collect every external file it references
    (textures, shape files, etc.) that actually exists on disk.
    """
    src_dir = os.path.dirname(i3d_path)
    found = []

    try:
        tree = ET.parse(i3d_path)
        root = tree.getroot()
    except Exception:
        return found

    # Attributes that can hold file references
    ref_attrs = {"filename", "normalMapFilename", "specularMapFilename",
                 "glossMapFilename", "emissiveMapFilename", "file",
                 "colorMapFilename", "reflectionMapFilename"}

    for elem in root.iter():
        for attr, val in elem.attrib.items():
            if attr in ref_attrs or val.endswith((".png", ".dds", ".shapes",
                                                   ".i3d.shapes", ".xml")):
                # Resolve relative to i3d directory
                candidate = os.path.normpath(os.path.join(src_dir, val))
                if os.path.isfile(candidate):
                    found.append(candidate)

    return found


def rewrite_paths_to_relative(i3d_path: str, new_dir: str) -> None:
    """
    In the copied i3d, replace any absolute or ../../ paths with simple
    relative filenames (basename only) so GE can resolve them from the
    same folder.
    """
    try:
        with open(i3d_path, "r", encoding="utf-8", errors="replace") as fh:
            content = fh.read()
    except Exception as e:
        print(f"    ⚠️  Could not read i3d for path rewrite: {e}")
        return

    # Replace  anything like  ../../../textures/foo.png  or  /absolute/foo.png
    # with just  foo.png  — valid only because we copied everything flat.
    def _to_basename(m: re.Match) -> str:
        quote   = m.group(1)
        val     = m.group(2)
        if val.endswith((".png", ".dds", ".shapes", ".i3d.shapes", ".xml",
                          ".jpg", ".jpeg", ".tga")):
            return f'{quote}{os.path.basename(val)}{quote}'
        return m.group(0)

    # Match quoted attribute values that look like file paths
    content = re.sub(r'(["\'])([^"\']*?(?:\.png|\.dds|\.shapes|\.xml|\.jpg|\.tga))\1',
                     _to_basename, content)

    try:
        with open(i3d_path, "w", encoding="utf-8") as fh:
            fh.write(content)
    except Exception as e:
        print(f"    ⚠️  Could not write rewritten i3d: {e}")


def copy_extra_assets(src_dir: str, dst_dir: str) -> int:
    """Copy any asset files from src_dir into dst_dir that aren't already there."""
    n = 0
    for fname in os.listdir(src_dir):
        ext = os.path.splitext(fname)[1].lower()
        if ext in ASSET_EXTS or fname.lower().endswith(".i3d.shapes"):
            src = os.path.join(src_dir, fname)
            dst = os.path.join(dst_dir, fname)
            if os.path.isfile(src) and not os.path.isfile(dst):
                shutil.copy2(src, dst)
                n += 1
    return n


# ── Main ──────────────────────────────────────────────────────────────────────

if not SCHEMA_PATH.is_file():
    print(f"ERROR: schema not found at {SCHEMA_PATH}")
    print("       Run python3 runners/scan_my_buildings.py first.")
    sys.exit(1)

with open(SCHEMA_PATH) as fh:
    schema = json.load(fh)

# We need to know where the BUILDINGS root lives — grab it from the first entry
# that has an absolute i3d path stored, or fall back to the default.
DEFAULT_BUILDINGS_ROOT = "/Users/alexwaterhouse/Documents/Modelling/FS/BUILDINGS"
BUILDINGS_ROOT = os.environ.get("BUILDINGS_ROOT", DEFAULT_BUILDINGS_ROOT)

print("=" * 60)
print("  South Warwickshire FS25 — Prepare GE Assets")
print("=" * 60)
print(f"  Source : {BUILDINGS_ROOT}")
print(f"  Output : {OUTPUT_DIR}")
print()

if OUTPUT_DIR.exists():
    shutil.rmtree(OUTPUT_DIR)
OUTPUT_DIR.mkdir(parents=True)

ok = 0
skipped = 0

for entry in schema:
    name      = entry.get("name", "unknown")
    i3d_rel   = entry.get("file", "")          # /assets/buildings/X/X.i3d
    i3d_name  = os.path.basename(i3d_rel)

    # ── 1. Locate the source i3d on disk ──────────────────────────────────────
    src_i3d = find_i3d_on_disk(i3d_name, BUILDINGS_ROOT)
    if not src_i3d:
        print(f"  ⚠️  {name:40s} — i3d not found on disk, skipped")
        skipped += 1
        continue

    src_dir = os.path.dirname(src_i3d)

    # ── 2. Create output folder ────────────────────────────────────────────────
    dst_dir = OUTPUT_DIR / name
    dst_dir.mkdir(parents=True, exist_ok=True)

    # ── 3. Copy the i3d ───────────────────────────────────────────────────────
    dst_i3d = dst_dir / i3d_name
    shutil.copy2(src_i3d, dst_i3d)

    # ── 4. Copy all referenced textures / shapes ──────────────────────────────
    refs = collect_referenced_files(src_i3d)
    for ref_path in refs:
        dst_ref = dst_dir / os.path.basename(ref_path)
        if not dst_ref.exists():
            shutil.copy2(ref_path, dst_ref)

    # ── 5. Copy any remaining assets sitting next to the i3d ─────────────────
    copy_extra_assets(src_dir, str(dst_dir))

    # ── 6. Rewrite paths inside the copied i3d → relative ────────────────────
    rewrite_paths_to_relative(str(dst_i3d), str(dst_dir))

    n_files = len(list(dst_dir.iterdir()))
    dims = entry.get("dimensions")
    dims_str = f"{dims[0]}×{dims[1]}m" if dims else "dims unknown"
    print(f"  ✅  {name:40s} ({dims_str}, {n_files} files)")
    ok += 1

print()
print(f"  Exported : {ok} buildings  |  Skipped : {skipped}")
print()
print("NEXT STEPS:")
print("  In Giants Editor: File → Import → I3D")
print(f"  Navigate to:  {OUTPUT_DIR}/<building_name>/<name>.i3d")
print()
print("  To place buildings on the map run:")
print("    python3 pipeline/place_farm_placeables.py")
print("    python3 pipeline/place_windmill.py")
