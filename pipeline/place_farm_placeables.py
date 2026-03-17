#!/usr/bin/env python3
"""
place_farm_placeables.py — South Warwickshire FS25 map
=======================================================
Reads building footprints from outputs/fs25_buildings.geojson, matches each
one to an appropriate entry in config/fs25_buildings_schema_uk.json, and
writes a Giants Editor placeables XML snippet.

The script converts WGS84 centroids to FS25 world-space coordinates and
chooses the best-matching schema building for each footprint based on
footprint area and building category.

Outputs:
    outputs/farm_placeables.xml       — Giants Editor placeables XML
    outputs/farm_placeables.geojson   — GeoJSON review overlay

Usage:
    python3 pipeline/place_farm_placeables.py
"""

import json
import math
import xml.etree.ElementTree as ET
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
BUILDINGS_GJ  = ROOT_DIR / "outputs" / "fs25_buildings.geojson"
SCHEMA_PATH   = ROOT_DIR / "config" / "fs25_buildings_schema_uk.json"
OUTPUT_XML    = ROOT_DIR / "outputs" / "farm_placeables.xml"
OUTPUT_GJ     = ROOT_DIR / "outputs" / "farm_placeables.geojson"

# ── Farmyard category keywords — OSM building tags → schema categories ────────
# Extend this if your OSM data uses different tagging.
CATEGORY_MAP = {
    "barn":         "farmyard",
    "farm":         "farmyard",
    "farm_auxiliary": "farmyard",
    "shed":         "farmyard",
    "silo":         "farmyard",
    "storage":      "farmyard",
    "industrial":   "industrial",
    "house":        "residential",
    "residential":  "residential",
    "commercial":   "commercial",
    "retail":       "retail",
    "church":       "religious",
    "chapel":       "religious",
    "yes":          "farmyard",   # untagged buildings default to farmyard
    "":             "farmyard",
}


# ── Helpers ───────────────────────────────────────────────────────────────────

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
    # Shoelace on projected coords
    xs = [(c[0] - MAP_CENTRE_LON) * 111320.0 * _cos_lat for c in ring]
    ys = [(c[1] - MAP_CENTRE_LAT) * 111320.0 for c in ring]
    n  = len(xs)
    area = 0.0
    for i in range(n):
        j = (i + 1) % n
        area += xs[i] * ys[j]
        area -= xs[j] * ys[i]
    return abs(area) / 2.0


def in_map_bbox(lon: float, lat: float) -> bool:
    return LON_MIN <= lon <= LON_MAX and LAT_MIN <= lat <= LAT_MAX


def best_schema_match(
    category: str,
    footprint_w: float,
    footprint_d: float,
    schema: list[dict],
) -> dict | None:
    """Return the schema entry whose dimensions best match the footprint."""
    candidates = [
        s for s in schema
        if category in s.get("categories", [])
        and s["width"] > 0 and s["depth"] > 0
    ]
    if not candidates:
        # Fall back to any farmyard building
        candidates = [s for s in schema if s["width"] > 0 and s["depth"] > 0]
    if not candidates:
        return None

    def score(s: dict) -> float:
        # Prefer buildings whose dimensions are close to the footprint.
        # Use minimum of (w,d) and (d,w) orientations.
        dw1 = abs(s["width"] - footprint_w) + abs(s["depth"] - footprint_d)
        dw2 = abs(s["width"] - footprint_d) + abs(s["depth"] - footprint_w)
        return min(dw1, dw2)

    return min(candidates, key=score)


# ── Load data ─────────────────────────────────────────────────────────────────

print("=" * 60)
print("  Place Farm Placeables — South Warwickshire FS25")
print("=" * 60)
print()

if not BUILDINGS_GJ.exists():
    print(f"ERROR: {BUILDINGS_GJ} not found.")
    print("  Run the OSM extraction pipeline first to generate fs25_buildings.geojson.")
    raise SystemExit(1)

if not SCHEMA_PATH.exists():
    print(f"ERROR: {SCHEMA_PATH} not found.")
    print("  Run runners/scan_my_buildings.py first, or check config/.")
    raise SystemExit(1)

with open(BUILDINGS_GJ) as f:
    buildings_gj = json.load(f)

with open(SCHEMA_PATH) as f:
    schema = json.load(f)

