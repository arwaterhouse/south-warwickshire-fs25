#!/usr/bin/env python3
"""
generate_ge_buildings.py — South Warwickshire FS25 map
=======================================================
Generates i3d XML snippets for viewing buildings in Giants Editor.

This creates:
1. buildings_preview.i3d - A standalone i3d file with all buildings as external references
2. buildings_files.xml - File entries to paste into map.i3d <Files> section
3. buildings_scene.xml - TransformGroup entries to paste into map.i3d <Scene> section

Usage:
    python pipeline/generate_ge_buildings.py
    
Then in Giants Editor:
    File → Import → buildings_preview.i3d
    OR merge the XML snippets manually into map.i3d
"""

import json
from pathlib import Path

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR = Path(__file__).resolve().parent
ROOT_DIR = SCRIPT_DIR.parent
PLACEMENTS_GJ = ROOT_DIR / "outputs" / "building_placements.geojson"
OUTPUT_DIR = ROOT_DIR / "outputs" / "GE_buildings"

# ── Load placements ───────────────────────────────────────────────────────────

print("=" * 60)
print("  Generate GE Building Preview — South Warwickshire FS25")
print("=" * 60)
print()

if not PLACEMENTS_GJ.exists():
    print(f"ERROR: {PLACEMENTS_GJ} not found")
    print("  Run place_map_buildings.py first")
    raise SystemExit(1)

with open(PLACEMENTS_GJ) as f:
    placements = json.load(f)

features = placements.get("features", [])
print(f"  Buildings to place: {len(features)}")
print()

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# ── Build mapping of mod/xml to i3d file ──────────────────────────────────────
# We need to find the actual .i3d file for each placeable

BUILDING_I3D_MAP = {
    "FS25_UK_MachineShed_3Bay/UK_MachineShed_3Bay.xml": "FS25_UK_MachineShed_3Bay/FS25_MachineShed_3Bay.i3d",
    "FS25_UK_MachineryShed/placeables/machineShed02/machineShed02.xml": "FS25_UK_MachineryShed/placeables/machineShed02/machineShed02.i3d",
    "FS25_UK_Grain_MachineryShed/FS25_GrainMachineShed.xml": "FS25_UK_Grain_MachineryShed/FS25_GrainMachineShed.i3d",
    "FS25_RDM_BritishGrainSheds/shed01.xml": "FS25_RDM_BritishGrainSheds/shed01.i3d",
    "FS25_RDM_BritishGrainSheds/shed02.xml": "FS25_RDM_BritishGrainSheds/shed02.i3d",
    "FS25_RDM_BritishGrainSheds/shed03.xml": "FS25_RDM_BritishGrainSheds/shed03R.i3d",
    "FS25_RDM_BritishGrainSheds/shed04.xml": "FS25_RDM_BritishGrainSheds/shed04.i3d",
    "FS25_UkStyleGrainShed/grainShed.xml": "FS25_UkStyleGrainShed/grainShed.i3d",
    "FS25_OldEnglishShed/grain_shed.xml": "FS25_OldEnglishShed/GrainShed.i3d",
    "FS25_UK_CattleShed/FS25_UK_CattleShed.xml": "FS25_UK_CattleShed/FS25_UK_CattleShed.i3d",
    "FS25_UK_LargeBeefShed/FS25_UK_LargeBeefShed.xml": "FS25_UK_LargeBeefShed/FS25_UK_LargeBeefShed.i3d",
    "FS25_englishStyleSheepBarn/sheepGoatBarn.xml": "FS25_englishStyleSheepBarn/sheepGoatBarn.i3d",
    "FS25_UK_BaleShed/FS25_UK_BaleShed.xml": "FS25_UK_BaleShed/FS25_UK_BaleShed.i3d",
    "FS25_RDM_BritishFieldGates/7Bar.xml": "FS25_RDM_BritishFieldGates/7Bar.i3d",
}

# ── Generate standalone preview i3d ───────────────────────────────────────────

# Collect unique i3d files needed
file_refs = {}  # path -> fileId
file_id = 1

for feat in features:
    props = feat["properties"]
    mod = props["mod"]
    xml = props["xml"]
    key = f"{mod}/{xml}"
    
    if key in BUILDING_I3D_MAP:
        # Path from outputs/GE_buildings/ to map/placeables/
        i3d_path = f"../../map/placeables/{BUILDING_I3D_MAP[key]}"
        if i3d_path not in file_refs:
            file_refs[i3d_path] = file_id
            file_id += 1

