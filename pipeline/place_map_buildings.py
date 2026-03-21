#!/usr/bin/env python3
"""
place_map_buildings.py — South Warwickshire FS25 map
=====================================================
Generates placeables.xml entries for functional buildings.

Reads building footprints from OSM data, matches them to your UK building mods,
and outputs the placeables.xml format that FS25 uses for default map buildings.

The buildings will work fully (doors, animations, etc.) when players load the map.

Usage:
    python pipeline/place_map_buildings.py
"""

import json
import math
import os
from pathlib import Path

# ── Map configuration ─────────────────────────────────────────────────────────
MAP_CENTRE_LAT = 52.089387
MAP_CENTRE_LON = -1.53229
MAP_SIZE_M     = 4096

_lat_per_m = 1.0 / 111320.0
_lon_per_m = 1.0 / (111320.0 * math.cos(math.radians(MAP_CENTRE_LAT)))
_cos_lat   = math.cos(math.radians(MAP_CENTRE_LAT))

LAT_HALF = (MAP_SIZE_M / 2) * _lat_per_m
LON_HALF = (MAP_SIZE_M / 2) * _lon_per_m
LAT_MIN  = MAP_CENTRE_LAT - LAT_HALF
LAT_MAX  = MAP_CENTRE_LAT + LAT_HALF
LON_MIN  = MAP_CENTRE_LON - LON_HALF
LON_MAX  = MAP_CENTRE_LON + LON_HALF

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR    = Path(__file__).resolve().parent
ROOT_DIR      = SCRIPT_DIR.parent
BUILDINGS_GJ  = ROOT_DIR / "fs25_layers" / "fs25_buildings.geojson"
OUTPUT_XML    = ROOT_DIR / "map" / "map" / "config" / "placeables.xml"
OUTPUT_REVIEW = ROOT_DIR / "outputs" / "building_placements.geojson"

# ── Your UK Building Mods ─────────────────────────────────────────────────────
# Each entry: (mod_folder_name, placeable_xml, width, depth, categories)

UK_BUILDINGS = [
    # Machine Sheds
    ("FS25_UK_MachineShed_3Bay", "UK_MachineShed_3Bay.xml", 36, 18, ["farmyard"]),
    ("FS25_UK_MachineryShed", "placeables/machineShed02/machineShed02.xml", 24, 12, ["farmyard"]),
    ("FS25_UK_Grain_MachineryShed", "FS25_GrainMachineShed.xml", 30, 15, ["farmyard"]),
    
    # Grain Sheds (RDM pack - Green/Blue, with/without concrete pad)
    ("FS25_RDM_BritishGrainSheds", "shed01.xml", 20, 12, ["farmyard"]),      # Green, 1 door, concrete
    ("FS25_RDM_BritishGrainSheds", "shed01_B.xml", 20, 12, ["farmyard"]),    # Blue, 1 door, concrete
    ("FS25_RDM_BritishGrainSheds", "shed01UB.xml", 20, 12, ["farmyard"]),    # Green, 1 door, no pad
    ("FS25_RDM_BritishGrainSheds", "shed01UB_B.xml", 20, 12, ["farmyard"]),  # Blue, 1 door, no pad
    ("FS25_RDM_BritishGrainSheds", "shed02.xml", 24, 14, ["farmyard"]),      # Green, 2 doors, concrete
    ("FS25_RDM_BritishGrainSheds", "shed02_B.xml", 24, 14, ["farmyard"]),    # Blue, 2 doors, concrete
    ("FS25_RDM_BritishGrainSheds", "shed02UB.xml", 24, 14, ["farmyard"]),    # Green, 2 doors, no pad
    ("FS25_RDM_BritishGrainSheds", "shed02UB_B.xml", 24, 14, ["farmyard"]),  # Blue, 2 doors, no pad
    ("FS25_RDM_BritishGrainSheds", "shed03R.xml", 28, 16, ["farmyard"]),     # Green, 2 doors + vehicle cover
    ("FS25_RDM_BritishGrainSheds", "shed03RUB.xml", 28, 16, ["farmyard"]),   # Green, 2 doors + cover, no pad
    ("FS25_RDM_BritishGrainSheds", "shed04.xml", 32, 18, ["farmyard"]),      # Sliding door
    ("FS25_UkStyleGrainShed", "grainShed.xml", 25, 15, ["farmyard"]),        # Green, partition wall
    ("FS25_OldEnglishShed", "grain_shed.xml", 20, 10, ["farmyard"]),         # Weathered/old style
    
    # Livestock
    ("FS25_UK_CattleShed", "FS25_UK_CattleShed.xml", 40, 20, ["farmyard", "livestock"]),
    ("FS25_UK_LargeBeefShed", "FS25_UK_LargeBeefShed.xml", 50, 25, ["farmyard", "livestock"]),
    ("FS25_englishStyleSheepBarn", "sheepGoatBarn.xml", 30, 15, ["farmyard", "livestock"]),
    
    # Storage
    ("FS25_UK_BaleShed", "FS25_UK_BaleShed.xml", 20, 12, ["farmyard"]),
    
    # Gates/Misc
    ("FS25_RDM_BritishFieldGates", "7Bar.xml", 4, 1, ["farmyard", "gate"]),
]

