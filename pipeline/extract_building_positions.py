#!/usr/bin/env python3
"""
extract_building_positions.py — South Warwickshire FS25 map
============================================================
After you've moved buildings in Giants Editor, run this to update placeables.xml
with the new positions and rotations.

Workflow:
    1. Import buildings_preview.i3d into map.i3d in Giants Editor
    2. Move/rotate buildings to where you want them
    3. Save map.i3d
    4. Run this script to extract positions back to placeables.xml

Usage:
    python pipeline/extract_building_positions.py
"""

import xml.etree.ElementTree as ET
from pathlib import Path
import re

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR = Path(__file__).resolve().parent
ROOT_DIR = SCRIPT_DIR.parent
MAP_I3D = ROOT_DIR / "map" / "map" / "map.i3d"
PLACEABLES_XML = ROOT_DIR / "map" / "map" / "config" / "placeables.xml"
BACKUP_XML = ROOT_DIR / "map" / "map" / "config" / "placeables_backup.xml"

# ── Parse map.i3d for building positions ──────────────────────────────────────

print("=" * 60)
print("  Extract Building Positions from Giants Editor")
print("=" * 60)
print()

if not MAP_I3D.exists():
    print(f"ERROR: {MAP_I3D} not found")
    raise SystemExit(1)

print(f"Reading: {MAP_I3D}")
print("  (This may take a moment - large file)")
print()

tree = ET.parse(MAP_I3D)
root = tree.getroot()

# Find all TransformGroups that reference building files
# These will have referenceId pointing to File entries with placeables/ paths

# First, build a map of fileId -> filename
file_map = {}
for file_elem in root.iter("File"):
    fid = file_elem.get("fileId")
    fname = file_elem.get("filename", "")
    if "placeables/" in fname and fid:
        file_map[fid] = fname

print(f"  Found {len(file_map)} building file references")

# Now find TransformGroups with those referenceIds
buildings = []
for tg in root.iter("TransformGroup"):
    ref_id = tg.get("referenceId", "")
    
    # Check if this references a building file
    if ref_id in file_map:
        name = tg.get("name", "")
        translation = tg.get("translation", "0 0 0")
        rotation = tg.get("rotation", "0 0 0")
        
        # Parse translation (x y z)
        trans_parts = translation.split()
        if len(trans_parts) >= 3:
            pos_x = trans_parts[0]
            pos_y = trans_parts[1]
            pos_z = trans_parts[2]
            
            # Parse rotation (rx ry rz)
            rot_parts = rotation.split()
            if len(rot_parts) >= 3:
                rot_x = rot_parts[0]
                rot_y = rot_parts[1]
                rot_z = rot_parts[2]
                
                # Extract the placeable filename from the file path
                # e.g., "../../placeables/FS25_UK_CattleShed/FS25_UK_CattleShed.i3d"
                #   -> need to find the XML file from this mod
                building_path = file_map[ref_id]
                
                buildings.append({
                    "name": name,
                    "file_path": building_path,
                    "pos_x": pos_x,
                    "pos_y": pos_y,
                    "pos_z": pos_z,
                    "rot_x": rot_x,
                    "rot_y": rot_y,
                    "rot_z": rot_z,
                })

print(f"  Found {len(buildings)} building placements")
print()

if not buildings:
    print("No buildings found in map.i3d")
    print("  Did you import buildings_preview.i3d?")
    raise SystemExit(1)

# ── Match i3d paths to placeable XML paths ────────────────────────────────────

