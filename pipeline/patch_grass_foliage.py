#!/usr/bin/env python3
"""
patch_grass_foliage.py — Install grass foliage pack into FS25 map.
Usage:
  python pipeline/patch_grass_foliage.py            # --dry-run (default)
  python pipeline/patch_grass_foliage.py --apply    # extract zip + patch i3d
"""

import argparse
import os
import re
import shutil
import sys
import zipfile
from datetime import datetime

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(SCRIPT_DIR)

GRASS_ZIP  = os.path.join(ROOT, "data", "grass.zip")
GRASS_DEST = os.path.join(ROOT, "map", "map", "foliage", "grass")
MAP_I3D    = os.path.join(ROOT, "map", "map", "map.i3d")
BACKUP_DIR = os.path.join(ROOT, "outputs", "grass_backup")


def check_lfs(path):
    """Return True if the file is a Git-LFS pointer."""
    try:
        with open(path, "rb") as f:
            header = f.read(128)
        return header.startswith(b"version https://git-lfs")
    except OSError:
        return False


def list_zip_keys(zf):
    """Return (dirs, files) lists of zip entries, stripped of __MACOSX."""
    dirs, files = [], []
    for info in zf.infolist():
        name = info.filename
        if name.startswith("__MACOSX"):
            continue
        if info.is_dir():
            dirs.append(name)
        else:
            files.append(name)
    return dirs, files


def strip_leading_grass(name):
    """Strip a leading grass/ component from a zip entry path."""
    if name.startswith("grass/"):
        return name[len("grass/"):]
    return name


def dry_run():
    print("=== patch_grass_foliage.py [DRY-RUN] ===\n")

    # Check zip
    if not os.path.isfile(GRASS_ZIP):
        print(f"  [MISSING] grass.zip not found at: {GRASS_ZIP}")
        print("  Cannot proceed — place grass.zip in data/ and re-run.")
        return
    else:
        print(f"  [OK] grass.zip found: {GRASS_ZIP}")

    with zipfile.ZipFile(GRASS_ZIP, "r") as zf:
        dirs, files = list_zip_keys(zf)
        key_files = [f for f in files if not f.startswith("grass/") or "/" not in f[len("grass/"):]]
        print(f"  Zip contains {len(files)} files, {len(dirs)} dirs (excl. __MACOSX).")
        print("  Key files (first 10):")
        for f in files[:10]:
            dest_name = strip_leading_grass(f)
            print(f"    {f}  →  foliage/grass/{dest_name}")
        if len(files) > 10:
            print(f"    ... and {len(files) - 10} more.")

    # Check destination
    if os.path.isdir(GRASS_DEST):
        existing = os.listdir(GRASS_DEST)
        print(f"\n  [EXISTS] {GRASS_DEST} already exists ({len(existing)} entries).")
    else:
        print(f"\n  [NOT YET] {GRASS_DEST} does not exist — will be created on --apply.")

    # Check map.i3d
    if not os.path.isfile(MAP_I3D):
        print(f"\n  [MISSING] map.i3d not found at: {MAP_I3D}")
    elif check_lfs(MAP_I3D):
        print(f"\n  [LFS] {MAP_I3D} is a Git-LFS pointer.")
        print("  Path patch cannot be applied automatically.")
        print("  MANUAL ACTION: check out the real file then search/replace:")
        print("    $data/foliage/grass/grass.xml  →  foliage/grass/grass.xml")
        print("    ../foliage/grass/grass.xml     →  foliage/grass/grass.xml")
    else:
        print(f"\n  [OK] map.i3d is a real file: {MAP_I3D}")
        with open(MAP_I3D, "r", encoding="utf-8", errors="replace") as f:
            content = f.read()
        hits1 = len(re.findall(r'\$data/foliage/grass/grass\.xml', content))
        hits2 = len(re.findall(r'\.\./foliage/grass/grass\.xml', content))
        print(f"  Would patch: {hits1} occurrence(s) of '$data/foliage/grass/grass.xml'")
        print(f"  Would patch: {hits2} occurrence(s) of '../foliage/grass/grass.xml'")
        print("  → both replaced with: foliage/grass/grass.xml")

    print("\nRun with --apply to install.")