# ── EXACT TAG MAPPING ─────────────────────────────────────────────────────────
# If an OSM building has one of these EXACT tags, use that specific model.
# This gives you full control - just tag buildings in your OSM data!
#
# Usage in JOSM/iD: building=machine_shed_3bay (or any tag below)

EXACT_TAG_TO_BUILDING = {
    # ═══════════════════════════════════════════════════════════════════════════
    # MACHINE SHEDS - Open-sided, for tractors/implements
    # ═══════════════════════════════════════════════════════════════════════════
    "machine_shed_3bay":     ("FS25_UK_MachineShed_3Bay", "UK_MachineShed_3Bay.xml"),  # 3 bays, grey metal
    "machine_shed":          ("FS25_UK_MachineryShed", "placeables/machineShed02/machineShed02.xml"),  # Grey metal
    "grain_machine_shed":    ("FS25_UK_Grain_MachineryShed", "FS25_GrainMachineShed.xml"),  # Green, combined
    
    # ═══════════════════════════════════════════════════════════════════════════
    # GRAIN SHEDS - RDM British Grain Sheds (Green or Blue, 1 or 2 doors)
    # ═══════════════════════════════════════════════════════════════════════════
    # Small (1000T) - 1 Door
    "grain_shed_1door_green":       ("FS25_RDM_BritishGrainSheds", "shed01.xml"),     # Green, concrete pad
    "grain_shed_1door_blue":        ("FS25_RDM_BritishGrainSheds", "shed01_B.xml"),   # Blue, concrete pad
    "grain_shed_1door_green_nopad": ("FS25_RDM_BritishGrainSheds", "shed01UB.xml"),   # Green, no pad
    "grain_shed_1door_blue_nopad":  ("FS25_RDM_BritishGrainSheds", "shed01UB_B.xml"), # Blue, no pad
    
    # Medium (2000T) - 2 Doors
    "grain_shed_2door_green":       ("FS25_RDM_BritishGrainSheds", "shed02.xml"),     # Green, concrete pad
    "grain_shed_2door_blue":        ("FS25_RDM_BritishGrainSheds", "shed02_B.xml"),   # Blue, concrete pad
    "grain_shed_2door_green_nopad": ("FS25_RDM_BritishGrainSheds", "shed02UB.xml"),   # Green, no pad
    "grain_shed_2door_blue_nopad":  ("FS25_RDM_BritishGrainSheds", "shed02UB_B.xml"), # Blue, no pad
    
    # Large (3000T) - 2 Doors + Vehicle Cover
    "grain_shed_cover_green":       ("FS25_RDM_BritishGrainSheds", "shed03R.xml"),    # Green, concrete pad
    "grain_shed_cover_green_nopad": ("FS25_RDM_BritishGrainSheds", "shed03RUB.xml"),  # Green, no pad
    
    # XL (2500T) - Sliding Door
    "grain_shed_sliding":           ("FS25_RDM_BritishGrainSheds", "shed04.xml"),     # Sliding door
    
    # Other grain sheds
    "grain_shed":            ("FS25_UkStyleGrainShed", "grainShed.xml"),    # Green, partition wall
    "old_shed":              ("FS25_OldEnglishShed", "grain_shed.xml"),     # Weathered corrugated
    
    # ═══════════════════════════════════════════════════════════════════════════
    # LIVESTOCK - Animal housing
    # ═══════════════════════════════════════════════════════════════════════════
    "cattle_shed":           ("FS25_UK_CattleShed", "FS25_UK_CattleShed.xml"),       # 35 cows, green
    "beef_shed":             ("FS25_UK_LargeBeefShed", "FS25_UK_LargeBeefShed.xml"), # 80 cows, large
    "sheep_barn":            ("FS25_englishStyleSheepBarn", "sheepGoatBarn.xml"),    # Red brick, 35 sheep
    
    # ═══════════════════════════════════════════════════════════════════════════
    # STORAGE
    # ═══════════════════════════════════════════════════════════════════════════
    "bale_shed":             ("FS25_UK_BaleShed", "FS25_UK_BaleShed.xml"),           # Open-sided bale store
    
    # ═══════════════════════════════════════════════════════════════════════════
    # FIELD GATES - 7 Bar British style (width selected in-game)
    # ═══════════════════════════════════════════════════════════════════════════
    "field_gate":            ("FS25_RDM_BritishFieldGates", "7Bar.xml"),
    "field_gate_0.9m":       ("FS25_RDM_BritishFieldGates", "7Bar.xml"),
    "field_gate_1.2m":       ("FS25_RDM_BritishFieldGates", "7Bar.xml"),
    "field_gate_1.5m":       ("FS25_RDM_BritishFieldGates", "7Bar.xml"),
    "field_gate_2.4m":       ("FS25_RDM_BritishFieldGates", "7Bar.xml"),
    "field_gate_3m":         ("FS25_RDM_BritishFieldGates", "7Bar.xml"),
    "field_gate_3.3m":       ("FS25_RDM_BritishFieldGates", "7Bar.xml"),
    "field_gate_3.6m":       ("FS25_RDM_BritishFieldGates", "7Bar.xml"),
    "field_gate_4.2m":       ("FS25_RDM_BritishFieldGates", "7Bar.xml"),
    "field_gate_double":     ("FS25_RDM_BritishFieldGates", "7Bar.xml"),
    
    # ═══════════════════════════════════════════════════════════════════════════
    # STILES - Pedestrian crossing (prefab - static)
    # ═══════════════════════════════════════════════════════════════════════════
    "stile":                 ("FS25_ukStilepack_prefab", "prefabDesc.xml"),
}

