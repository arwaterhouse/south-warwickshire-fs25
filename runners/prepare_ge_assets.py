#!/usr/bin/env python3
"""
prepare_ge_assets.py — South Warwickshire FS25
===============================================
Scans BUILDINGS_ROOT directly (no schema required) and for every .i3d found:
  1. Copies the .i3d + all referenced textures/shapes into
       outputs/ge_ready/<folder_label>/<building_name>/
  2. Rewrites absolute/relative texture paths inside the .i3d to simple
     basenames so Giants Editor can open the file without missing-file errors.

Usage:
    python3 runners/prepare_ge_assets.py
    python3 runners/prepare_ge_assets.py /path/to/other/BUILDINGS
"""

import os, sys, re, shutil
import xml.etree.ElementTree as ET
from pathlib import Path

# ── Config ────────────────────────────────────────────────────────────────────
DEFAULT_BUILDINGS_ROOT = "/Users/alexwaterhouse/Documents/Modelling/FS/BUILDINGS"
BUILDINGS_ROOT = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_BUILDINGS_ROOT
BUILDINGS_ROOT = os.path.expanduser(BUILDINGS_ROOT)

SCRIPT_DIR = Path(__file__).resolve().parent
ROOT_DIR   = SCRIPT_DIR.parent
OUTPUT_DIR = ROOT_DIR / "outputs" / "ge_ready"

ASSET_EXTS = {".png", ".dds", ".jpg", ".jpeg", ".tga", ".xml", ".lua"}
SHAPE_EXTS = {".shapes"}   # covers both .shapes and .i3d.shapes

SKIP_DIRS  = {"textures", "shaders", "materials", "sounds", "effects", "scripts"}


# ── Folder discovery (mirrors scan_my_buildings logic) ───────────────────────

def has_building_files(folder: str) -> bool:
    try:
        for f in os.listdir(folder):
            if f.lower().endswith((".i3d", ".xml")) and f.lower() != "moddesc.xml":
                return True
    except PermissionError:
        pass
    return False


def discover_mod_folders(root: str) -> list[tuple[str, str]]:
    """(label, path) for every building folder under root, two levels deep."""
    result = []
    for cat in sorted(os.scandir(root), key=lambda e: e.name):
        if not cat.is_dir() or cat.name.startswith("."):
            continue
        if has_building_files(cat.path):
            result.append((cat.name, cat.path))
        else:
            for sub in sorted(os.scandir(cat.path), key=lambda e: e.name):
                if sub.is_dir() and not sub.name.startswith("."):
                    result.append((f"{cat.name}/{sub.name}", sub.path))
    return result


def find_i3d_files(folder: str) -> list[str]:
    results = []
    for root_dir, dirs, files in os.walk(folder):
        dirs[:] = [d for d in dirs if d.lower() not in SKIP_DIRS]
        for f in files:
            if f.lower().endswith(".i3d"):
                results.append(os.path.join(root_dir, f))
    return results


# ── Asset helpers ─────────────────────────────────────────────────────────────

def collect_referenced_files(i3d_path: str) -> list[str]:
    """Parse i3d XML and collect every external file it references on disk."""
    src_dir = os.path.dirname(i3d_path)
    found = []
    ref_attrs = {
        "filename", "normalMapFilename", "specularMapFilename",
        "glossMapFilename", "emissiveMapFilename", "file",
        "colorMapFilename", "reflectionMapFilename",
    }
    try:
        tree = ET.parse(i3d_path)
        for elem in tree.getroot().iter():
            for attr, val in elem.attrib.items():
                is_ref = (attr in ref_attrs or
                          any(val.lower().endswith(e)
                              for e in (".png", ".dds", ".shapes", ".i3d.shapes",
                                        ".xml", ".jpg", ".jpeg", ".tga")))
                if is_ref:
                    candidate = os.path.normpath(os.path.join(src_dir, val))
                    if os.path.isfile(candidate) and candidate not in found:
                        found.append(candidate)
    except Exception:
        pass
    return found