features    = buildings_gj.get("features", [])
valid_schema = [s for s in schema if s["width"] > 0 and s["depth"] > 0]

print(f"  Building footprints : {len(features)}")
print(f"  Schema entries      : {len(schema)}  ({len(valid_schema)} with valid dims)")
print()

if not valid_schema:
    print("WARNING: No schema entries with valid dimensions.")
    print("  Run scan_my_buildings.py and fill in missing dimensions first.")

# ── Build placeables ──────────────────────────────────────────────────────────

map_elem       = ET.Element("map")
placeables_elem = ET.SubElement(map_elem, "placeables")

placed      = 0
skipped     = 0
gj_features = []

for feat in features:
    geom = feat.get("geometry", {})
    props = feat.get("properties", {})

    gtype = geom.get("type", "")
    if gtype == "Polygon":
        rings = geom["coordinates"]
    elif gtype == "MultiPolygon":
        # Use the largest ring
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

    # Approximate footprint bounding box in metres
    lons_m = [(c[0] - clon) * 111320.0 * _cos_lat for c in outer_ring]
    lats_m = [(c[1] - clat) * 111320.0             for c in outer_ring]
    fp_w   = max(lons_m) - min(lons_m)
    fp_d   = max(lats_m) - min(lats_m)
    area   = polygon_area_m2(outer_ring)

    # Determine category from OSM tags
    osm_building = str(props.get("building", "")).lower()
    osm_type     = str(props.get("fs25_type", "")).lower()
    raw_cat      = osm_building or osm_type or ""
    fs25_cat     = CATEGORY_MAP.get(raw_cat, "farmyard")

    # Skip tiny slivers and very large (non-placeable) areas
    if area < 10 or area > 10000:
        skipped += 1
        continue

    match = best_schema_match(fs25_cat, fp_w, fp_d, valid_schema)
    if not match:
        skipped += 1
        continue

    fs25_x, fs25_z = wgs84_to_fs25(clat, clon)
    name = props.get("name", match["name"])

    attrib = {
        "filename": match["file"],
        "posX":     str(fs25_x),
        "posY":     "0",
        "posZ":     str(fs25_z),
        "rotX":     "0",
        "rotY":     "0",
        "rotZ":     "0",
        "name":     name,
    }
    ET.SubElement(placeables_elem, "placeable", attrib)

    gj_features.append({
        "type": "Feature",
        "geometry": {"type": "Point", "coordinates": [clon, clat]},
        "properties": {
            "name":       name,
            "schema_name": match["name"],
            "category":   fs25_cat,
            "fs25_x":     fs25_x,
            "fs25_z":     fs25_z,
            "footprint_w": round(fp_w, 1),
            "footprint_d": round(fp_d, 1),
            "area_m2":    round(area, 1),
        },
    })
    placed += 1

# ── Write outputs ─────────────────────────────────────────────────────────────

ET.indent(map_elem, space="  ")
xml_str  = ET.tostring(map_elem, encoding="unicode", xml_declaration=False)
full_xml = '<?xml version="1.0" encoding="utf-8" standalone="no" ?>\n' + xml_str + "\n"

OUTPUT_XML.parent.mkdir(parents=True, exist_ok=True)
OUTPUT_XML.write_text(full_xml)
print(f"  XML     → {OUTPUT_XML}")

gj_out = {"type": "FeatureCollection", "features": gj_features}
with open(OUTPUT_GJ, "w") as f:
    json.dump(gj_out, f, indent=2)
print(f"  GeoJSON → {OUTPUT_GJ}")

print()
print("=" * 60)
print(f"  Placed  : {placed}")
print(f"  Skipped : {skipped}  (out-of-bounds, tiny slivers, or no schema match)")
print("=" * 60)
print()
print("NEXT STEPS:")
print("  1. Review farm_placeables.geojson in QGIS or geojson.io to check placements")
print("  2. Open map.i3d in Giants Editor")
print(f"  3. File → Merge → select {OUTPUT_XML.name}")
print("     (or copy the <placeable> entries into your map.i3d placeables section)")
print("  4. Select all placed buildings and run 'Snap to Terrain' to fix Y positions")
print("  5. Manually rotate / reposition buildings that don't align with the road layout")