# Which OSM building types are farm buildings (for fallback size-based matching)?
# These will be placed using size-matching if not in EXACT_TAG_TO_BUILDING
FARM_BUILDING_TYPES = {
    "agricultural",
    "barn", 
    "farm",
    "farm_auxiliary",
    "shed",
    "silo",
    "storage",
    "cowshed",
    "stable",
    "livestock",
    "greenhouse",
    "hayloft",
}
# Also include all exact tags as valid farm building types
FARM_BUILDING_TYPES.update(EXACT_TAG_TO_BUILDING.keys())

# Category mapping for fallback size-based matching
CATEGORY_MAP = {
    "barn":           "farmyard",
    "farm":           "farmyard", 
    "farm_auxiliary": "farmyard",
    "agricultural":   "farmyard",
    "shed":           "farmyard",
    "silo":           "farmyard",
    "storage":        "farmyard",
    "cowshed":        "livestock",
    "stable":         "livestock",
    "livestock":      "livestock",
    "greenhouse":     "farmyard",
    "hayloft":        "farmyard",
}


def wgs84_to_fs25(lat: float, lon: float) -> tuple[float, float]:
    """WGS84 → FS25 world (x east-positive, z south-positive)."""
    x = (lon - MAP_CENTRE_LON) * 111320.0 * _cos_lat
    z = -(lat - MAP_CENTRE_LAT) * 111320.0
    return round(x, 2), round(z, 2)


def polygon_centroid(ring: list) -> tuple[float, float]:
    """Compute centroid (lon, lat) of a GeoJSON coordinate ring."""
    lons = [c[0] for c in ring]
    lats = [c[1] for c in ring]
    return sum(lons) / len(lons), sum(lats) / len(lats)


