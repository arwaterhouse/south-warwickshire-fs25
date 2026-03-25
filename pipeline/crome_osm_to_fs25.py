#!/usr/bin/env python3
"""
CROME 2024 + OSM → FS25 Map Pipeline
South Warwickshire (4x4km centred at 52.089387, -1.532290)

Combines:
  - DEFRA CROME crop data  → field type assignments
  - OSM data               → roads, hedges, buildings, water, tracks

Outputs (all WGS84 GeoJSON, clipped to map bbox):
  fs25_fields.geojson       - Arable/grass fields with FS25 crop type
  fs25_hedges.geojson       - Hedge lines (barrier=hedge)
  fs25_roads.geojson        - Roads and farm tracks with type classification
  fs25_buildings.geojson    - Buildings with type (farmhouse, barn, house, etc.)
  fs25_water.geojson        - Streams, ponds, ditches
  fs25_forest.geojson       - Woodland/forest areas
  fs25_summary.json         - Stats for maps4fs config generation

Usage:
    python3 crome_osm_to_fs25.py \\
        --crome  crome_south_warwickshire_fs25.geojson \\
        --osm    custom_osm.osm \\
        --output ./fs25_layers/
"""

import json, math, argparse, os, xml.etree.ElementTree as ET
from pathlib import Path
from collections import defaultdict

# ── Map configuration ──────────────────────────────────────────────────────────
# Must match coordinates= in runners/run_maps4fs.py and MAP_LAT/LON in generate_hedges.py
MAP_CENTRE_LAT  = 52.089387
MAP_CENTRE_LON  = -1.532290
MAP_HALF_KM     = 2.0          # 4x4 km map
LAT_PER_KM      = 1 / 111.32
LON_PER_KM      = 1 / (111.32 * math.cos(math.radians(MAP_CENTRE_LAT)))

MAP_LAT_MIN = MAP_CENTRE_LAT - MAP_HALF_KM * LAT_PER_KM
MAP_LAT_MAX = MAP_CENTRE_LAT + MAP_HALF_KM * LAT_PER_KM
MAP_LON_MIN = MAP_CENTRE_LON - MAP_HALF_KM * LON_PER_KM
MAP_LON_MAX = MAP_CENTRE_LON + MAP_HALF_KM * LON_PER_KM

# ── FS25 crop mapping (from CROME lucode) ──────────────────────────────────────
LUCODE_TO_FS25 = {
    "AC01": "wheat",        "AC03": "barley",        "AC06": "oilseedRape",
    "AC17": "barley",       "AC19": "oat",           "AC32": "maize",
    "AC37": "sugarBeet",    "AC38": "potato",        "AC44": "soybean",
    "AC63": "wheat",        "AC65": "wheat",         "AC66": None,          # fallow
    "AC67": "carrot",       "AC68": "grass",
    "LG03": "grass",        "LG07": "grass",         "LG14": "grass",
    "LG20": "grass",        "LG21": "grass",
    "NA01": None,                                                            # woodland
    "PG01": "grass",        "TG01": "grass",         "WO12": None,          # woodland
    "FA01": None,                                                            # farmyard
}

LUCODE_CATEGORY = {
    "AC01":"arable",  "AC03":"arable",  "AC06":"arable",  "AC17":"arable",
    "AC19":"arable",  "AC32":"arable",  "AC37":"root",    "AC38":"root",
    "AC44":"arable",  "AC63":"arable",  "AC65":"arable",  "AC66":"fallow",
    "AC67":"vegetable","AC68":"grassland",
    "LG03":"grassland","LG07":"grassland","LG14":"grassland",
    "LG20":"grassland","LG21":"grassland","NA01":"woodland",
    "PG01":"grassland","TG01":"grassland","WO12":"woodland","FA01":"farmyard",
}