def copy_siblings(src_dir: str, dst_dir: str) -> None:
    """Copy all asset files sitting next to the i3d into dst_dir."""
    for fname in os.listdir(src_dir):
        src = os.path.join(src_dir, fname)
        if not os.path.isfile(src):
            continue
        ext = os.path.splitext(fname)[1].lower()
        is_shape = fname.lower().endswith(".i3d.shapes") or ext in SHAPE_EXTS
        if ext in ASSET_EXTS or is_shape:
            dst = os.path.join(dst_dir, fname)
            if not os.path.exists(dst):
                shutil.copy2(src, dst)


def rewrite_paths_to_relative(i3d_path: str) -> None:
    """Replace any ../../ or absolute paths in the i3d with bare basenames."""
    try:
        with open(i3d_path, "r", encoding="utf-8", errors="replace") as fh:
            content = fh.read()
    except Exception as e:
        print(f"    ⚠️  Cannot read for path rewrite: {e}")
        return

    file_exts = r"\.(?:png|dds|jpg|jpeg|tga|shapes|xml)"

    def _basename(m: re.Match) -> str:
        q, val = m.group(1), m.group(2)
        return f"{q}{os.path.basename(val)}{q}"

    content = re.sub(
        rf'(["\'])([^"\']+?{file_exts})\1',
        _basename,
        content,
        flags=re.IGNORECASE,
    )

    try:
        with open(i3d_path, "w", encoding="utf-8") as fh:
            fh.write(content)
    except Exception as e:
        print(f"    ⚠️  Cannot write rewritten i3d: {e}")


# ── Main ──────────────────────────────────────────────────────────────────────

if not os.path.isdir(BUILDINGS_ROOT):
    print(f"ERROR: BUILDINGS_ROOT not found: {BUILDINGS_ROOT}")
    print("       Run on your Mac, or pass the path as an argument.")
    sys.exit(1)

print("=" * 60)
print("  South Warwickshire FS25 — Prepare GE Assets")
print("=" * 60)
print(f"  Source : {BUILDINGS_ROOT}")
print(f"  Output : {OUTPUT_DIR}")
print()

if OUTPUT_DIR.exists():
    shutil.rmtree(OUTPUT_DIR)
OUTPUT_DIR.mkdir(parents=True)

mod_folders = discover_mod_folders(BUILDINGS_ROOT)
print(f"  Found {len(mod_folders)} building folder(s)\n")

ok = skipped = 0

for label, folder_path in mod_folders:
    i3d_files = find_i3d_files(folder_path)
    if not i3d_files:
        print(f"  ⚠️  {label} — no .i3d files found, skipped")
        skipped += 1
        continue

    # Use label as the output folder name (replace / with _)
    out_label = label.replace("/", "_")

    for i3d_src in i3d_files:
        name     = os.path.splitext(os.path.basename(i3d_src))[0]
        dst_dir  = OUTPUT_DIR / out_label / name
        dst_dir.mkdir(parents=True, exist_ok=True)

        # Copy i3d
        dst_i3d = dst_dir / os.path.basename(i3d_src)
        shutil.copy2(i3d_src, dst_i3d)

        # Copy all referenced external files
        for ref in collect_referenced_files(i3d_src):
            dst_ref = dst_dir / os.path.basename(ref)
            if not dst_ref.exists():
                shutil.copy2(ref, dst_ref)

        # Copy anything else sitting next to the i3d
        copy_siblings(os.path.dirname(i3d_src), str(dst_dir))

        # Rewrite paths inside the copied i3d → relative basenames
        rewrite_paths_to_relative(str(dst_i3d))

        n_files = len(list(dst_dir.iterdir()))
        print(f"  ✅  {label}/{name:35s} ({n_files} files)")
        ok += 1

print()
print(f"  Exported : {ok} building(s)  |  Skipped : {skipped}")
print()
print("NEXT STEPS:")
print("  In Giants Editor: File → Import → I3D")
print(f"  Navigate to:  {OUTPUT_DIR}/<folder>/<name>/<name>.i3d")
print()
print("  To place buildings on the map run:")
print("    python3 pipeline/place_farm_placeables.py")
print("    python3 pipeline/place_windmill.py")