def polygon_area_m2(ring: list) -> float:
    """Approximate area of a WGS84 polygon ring in square metres."""
    if len(ring) < 3:
        return 0.0
    xs = [(c[0] - MAP_CENTRE_LON) * 111320.0 * _cos_lat for c in ring]
    ys = [(c[1] - MAP_CENTRE_LAT) * 111320.0 for c in ring]
    n = len(xs)
    area = 0.0
    for i in range(n):
        j = (i + 1) % n
        area += xs[i] * ys[j]
        area -= xs[j] * ys[i]
    return abs(area) / 2.0


def polygon_bbox_m(ring: list, clon: float, clat: float) -> tuple[float, float]:
    """Get width and depth of polygon bounding box in metres."""
    lons_m = [(c[0] - clon) * 111320.0 * _cos_lat for c in ring]
    lats_m = [(c[1] - clat) * 111320.0 for c in ring]
    return max(lons_m) - min(lons_m), max(lats_m) - min(lats_m)


def in_map_bbox(lon: float, lat: float) -> bool:
    return LON_MIN <= lon <= LON_MAX and LAT_MIN <= lat <= LAT_MAX


def exact_tag_match(osm_tag: str) -> dict | None:
    """Check if OSM tag has an exact building match."""
    if osm_tag in EXACT_TAG_TO_BUILDING:
        mod, xml = EXACT_TAG_TO_BUILDING[osm_tag]
        return {"mod": mod, "xml": xml, "exact": True}
    return None


def best_building_match(category: str, fp_w: float, fp_d: float) -> dict | None:
    """Find the best matching building for a footprint (fallback size-based)."""
    # Filter by category
    candidates = [b for b in UK_BUILDINGS if category in b[4]]
    if not candidates:
        candidates = [b for b in UK_BUILDINGS if "farmyard" in b[4]]
    if not candidates:
        return None
    
    def score(b):
        w, d = b[2], b[3]
        # Score based on area difference (allow both orientations)
        dw1 = abs(w - fp_w) + abs(d - fp_d)
        dw2 = abs(w - fp_d) + abs(d - fp_w)
        return min(dw1, dw2)
    
    best = min(candidates, key=score)
    return {
        "mod": best[0],
        "xml": best[1],
        "width": best[2],
        "depth": best[3],
        "exact": False,
    }


# ── Main ──────────────────────────────────────────────────────────────────────

print("=" * 60)
print("  Place Map Buildings — South Warwickshire FS25")
print("=" * 60)
print()

# Try both possible locations for buildings geojson
if not BUILDINGS_GJ.exists():
    alt_path = ROOT_DIR / "outputs" / "fs25_buildings.geojson"
    if alt_path.exists():
        BUILDINGS_GJ = alt_path
    else:
        print(f"ERROR: Cannot find fs25_buildings.geojson")
        print(f"  Tried: {BUILDINGS_GJ}")
        print(f"  Tried: {alt_path}")
        raise SystemExit(1)

with open(BUILDINGS_GJ) as f:
    buildings_gj = json.load(f)

features = buildings_gj.get("features", [])
print(f"  Building footprints: {len(features)}")
print(f"  UK building types:   {len(UK_BUILDINGS)}")
print()

# Process each footprint
placements = []
skipped = 0
exact_matches = 0
size_matches = 0

