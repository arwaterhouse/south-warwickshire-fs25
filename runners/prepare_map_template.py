#!/usr/bin/env python3
"""
prepare_map_template.py — South Warwickshire FS25
==================================================
Run this AFTER scan_my_buildings.py and BEFORE run_maps4fs.py --buildings

What it does:
  1. Downloads the stock FS25 map template from maps4fsdata GitHub
  2. Extracts it
  3. Copies YOUR building .i3d files and their textures into the template
     under /assets/buildings/<mod_name>/
  4. Updates the template ZIP ready for maps4fs to use

Usage:
    python3 prepare_map_template.py
"""

import os, sys, json, shutil, zipfile, urllib.request

SCRIPT_DIR   = os.path.dirname(os.path.abspath(__file__))
SCHEMA_PATH  = os.path.join(SCRIPT_DIR, "fs25_buildings_schema_uk.json")
TEMPLATE_URL = "https://github.com/iwatkot/maps4fsdata/raw/main/fs25/fs25-map-template.zip"
TEMPLATE_ZIP = os.path.join(SCRIPT_DIR, "fs25-map-template.zip")
TEMPLATE_DIR = os.path.join(SCRIPT_DIR, "map_template")
OUTPUT_ZIP   = os.path.join(SCRIPT_DIR, "fs25-map-template-uk.zip")

# ── Load building schema ───────────────────────────────────────────────────────
if not os.path.isfile(SCHEMA_PATH):
    print(f"ERROR: {SCHEMA_PATH} not found. Run scan_my_buildings.py first.")
    sys.exit(1)

with open(SCHEMA_PATH) as f:
    schema = json.load(f)

print("=" * 60)
print("  Preparing custom map template with UK buildings")
print("=" * 60)
print()

# ── Download template if needed ───────────────────────────────────────────────
if not os.path.isfile(TEMPLATE_ZIP):
    print(f"Downloading FS25 map template from maps4fsdata...")
    try:
        urllib.request.urlretrieve(TEMPLATE_URL, TEMPLATE_ZIP)
        print(f"  ✅  Downloaded: {TEMPLATE_ZIP}")
    except Exception as e:
        print(f"  ❌  Download failed: {e}")
        print(f"  → Manually download from:")
        print(f"    {TEMPLATE_URL}")
        print(f"  → Save as: {TEMPLATE_ZIP}")
        sys.exit(1)
else:
    print(f"  ✅  Template already downloaded: {TEMPLATE_ZIP}")

print()

# ── Extract template ───────────────────────────────────────────────────────────
if os.path.isdir(TEMPLATE_DIR):
    shutil.rmtree(TEMPLATE_DIR)
os.makedirs(TEMPLATE_DIR, exist_ok=True)

print(f"Extracting template to {TEMPLATE_DIR}...")
with zipfile.ZipFile(TEMPLATE_ZIP, "r") as z:
    z.extractall(TEMPLATE_DIR)
print(f"  ✅  Extracted")
print()

# ── Copy building files into template ────────────────────────────────────────
print("Copying building .i3d files into template...")
copied = 0
missing = []

for entry in schema:
    schema_path = entry["file"]  # e.g. /assets/buildings/greenShed/greenShed.i3d

    # Work out local source path:
    # The scanner writes the local path into the schema if it found it
    # We look for _local_path — but that's stripped from clean schema.
    # So we need to reconstruct from the mod folders.
    # 
    # Simpler: the schema_path tells us WHERE it should live in the template.
    # The user needs to have their mod files extracted locally.
    # We look for the file relative to MOD_FOLDERS defined in scan_my_buildings.py.
    #
    # For now, look for the i3d basename anywhere inside SCRIPT_DIR subfolders.

    i3d_basename = os.path.basename(schema_path)
    found_local = None

    # Search in script dir tree for a file with this name
    for dirpath, dirnames, filenames in os.walk(SCRIPT_DIR):
        if i3d_basename in filenames:
            candidate = os.path.join(dirpath, i3d_basename)
            # Make sure it's not already inside map_template
            if TEMPLATE_DIR not in candidate:
                found_local = candidate
                break

    if not found_local:
        missing.append((entry["name"], schema_path, i3d_basename))
        print(f"  ⚠️  NOT FOUND locally: {i3d_basename}")
        continue

    # Destination path inside template
    # schema_path = /assets/buildings/xyz/xyz.i3d
    # template dest = map_template/map/assets/buildings/xyz/xyz.i3d
    rel_in_template = schema_path.lstrip("/")  # assets/buildings/xyz/xyz.i3d
    dest_path = os.path.join(TEMPLATE_DIR, "map", rel_in_template)
    os.makedirs(os.path.dirname(dest_path), exist_ok=True)

    shutil.copy2(found_local, dest_path)
    copied += 1

    # Also copy texture files from the same source directory
    src_dir = os.path.dirname(found_local)
    dest_dir = os.path.dirname(dest_path)
    for f in os.listdir(src_dir):
        if f.lower().endswith((".png", ".dds", ".xml", ".i3d.shapes")):
            src_f = os.path.join(src_dir, f)
            dst_f = os.path.join(dest_dir, f)
            if not os.path.isfile(dst_f):
                shutil.copy2(src_f, dst_f)

    print(f"  ✅  {entry['name']:40s} → {rel_in_template}")

print()
print(f"  Copied: {copied}/{len(schema)} buildings")

if missing:
    print()
    print("⚠️  MISSING FILES — these buildings won't be placed:")
    for name, schema_path, basename in missing:
        print(f"   {name}: looking for '{basename}'")
    print()
    print("  To fix: copy those .i3d files (and their textures) into a subfolder")
    print(f"  next to this script so the scanner can find them.")

# ── Repack as new template ZIP ────────────────────────────────────────────────
print()
print(f"Repacking template as {os.path.basename(OUTPUT_ZIP)}...")
with zipfile.ZipFile(OUTPUT_ZIP, "w", zipfile.ZIP_DEFLATED) as zout:
    for dirpath, dirnames, filenames in os.walk(TEMPLATE_DIR):
        for f in filenames:
            abs_path = os.path.join(dirpath, f)
            arc_path = os.path.relpath(abs_path, TEMPLATE_DIR)
            zout.write(abs_path, arc_path)

print(f"  ✅  Written: {OUTPUT_ZIP}")
print()
print("NEXT STEP:")
print("  Run: python3 run_maps4fs.py --buildings")
print("  maps4fs will use fs25-map-template-uk.zip as the template")