# Map from i3d filename -> xml filename (based on your building mods)
I3D_TO_XML = {
    "FS25_UK_MachineShed_3Bay/FS25_MachineShed_3Bay.i3d": "placeables/FS25_UK_MachineShed_3Bay/UK_MachineShed_3Bay.xml",
    "FS25_UK_MachineryShed/placeables/machineShed02/machineShed02.i3d": "placeables/FS25_UK_MachineryShed/placeables/machineShed02/machineShed02.xml",
    "FS25_UK_Grain_MachineryShed/FS25_GrainMachineShed.i3d": "placeables/FS25_UK_Grain_MachineryShed/FS25_GrainMachineShed.xml",
    "FS25_RDM_BritishGrainSheds/shed01.i3d": "placeables/FS25_RDM_BritishGrainSheds/shed01.xml",
    "FS25_RDM_BritishGrainSheds/shed02.i3d": "placeables/FS25_RDM_BritishGrainSheds/shed02.xml",
    "FS25_RDM_BritishGrainSheds/shed03R.i3d": "placeables/FS25_RDM_BritishGrainSheds/shed03R.xml",
    "FS25_RDM_BritishGrainSheds/shed04.i3d": "placeables/FS25_RDM_BritishGrainSheds/shed04.xml",
    "FS25_RDM_BritishGrainSheds/shed01_B.i3d": "placeables/FS25_RDM_BritishGrainSheds/shed01_B.xml",
    "FS25_RDM_BritishGrainSheds/shed02_B.i3d": "placeables/FS25_RDM_BritishGrainSheds/shed02_B.xml",
    "FS25_RDM_BritishGrainSheds/shed01UB.i3d": "placeables/FS25_RDM_BritishGrainSheds/shed01UB.xml",
    "FS25_RDM_BritishGrainSheds/shed02UB.i3d": "placeables/FS25_RDM_BritishGrainSheds/shed02UB.xml",
    "FS25_RDM_BritishGrainSheds/shed01UB_B.i3d": "placeables/FS25_RDM_BritishGrainSheds/shed01UB_B.xml",
    "FS25_RDM_BritishGrainSheds/shed02UB_B.i3d": "placeables/FS25_RDM_BritishGrainSheds/shed02UB_B.xml",
    "FS25_RDM_BritishGrainSheds/shed03RUB.i3d": "placeables/FS25_RDM_BritishGrainSheds/shed03RUB.xml",
    "FS25_UkStyleGrainShed/grainShed.i3d": "placeables/FS25_UkStyleGrainShed/grainShed.xml",
    "FS25_OldEnglishShed/GrainShed.i3d": "placeables/FS25_OldEnglishShed/grain_shed.xml",
    "FS25_UK_CattleShed/FS25_UK_CattleShed.i3d": "placeables/FS25_UK_CattleShed/FS25_UK_CattleShed.xml",
    "FS25_UK_LargeBeefShed/FS25_UK_LargeBeefShed.i3d": "placeables/FS25_UK_LargeBeefShed/FS25_UK_LargeBeefShed.xml",
    "FS25_englishStyleSheepBarn/sheepGoatBarn.i3d": "placeables/FS25_englishStyleSheepBarn/sheepGoatBarn.xml",
    "FS25_UK_BaleShed/FS25_UK_BaleShed.i3d": "placeables/FS25_UK_BaleShed/FS25_UK_BaleShed.xml",
    "FS25_RDM_BritishFieldGates/7Bar.i3d": "placeables/FS25_RDM_BritishFieldGates/7Bar.xml",
}

# Convert building file paths to XML paths
placeable_entries = []
for b in buildings:
    i3d_path = b["file_path"]
    
    # Clean up the path - remove leading ../../map/placeables/ or similar
    for prefix in ["../../map/placeables/", "../placeables/", "placeables/"]:
        if i3d_path.startswith(prefix):
            i3d_path = i3d_path[len(prefix):]
    
    # Find matching XML
    xml_filename = None
    for i3d_pattern, xml_path in I3D_TO_XML.items():
        if i3d_path == i3d_pattern:
            xml_filename = xml_path
            break
    
    if not xml_filename:
        print(f"  WARNING: No XML mapping for {i3d_path}")
        continue
    
    placeable_entries.append({
        "filename": xml_filename,
        "position": f"{b['pos_x']} {b['pos_y']} {b['pos_z']}",
        "rotation": f"{b['rot_x']} {b['rot_y']} {b['rot_z']}",
        "name": b["name"],
    })

print(f"  Mapped {len(placeable_entries)} buildings to placeables")
print()

# ── Backup existing placeables.xml ────────────────────────────────────────────

if PLACEABLES_XML.exists():
    import shutil
    shutil.copy(PLACEABLES_XML, BACKUP_XML)
    print(f"  Backed up existing: {BACKUP_XML.name}")

# ── Write new placeables.xml ──────────────────────────────────────────────────

xml_lines = [
    '<?xml version="1.0" encoding="utf-8" standalone="no" ?>',
    '<placeables version="2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="../../../../shared/xml/schema/savegame_placeables.xsd">',
]

for i, entry in enumerate(placeable_entries):
    xml_lines.append(
        f'    <placeable filename="{entry["filename"]}" '
        f'position="{entry["position"]}" '
        f'rotation="{entry["rotation"]}" '
        f'id="{i + 1}"/>'
    )

xml_lines.append('</placeables>')
xml_lines.append('')

PLACEABLES_XML.write_text('\n'.join(xml_lines))
print(f"  Written: {PLACEABLES_XML}")
print()
print("=" * 60)
print("  DONE!")
print("=" * 60)
print()
print("  Your adjusted positions from Giants Editor have been")
print("  extracted and written to placeables.xml")
print()
print("  The buildings will now appear at these positions in-game.")
print()