for feat in features:
    geom = feat.get("geometry", {})
    props = feat.get("properties", {})
    
    gtype = geom.get("type", "")
    if gtype == "Polygon":
        rings = geom["coordinates"]
    elif gtype == "MultiPolygon":
        rings = max(geom["coordinates"], key=lambda p: polygon_area_m2(p[0]))
    else:
        skipped += 1
        continue
    
    outer_ring = rings[0]
    if len(outer_ring) < 3:
        skipped += 1
        continue
    
    clon, clat = polygon_centroid(outer_ring)
    
    if not in_map_bbox(clon, clat):
        skipped += 1
        continue
    
    fp_w, fp_d = polygon_bbox_m(outer_ring, clon, clat)
    area = polygon_area_m2(outer_ring)
    
    # Skip tiny or huge footprints
    if area < 20 or area > 5000:
        skipped += 1
        continue
    
    # Determine building type from OSM
    # Check fs25:building FIRST (custom tag), then fall back to building tag
    fs25_building = str(props.get("fs25:building", "")).lower()
    osm_building = str(props.get("building", "")).lower()
    
    # Use custom tag if present, otherwise use standard building tag
    effective_tag = fs25_building if fs25_building else osm_building
    
    # ONLY place farm buildings - skip houses, garages, shops, etc.
    if effective_tag not in FARM_BUILDING_TYPES and osm_building not in FARM_BUILDING_TYPES:
        skipped += 1
        continue
    
    # FIRST: Check for exact tag match (e.g., fs25:building=cattle_shed or building=cattle_shed)
    match = exact_tag_match(effective_tag)
    
    # FALLBACK: Use size-based matching for generic tags
    if not match:
        category = CATEGORY_MAP.get(effective_tag, CATEGORY_MAP.get(osm_building, "farmyard"))
        match = best_building_match(category, fp_w, fp_d)
    if not match:
        skipped += 1
        continue
    
    fs25_x, fs25_z = wgs84_to_fs25(clat, clon)
    
    if match.get("exact"):
        exact_matches += 1
    else:
        size_matches += 1
    
    placements.append({
        "mod": match["mod"],
        "xml": match["xml"],
        "posX": fs25_x,
        "posZ": fs25_z,
        "footprint_w": round(fp_w, 1),
        "footprint_d": round(fp_d, 1),
        "area": round(area, 1),
        "lon": clon,
        "lat": clat,
        "osm_tag": effective_tag,
        "match_type": "exact" if match.get("exact") else "size",
    })

print(f"  Matched: {len(placements)}")
print(f"    - Exact tag matches: {exact_matches}")
print(f"    - Size-based matches: {size_matches}")
print(f"  Skipped: {skipped}")
print()

# ── Write placeables.xml ──────────────────────────────────────────────────────

xml_lines = [
    '<?xml version="1.0" encoding="utf-8" standalone="no" ?>',
    '<placeables version="2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="../../../../shared/xml/schema/savegame_placeables.xsd">',
]

for i, p in enumerate(placements):
    # Format: relative path from map root - placeables are bundled in map/placeables/
    filename = f"placeables/{p['mod']}/{p['xml']}"
    xml_lines.append(
        f'    <placeable filename="{filename}" '
        f'position="{p["posX"]} 0 {p["posZ"]}" '
        f'rotation="0 0 0" '
        f'id="{i + 1}"/>'
    )

xml_lines.append('</placeables>')
xml_lines.append('')

OUTPUT_XML.parent.mkdir(parents=True, exist_ok=True)
OUTPUT_XML.write_text('\n'.join(xml_lines))
print(f"  Written: {OUTPUT_XML}")

# ── Write review GeoJSON ──────────────────────────────────────────────────────

review_features = []
for p in placements:
    review_features.append({
        "type": "Feature",
        "geometry": {"type": "Point", "coordinates": [p["lon"], p["lat"]]},
        "properties": {
            "mod": p["mod"],
            "xml": p["xml"],
            "fs25_x": p["posX"],
            "fs25_z": p["posZ"],
            "footprint": f"{p['footprint_w']}x{p['footprint_d']}m",
            "area_m2": p["area"],
        }
    })

review_gj = {"type": "FeatureCollection", "features": review_features}
OUTPUT_REVIEW.parent.mkdir(parents=True, exist_ok=True)
with open(OUTPUT_REVIEW, "w") as f:
    json.dump(review_gj, f, indent=2)
print(f"  Review:  {OUTPUT_REVIEW}")

print()
print("=" * 60)
print("  NEXT STEPS")
print("=" * 60)
print()
print("  1. Review building_placements.geojson in QGIS to check positions")
print()
print("  2. Players need these mods installed:")
mods_used = sorted(set(p["mod"] for p in placements))
for mod in mods_used:
    print(f"       - {mod}")
print()
print("  3. OR bundle the building mods with your map:")
print("       - Copy each mod folder into: map/placeables/")
print("       - Update modDesc.xml to include them")
print()
print("  4. The buildings will appear when starting a new save on your map")
print()