# ── OSM highway → FS25 road classification ─────────────────────────────────────
HIGHWAY_FS25 = {
    "motorway": None, "trunk": None,
    "primary":     {"fs25_type": "road",        "width": 10.0},
    "secondary":   {"fs25_type": "road",        "width": 10.0},
    "tertiary":    {"fs25_type": "road",        "width": 10.0},
    "unclassified":{"fs25_type": "road",        "width": 4.5},
    "residential": {"fs25_type": "road",        "width": 4.0},
    "service":     {"fs25_type": "service",     "width": 3.0},
    "track":       {"fs25_type": "dirt_track",  "width": 3.5},
    "bridleway":   {"fs25_type": "dirt_track",  "width": 2.5},
    "footway":     {"fs25_type": "footpath",    "width": 1.5},
    "path":        {"fs25_type": "footpath",    "width": 1.5},
    "steps":       None,
    "raceway":     {"fs25_type": "road",        "width": 8.5},
}

# ── OSM building → FS25 building type ─────────────────────────────────────────
def classify_building(tags):
    b = tags.get("building", "yes")
    name = tags.get("name", "").lower()
    if b in ("farm", "barn", "stable", "sty", "greenhouse", "storage_tank"):
        return "farm_building"
    if b in ("house", "detached", "semidetached_house", "terrace", "bungalow"):
        return "house"
    if b in ("church", "chapel", "cathedral"):
        return "church"
    if b in ("commercial", "industrial", "warehouse", "retail"):
        return "commercial"
    if "farm" in name or "barn" in name or "stable" in name:
        return "farm_building"
    if "church" in name or "chapel" in name or "abbey" in name:
        return "church"
    return "house"  # default


# ── Geometry helpers ───────────────────────────────────────────────────────────
def in_map_bbox(lat, lon):
    return MAP_LAT_MIN <= lat <= MAP_LAT_MAX and MAP_LON_MIN <= lon <= MAP_LON_MAX

def coords_in_bbox(coords):
    """Return True if any coord is inside bbox."""
    return any(in_map_bbox(lat, lon) for lat, lon in coords)

def geojson_feature(geometry, properties):
    return {"type": "Feature", "geometry": geometry, "properties": properties}

def line_geometry(coords_latlon):
    return {"type": "LineString", "coordinates": [[lon, lat] for lat, lon in coords_latlon]}

def polygon_geometry(coords_latlon):
    ring = [[lon, lat] for lat, lon in coords_latlon]
    if ring[0] != ring[-1]:
        ring.append(ring[0])
    return {"type": "Polygon", "coordinates": [ring]}

def way_length_m(coords):
    """Approximate length of a polyline in metres."""
    total = 0
    for i in range(len(coords) - 1):
        dlat = (coords[i+1][0] - coords[i][0]) * 111320
        dlon = (coords[i+1][1] - coords[i][1]) * 111320 * math.cos(math.radians(MAP_CENTRE_LAT))
        total += math.sqrt(dlat**2 + dlon**2)
    return total

def polygon_area_ha(coords):
    """Shoelace area of lat/lon polygon in hectares (approximate)."""
    n = len(coords)
    area = 0
    for i in range(n):
        j = (i + 1) % n
        area += coords[i][1] * coords[j][0]
        area -= coords[j][1] * coords[i][0]
    area_deg2 = abs(area) / 2
    # Convert deg² → m²
    area_m2 = area_deg2 * (111320 ** 2) * math.cos(math.radians(MAP_CENTRE_LAT))
    return area_m2 / 10000


