#!/usr/bin/env python3
"""
place_windmill.py — South Warwickshire FS25 map
================================================
Extracts windmill nodes from the OSM data, converts their WGS84 coordinates
to FS25 world-space (metres from map centre), and writes:

  outputs/windmill_placeables.xml   — Giants Editor placeables XML snippet
  outputs/windmill_placeables.geojson — review overlay

The windmill placeable used is the stock FS25 EU decorative windmill.
Swap the filename to a mod path if you have a better windmill model.

Usage:
    python3 pipeline/place_windmill.py
"""

import json
import math
import xml.etree.ElementTree as ET
from pathlib import Path

# ── Map configuration ─────────────────────────────────────────────────────────
MAP_CENTRE_LAT = 52.089387
MAP_CENTRE_LON = -1.53229
MAP_SIZE_M     = 4096

_cos_lat = math.cos(math.radians(MAP_CENTRE_LAT))

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR  = Path(__file__).resolve().parent
ROOT_DIR    = SCRIPT_DIR.parent
OSM_FILE    = ROOT_DIR / "data" / "custom_osm.osm"
OUTPUT_XML  = ROOT_DIR / "outputs" / "windmill_placeables.xml"
OUTPUT_GJ   = ROOT_DIR / "outputs" / "windmill_placeables.geojson"

# FS25 placeable to use for decorative windmills.
# Replace with a mod path e.g. "$modDir/placeables/Windmill/windmill.i3d"
# if you have a better UK windmill asset.
WINDMILL_I3D = "$data/placeables/windmill/windmill01.i3d"


# ── Coordinate helper ─────────────────────────────────────────────────────────

def wgs84_to_fs25(lat: float, lon: float) -> tuple[float, float]:
    """Convert WGS84 lat/lon to FS25 world coordinates (x, z).

    FS25 convention:
      X = east  (positive = east of map centre)
      Z = south (positive = south of map centre, because FS25 Z increases
                 going south while latitude increases going north)
    """
    x = (lon - MAP_CENTRE_LON) * 111320.0 * _cos_lat
    z = -(lat - MAP_CENTRE_LAT) * 111320.0
    return round(x, 2), round(z, 2)


# ── Parse OSM ────────────────────────────────────────────────────────────────

print("=" * 60)
print("  Place Windmill — South Warwickshire FS25")
print("=" * 60)
print()
print(f"Reading {OSM_FILE.name}...")

tree = ET.parse(OSM_FILE)
root = tree.getroot()

# Build node id → (lat, lon) lookup
nodes = {
    n.get("id"): (float(n.get("lat")), float(n.get("lon")))
    for n in root.findall("node")
}

windmills = []

# 1. Standalone windmill nodes
for node in root.findall("node"):
    tags = {t.get("k"): t.get("v") for t in node.findall("tag")}
    if tags.get("man_made") == "windmill":
        nid  = node.get("id")
        lat  = float(node.get("lat"))
        lon  = float(node.get("lon"))
        name = tags.get("name", f"Windmill_{nid}")
        windmills.append({"name": name, "lat": lat, "lon": lon})

# 2. Windmill ways — use centroid of first / only way
for way in root.findall("way"):
    tags = {t.get("k"): t.get("v") for t in way.findall("tag")}
    if tags.get("man_made") == "windmill":
        wid   = way.get("id")
        name  = tags.get("name", f"Windmill_way{wid}")
        coords = [nodes[nd.get("ref")]
                  for nd in way.findall("nd")
                  if nd.get("ref") in nodes]
        if not coords:
            continue
        lat = sum(c[0] for c in coords) / len(coords)
        lon = sum(c[1] for c in coords) / len(coords)
        windmills.append({"name": name, "lat": lat, "lon": lon})

print(f"  Windmills found in OSM: {len(windmills)}")
print()

if not windmills:
    print("No windmill nodes found in custom_osm.osm — nothing to do.")
    raise SystemExit(0)

# ── Build XML placeables ──────────────────────────────────────────────────────

map_elem = ET.Element("map")
ET.SubElement(map_elem, "placeables")  # placeholder header comment not needed
placeables_elem = map_elem.find("placeables")

gj_features = []

for wm in windmills:
    fs25_x, fs25_z = wgs84_to_fs25(wm["lat"], wm["lon"])

    print(f"  {wm['name']}")
    print(f"    lat={wm['lat']:.6f}  lon={wm['lon']:.6f}")
    print(f"    FS25 world  x={fs25_x}  z={fs25_z}")
    print()

    # XML entry (posY=0 — Giants Editor will snap to terrain height on load)
    attrib = {
        "filename": WINDMILL_I3D,
        "posX":     str(fs25_x),
        "posY":     "0",
        "posZ":     str(fs25_z),
        "rotX":     "0",
        "rotY":     "0",
        "rotZ":     "0",
        "name":     wm["name"],
    }
    ET.SubElement(placeables_elem, "placeable", attrib)

    # GeoJSON feature for preview
    gj_features.append({
        "type": "Feature",
        "geometry": {
            "type": "Point",
            "coordinates": [wm["lon"], wm["lat"]],
        },
        "properties": {
            "name":   wm["name"],
            "fs25_x": fs25_x,
            "fs25_z": fs25_z,
        },
    })

# ── Write outputs ─────────────────────────────────────────────────────────────

# Pretty-print XML
ET.indent(map_elem, space="  ")
xml_str = ET.tostring(map_elem, encoding="unicode", xml_declaration=False)
full_xml = '<?xml version="1.0" encoding="utf-8" standalone="no" ?>\n' + xml_str + "\n"

OUTPUT_XML.parent.mkdir(parents=True, exist_ok=True)
OUTPUT_XML.write_text(full_xml)
print(f"  XML  → {OUTPUT_XML}")

gj_out = {"type": "FeatureCollection", "features": gj_features}
with open(OUTPUT_GJ, "w") as f:
    json.dump(gj_out, f, indent=2)
print(f"  GeoJSON → {OUTPUT_GJ}")

print()
print("=" * 60)
print(f"  Total windmills placed: {len(windmills)}")
print("=" * 60)
print()
print("NEXT STEPS:")
print("  1. Open map.i3d in Giants Editor")
print(f"  2. File → Merge → select {OUTPUT_XML.name}")
print("     (or manually copy the <placeable> entries into your map.i3d placeables section)")
print("  3. Select the placed windmill, press F (focus) to jump to it")
print("  4. Use Terrain Snap so it sits on the ground correctly")
print("  5. If you have a better windmill .i3d, update WINDMILL_I3D at the top of this script")