# Build the i3d file
i3d_lines = [
    '<?xml version="1.0" encoding="iso-8859-1"?>',
    '<i3D name="buildings_preview" version="1.6">',
    '  <Asset>',
    '    <Export program="South Warwickshire Map Generator" version="1.0"/>',
    '  </Asset>',
    '',
    '  <Files>',
]

for path, fid in sorted(file_refs.items(), key=lambda x: x[1]):
    i3d_lines.append(f'    <File fileId="{fid}" filename="{path}"/>')

i3d_lines.extend([
    '  </Files>',
    '',
    '  <Scene>',
    '    <TransformGroup name="buildings" translation="0 0 0" nodeId="1">',
])

node_id = 100
for i, feat in enumerate(features):
    props = feat["properties"]
    mod = props["mod"]
    xml = props["xml"]
    key = f"{mod}/{xml}"
    
    if key not in BUILDING_I3D_MAP:
        continue
    
    i3d_path = f"../../map/placeables/{BUILDING_I3D_MAP[key]}"
    fid = file_refs[i3d_path]
    
    x = props["fs25_x"]
    z = props["fs25_z"]
    name = f"building_{i+1:04d}"
    
    i3d_lines.append(
        f'      <TransformGroup name="{name}" '
        f'translation="{x} 0 {z}" rotation="0 0 0" '
        f'referenceId="{fid}" nodeId="{node_id}"/>'
    )
    node_id += 1

i3d_lines.extend([
    '    </TransformGroup>',
    '  </Scene>',
    '</i3D>',
])

preview_path = OUTPUT_DIR / "buildings_preview.i3d"
preview_path.write_text('\n'.join(i3d_lines))
print(f"  Preview i3d:  {preview_path}")

# ── Generate XML snippets for manual merge ────────────────────────────────────

# Files section
files_lines = ['<!-- Add these to map.i3d <Files> section -->']
for path, fid in sorted(file_refs.items(), key=lambda x: x[1]):
    # For map.i3d, paths should be relative to map/map/ folder
    map_relative = path.replace("../placeables/", "../../placeables/")
    files_lines.append(f'<File fileId="{2000 + fid}" filename="{map_relative}"/>')

files_path = OUTPUT_DIR / "buildings_files.xml"
files_path.write_text('\n'.join(files_lines))
print(f"  Files XML:    {files_path}")

# Scene section  
scene_lines = [
    '<!-- Add this inside map.i3d <Scene> section -->',
    '<TransformGroup name="map_buildings" translation="0 0 0">',
]

for i, feat in enumerate(features):
    props = feat["properties"]
    mod = props["mod"]
    xml = props["xml"]
    key = f"{mod}/{xml}"
    
    if key not in BUILDING_I3D_MAP:
        continue
    
    i3d_path = f"../../map/placeables/{BUILDING_I3D_MAP[key]}"
    fid = file_refs[i3d_path]
    
    x = props["fs25_x"]
    z = props["fs25_z"]
    name = f"building_{i+1:04d}"
    
    scene_lines.append(
        f'  <TransformGroup name="{name}" '
        f'translation="{x} 0 {z}" rotation="0 0 0" '
        f'referenceId="{2000 + fid}"/>'
    )

scene_lines.append('</TransformGroup>')

scene_path = OUTPUT_DIR / "buildings_scene.xml"
scene_path.write_text('\n'.join(scene_lines))
print(f"  Scene XML:    {scene_path}")

print()
print("=" * 60)
print("  HOW TO VIEW IN GIANTS EDITOR")
print("=" * 60)
print()
print("  Option 1 - Import preview file:")
print(f"    1. Open your map.i3d in Giants Editor")
print(f"    2. File -> Import")
print(f"    3. Select: {preview_path}")
print(f"    4. Buildings will appear as a 'buildings' transform group")
print()
print("  Option 2 - Merge XML manually:")
print(f"    1. Copy contents of buildings_files.xml into map.i3d <Files> section")
print(f"    2. Copy contents of buildings_scene.xml into map.i3d <Scene> section")
print(f"    3. Reload map.i3d in Giants Editor")
print()
print("  Note: Y positions are 0 - use 'Snap to Terrain' in GE to fix heights")
print()