# ── OSM parser ─────────────────────────────────────────────────────────────────
def parse_osm(osm_path):
    print(f"Parsing OSM: {osm_path}")
    tree = ET.parse(osm_path)
    root = tree.getroot()

    nodes = {}
    for node in root.findall('node'):
        nodes[node.get('id')] = (float(node.get('lat')), float(node.get('lon')))

    hedges, roads, buildings, water, forest, farmland = [], [], [], [], [], []
    stats = defaultdict(int)

    for way in root.findall('way'):
        tags = {t.get('k'): t.get('v') for t in way.findall('tag')}
        nd_refs = [nd.get('ref') for nd in way.findall('nd')]
        coords = [nodes[ref] for ref in nd_refs if ref in nodes]

        if len(coords) < 2:
            continue
        if not coords_in_bbox(coords):
            continue

        # ── Hedges ──
        if tags.get('barrier') == 'hedge':
            length = way_length_m(coords)
            hedges.append(geojson_feature(
                line_geometry(coords),
                {"type": "hedge", "length_m": round(length, 1),
                 "source": tags.get("source", "")}
            ))
            stats['hedges'] += 1

        # ── Roads & tracks ──
        elif 'highway' in tags:
            hw = tags['highway']
            mapping = HIGHWAY_FS25.get(hw)
            if mapping:
                length = way_length_m(coords)
                roads.append(geojson_feature(
                    line_geometry(coords),
                    {"highway": hw, "fs25_type": mapping["fs25_type"],
                     "width_m": mapping["width"],
                     "name": tags.get("name", ""),
                     "surface": tags.get("surface", ""),
                     "length_m": round(length, 1)}
                ))
                stats[f'road_{mapping["fs25_type"]}'] += 1

        # ── Buildings ──
        elif 'building' in tags:
            if len(coords) >= 3:
                btype = classify_building(tags)
                area = polygon_area_ha(coords)
                buildings.append(geojson_feature(
                    polygon_geometry(coords),
                    {"building": tags.get("building", "yes"),
                     "fs25:building": tags.get("fs25:building", ""),
                     "fs25_type": btype,
                     "name": tags.get("name", ""),
                     "area_ha": round(area, 4)}
                ))
                stats[f'building_{btype}'] += 1

        # ── Water ──
        elif 'waterway' in tags or (tags.get('natural') == 'water'):
            wtype = tags.get('waterway', 'pond')
            is_line = wtype in ('stream', 'ditch', 'drain', 'river')
            name = tags.get('name', '')
            if is_line:
                length = way_length_m(coords)
                water.append(geojson_feature(
                    line_geometry(coords),
                    {"waterway": wtype, "fs25_type": "stream" if wtype == "stream" else "ditch",
                     "name": name, "length_m": round(length, 1),
                     "tunnel": tags.get("tunnel", "no")}
                ))
            else:
                if len(coords) >= 3:
                    area = polygon_area_ha(coords)
                    water.append(geojson_feature(
                        polygon_geometry(coords),
                        {"waterway": "pond", "fs25_type": "pond", "name": name,
                         "area_ha": round(area, 4)}
                    ))
            stats['water'] += 1

        # ── Forest / woodland ──
        elif tags.get('landuse') == 'forest' or tags.get('natural') == 'wood':
            if len(coords) >= 3:
                area = polygon_area_ha(coords)
                forest.append(geojson_feature(
                    polygon_geometry(coords),
                    {"landuse": "forest", "fs25_type": "woodland",
                     "name": tags.get("name", ""),
                     "area_ha": round(area, 4)}
                ))
                stats['forest'] += 1

        # ── OSM farmland outlines (for reference) ──
        elif tags.get('landuse') == 'farmland':
            if len(coords) >= 3:
                farmland.append(geojson_feature(
                    polygon_geometry(coords),
                    {"landuse": "farmland", "name": tags.get("name", "")}
                ))

    stats['total_ways_in_bbox'] = sum(1 for way in root.findall('way')
        if coords_in_bbox([nodes[nd.get('ref')] for nd in way.findall('nd')
                           if nd.get('ref') in nodes]))

    return {
        "hedges": hedges, "roads": roads, "buildings": buildings,
        "water": water, "forest": forest, "farmland": farmland,
        "stats": dict(stats)
    }


