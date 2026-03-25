#!/usr/bin/env python3
"""
snap_buildings_to_terrain.py — South Warwickshire FS25 map
===========================================================
Reads terrain heightmap and updates building Y positions in placeables.xml
without needing to manually snap in Giants Editor.

This avoids the issue where GE's Snap to Terrain breaks child objects.

Usage:
    python pipeline/snap_buildings_to_terrain.py
"""

import xml.etree.ElementTree as ET
from pathlib import Path
import struct

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR = Path(__file__).resolve().parent
ROOT_DIR = SCRIPT_DIR.parent
PLACEABLES_XML = ROOT_DIR / "map" / "map" / "config" / "placeables.xml"
HEIGHTMAP = ROOT_DIR / "map" / "map" / "data" / "infoLayer_terrainHeight.png"
BACKUP_XML = ROOT_DIR / "map" / "map" / "config" / "placeables_terrain_snap_backup.xml"

# ── Map configuration ─────────────────────────────────────────────────────────
MAP_SIZE_M = 4096

print("=" * 60)
print("  Snap Buildings to Terrain")
print("=" * 60)
print()

if not PLACEABLES_XML.exists():
    print(f"ERROR: {PLACEABLES_XML} not found")
    raise SystemExit(1)

if not HEIGHTMAP.exists():
    print(f"ERROR: Heightmap not found at {HEIGHTMAP}")
    print("  This script needs the terrain heightmap from your map.")
    print("  It's usually at map/map/data/infoLayer_terrainHeight.png")
    raise SystemExit(1)

# ── Load heightmap ────────────────────────────────────────────────────────────

print(f"Loading heightmap: {HEIGHTMAP.name}")

try:
    from PIL import Image
except ImportError:
    print("ERROR: Pillow not installed. Run: pip install Pillow")
    raise SystemExit(1)

hm_img = Image.open(HEIGHTMAP).convert('I;16')  # 16-bit grayscale
hm_data = hm_img.load()
hm_width, hm_height = hm_img.size

print(f"  Heightmap size: {hm_width}×{hm_height}")
print()

def get_terrain_height(x: float, z: float) -> float:
    """Get terrain height at FS25 world coordinates (x, z)."""
    # Convert FS25 world coords to heightmap pixel coords
    # FS25: x=0, z=0 is map centre
    # Heightmap: (0,0) is top-left corner
    
    # FS25 world: -2048 to +2048 (for 4096m map)
    # Heightmap: 0 to hm_width-1
    
    map_half = MAP_SIZE_M / 2
    px = int((x + map_half) / MAP_SIZE_M * hm_width)
    pz = int((z + map_half) / MAP_SIZE_M * hm_height)
    
    # Clamp to valid range
    px = max(0, min(hm_width - 1, px))
    pz = max(0, min(hm_height - 1, pz))
    
    # Read 16-bit value (0-65535), convert to height
    # FS25 heightmap: 32768 = 0m elevation, scale ±512m range typically
    raw_value = hm_data[px, pz]
    height = (raw_value - 32768) / 64.0  # Adjust scale factor as needed
    
    return round(height, 2)

# ── Update placeables ─────────────────────────────────────────────────────────

print(f"Reading: {PLACEABLES_XML.name}")

tree = ET.parse(PLACEABLES_XML)
root = tree.getroot()

updated = 0
for placeable in root.findall(".//placeable"):
    position = placeable.get("position", "0 0 0")
    parts = position.split()
    
    if len(parts) >= 3:
        x = float(parts[0])
        z = float(parts[2])
        
        # Get terrain height
        terrain_y = get_terrain_height(x, z)
        
        # Update position
        new_position = f"{x} {terrain_y} {z}"
        placeable.set("position", new_position)
        updated += 1

print(f"  Updated Y positions: {updated} buildings")
print()

# ── Backup and save ───────────────────────────────────────────────────────────

if PLACEABLES_XML.exists():
    import shutil
    shutil.copy(PLACEABLES_XML, BACKUP_XML)
    print(f"  Backup: {BACKUP_XML.name}")

# Write with proper formatting
ET.indent(root, space="    ")
tree.write(PLACEABLES_XML, encoding="utf-8", xml_declaration=True)

print(f"  Written: {PLACEABLES_XML.name}")
print()
print("=" * 60)
print("  Buildings snapped to terrain!")
print("=" * 60)
print()
print("  All building Y positions updated based on terrain height.")
print("  You can now test in-game without manually snapping in GE.")
print()