def apply_changes():
    print("=== patch_grass_foliage.py [APPLY] ===\n")

    # 1. Check zip exists
    if not os.path.isfile(GRASS_ZIP):
        print(f"ERROR: grass.zip not found at: {GRASS_ZIP}")
        print("Place grass.zip in the data/ directory and re-run.")
        sys.exit(1)
    print(f"  [OK] grass.zip found.")

    # 2. Backup map.i3d
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_dest = os.path.join(BACKUP_DIR, timestamp)
    os.makedirs(backup_dest, exist_ok=True)

    if os.path.isfile(MAP_I3D):
        backed_up_i3d = os.path.join(backup_dest, "map.i3d")
        shutil.copy2(MAP_I3D, backed_up_i3d)
        print(f"  Backed up map.i3d → {backed_up_i3d}")
    else:
        print(f"  WARNING: map.i3d not found at {MAP_I3D} — skipping backup.")

    # Write restore script
    restore_path = os.path.join(ROOT, "pipeline", "restore_grass_backup.py")
    with open(restore_path, "w") as f:
        f.write(f'''#!/usr/bin/env python3
"""Auto-generated restore script — restores grass installation from backup {timestamp}."""
import os, shutil

BACKUP_I3D = {repr(os.path.join(backup_dest, "map.i3d"))}
MAP_I3D    = {repr(MAP_I3D)}
GRASS_DEST = {repr(GRASS_DEST)}

# Restore map.i3d
if os.path.isfile(BACKUP_I3D):
    shutil.copy2(BACKUP_I3D, MAP_I3D)
    print(f"Restored map.i3d from backup.")
else:
    print(f"WARNING: backup map.i3d not found at {{BACKUP_I3D}}")

# Delete installed grass files
if os.path.isdir(GRASS_DEST):
    shutil.rmtree(GRASS_DEST)
    print(f"Deleted {{GRASS_DEST}}")
else:
    print(f"{{GRASS_DEST}} does not exist — nothing to delete.")

print("Restore complete.")
''')
    print(f"  Restore script written: {restore_path}")

    # 3. Extract grass.zip
    print(f"\n  Extracting grass.zip → {GRASS_DEST} ...")
    os.makedirs(GRASS_DEST, exist_ok=True)
    extracted = 0
    with zipfile.ZipFile(GRASS_ZIP, "r") as zf:
        for info in zf.infolist():
            name = info.filename
            # Skip __MACOSX
            if name.startswith("__MACOSX"):
                continue
            # Skip directory-only entries that start with grass/
            if info.is_dir():
                continue
            # Strip leading grass/
            rel = strip_leading_grass(name)
            if not rel:
                continue
            dest_path = os.path.join(GRASS_DEST, rel)
            os.makedirs(os.path.dirname(dest_path), exist_ok=True)
            with zf.open(info) as src, open(dest_path, "wb") as dst:
                shutil.copyfileobj(src, dst)
            extracted += 1
    print(f"  Extracted {extracted} files.")

    # 4. Patch map.i3d
    if not os.path.isfile(MAP_I3D):
        print(f"\n  WARNING: map.i3d not found at {MAP_I3D} — skipping patch.")
        return

    if check_lfs(MAP_I3D):
        print(f"\n  [LFS] map.i3d is a Git-LFS pointer — cannot patch automatically.")
        print("  MANUAL ACTION: check out the real file then search/replace:")
        print("    $data/foliage/grass/grass.xml  →  foliage/grass/grass.xml")
        print("    ../foliage/grass/grass.xml     →  foliage/grass/grass.xml")
        return

    print(f"\n  Patching {MAP_I3D} ...")
    with open(MAP_I3D, "r", encoding="utf-8", errors="replace") as f:
        original = f.read()

    patched = original
    patched = re.sub(r'\$data/foliage/grass/grass\.xml', 'foliage/grass/grass.xml', patched)
    patched = re.sub(r'\.\./foliage/grass/grass\.xml',   'foliage/grass/grass.xml', patched)

    if patched != original:
        with open(MAP_I3D, "w", encoding="utf-8") as f:
            f.write(patched)
        print("  map.i3d patched successfully.")
    else:
        print("  map.i3d: no matching patterns found — file unchanged.")

    print("\n=== Done ===")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    if args.apply:
        apply_changes()
    else:
        dry_run()


if __name__ == "__main__":
    main()