# ── CROME loader ───────────────────────────────────────────────────────────────
def load_crome(geojson_path):
    print(f"Loading CROME: {geojson_path}")
    with open(geojson_path) as f:
        gj = json.load(f)

    features = []
    stats = defaultdict(int)
    for feat in gj['features']:
        props = feat['properties']
        lucode = props.get('lucode', '')
        category = LUCODE_CATEGORY.get(lucode, 'arable')
        fs25_fruit = LUCODE_TO_FS25.get(lucode)
        area_ha = props.get('area_ha', 0)

        # Check centroid-ish: first coord of first ring
        try:
            ring = feat['geometry']['coordinates'][0]
            lons = [c[0] for c in ring]
            lats = [c[1] for c in ring]
            clat = sum(lats) / len(lats)
            clon = sum(lons) / len(lons)
            if not in_map_bbox(clat, clon):
                continue
        except Exception:
            continue

        features.append(geojson_feature(
            feat['geometry'],
            {"lucode": lucode,
             "crop_name": props.get('crop_name', lucode),
             "fs25_fruit": fs25_fruit,
             "fs25_category": category,
             "area_ha": round(area_ha, 3)}
        ))
        stats[category] += 1

    return features, dict(stats)


# ── GeoJSON writer ─────────────────────────────────────────────────────────────
def write_geojson(features, path):
    gj = {"type": "FeatureCollection", "features": features}
    with open(path, 'w') as f:
        json.dump(gj, f, separators=(',', ':'))
    print(f"  -> {path}  ({len(features)} features)")


# ── Main ───────────────────────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--crome',  default='crome_south_warwickshire_fs25.geojson')
    parser.add_argument('--osm',    default='custom_osm.osm')
    parser.add_argument('--output', default='./fs25_layers/')
    args = parser.parse_args()

    out = Path(args.output)
    out.mkdir(exist_ok=True)

    # Parse OSM
    osm = parse_osm(args.osm)

    # Load CROME
    crome_features, crome_stats = load_crome(args.crome)

    # Write layers
    print("\nWriting FS25 layers:")
    write_geojson(crome_features,    out / 'fs25_fields.geojson')
    write_geojson(osm['hedges'],     out / 'fs25_hedges.geojson')
    write_geojson(osm['roads'],      out / 'fs25_roads.geojson')
    write_geojson(osm['buildings'],  out / 'fs25_buildings.geojson')
    write_geojson(osm['water'],      out / 'fs25_water.geojson')
    write_geojson(osm['forest'],     out / 'fs25_forest.geojson')

    # Summary
    summary = {
        "map": {
            "centre_lat": MAP_CENTRE_LAT, "centre_lon": MAP_CENTRE_LON,
            "size_km": MAP_HALF_KM * 2,
            "bbox": [MAP_LAT_MIN, MAP_LON_MIN, MAP_LAT_MAX, MAP_LON_MAX]
        },
        "crome": crome_stats,
        "osm": osm['stats'],
        "layer_counts": {
            "fields":    len(crome_features),
            "hedges":    len(osm['hedges']),
            "roads":     len(osm['roads']),
            "buildings": len(osm['buildings']),
            "water":     len(osm['water']),
            "forest":    len(osm['forest']),
        },
        "notes": {
            "osm_coverage": "~70% of map area (missing ~1km N edge, ~300m W edge)",
            "hedge_count": len(osm['hedges']),
            "crome_parcels": len(crome_features),
        }
    }
    with open(out / 'fs25_summary.json', 'w') as f:
        json.dump(summary, f, indent=2)
    print(f"  -> {out}/fs25_summary.json")

    print("\n=== Pipeline Summary ===")
    print(f"  Fields (CROME):  {len(crome_features):>5}")
    print(f"  Hedges (OSM):    {len(osm['hedges']):>5}")
    print(f"  Roads (OSM):     {len(osm['roads']):>5}")
    print(f"  Buildings (OSM): {len(osm['buildings']):>5}")
    print(f"  Water (OSM):     {len(osm['water']):>5}")
    print(f"  Forest (OSM):    {len(osm['forest']):>5}")
    print(f"\n  CROME categories:")
    for cat, count in sorted(crome_stats.items(), key=lambda x: -x[1]):
        print(f"    {cat:<15} {count:>4}")
    print(f"\n  OSM breakdown:")
    for k, v in sorted(osm['stats'].items(), key=lambda x: -x[1]):
        print(f"    {k:<30} {v:>4}")


if __name__ == '__main__':
    main()
