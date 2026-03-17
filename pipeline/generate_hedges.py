#!/usr/bin/env python3
"""
Hedge Spline Generator — South Warwickshire FS25
Generates hedge lines from:
  1. OSM barrier=hedge (20 confirmed hedges)
  2. CROME field boundary intersections (inferred hedgerows)

Output: hedge_splines.geojson  — linestrings ready for Giants Editor spline import
        hedge_splines_preview.png — visual check

Usage: python3 generate_hedges.py
"""

import json, math, xml.etree.ElementTree as ET
from pathlib import Path
from shapely.geometry import LineString, MultiLineString, shape
from shapely.ops import unary_union
import geopandas as gpd
import warnings; warnings.filterwarnings('ignore')

# ── Config ─────────────────────────────────────────────────────────────────────
MAP_LAT, MAP_LON = 52.089387, -1.532290
HALF = 4096 / 2
LAT_PER_M = 1 / 111320
LON_PER_M = 1 / (111320 * math.cos(math.radians(MAP_LAT)))
MAP_LAT_MIN = MAP_LAT - HALF * LAT_PER_M
MAP_LAT_MAX = MAP_LAT + HALF * LAT_PER_M
MAP_LON_MIN = MAP_LON - HALF * LON_PER_M
MAP_LON_MAX = MAP_LON + HALF * LON_PER_M

SCRIPT_DIR  = Path(__file__).resolve().parent
ROOT_DIR    = SCRIPT_DIR.parent
OSM_FILE    = ROOT_DIR / "data" / "south_warwickshire_enriched.osm"
CROME_FILE  = ROOT_DIR / "data" / "crome_south_warwickshire_fs25.geojson"
OUTPUT_FILE = ROOT_DIR / "outputs" / "hedge_splines.geojson"

# ── Helpers ────────────────────────────────────────────────────────────────────
def any_in_bbox(coords, t=0.3):
    n = sum(1 for lat,lon in coords
            if MAP_LAT_MIN<=lat<=MAP_LAT_MAX and MAP_LON_MIN<=lon<=MAP_LON_MAX)
    return len(coords) > 0 and n/len(coords) >= t

# ── 1. OSM hedges ──────────────────────────────────────────────────────────────
print("Loading OSM hedges...")
tree = ET.parse(OSM_FILE)
root = tree.getroot()
nodes = {n.get('id'): (float(n.get('lat')), float(n.get('lon')))
         for n in root.findall('node')}

osm_hedges = []
for way in root.findall('way'):
    tags = {t.get('k'): t.get('v') for t in way.findall('tag')}
    if tags.get('barrier') != 'hedge': continue
    coords = [nodes[nd.get('ref')] for nd in way.findall('nd') if nd.get('ref') in nodes]
    if not coords or not any_in_bbox(coords): continue
    ll = [(lon,lat) for lat,lon in coords]
    osm_hedges.append(LineString(ll))

print(f"  OSM hedges found: {len(osm_hedges)}")

# ── 2. Infer hedges from CROME field boundaries ────────────────────────────────
print("Inferring hedges from CROME field boundaries...")
with open(CROME_FILE) as f:
    crome = json.load(f)

# Build GeoDataFrame of CROME parcels within bbox
crome_feats = []
for feat in crome['features']:
    ring = feat['geometry']['coordinates'][0]
    clon = sum(c[0] for c in ring)/len(ring)
    clat = sum(c[1] for c in ring)/len(ring)
    if MAP_LAT_MIN<=clat<=MAP_LAT_MAX and MAP_LON_MIN<=clon<=MAP_LON_MAX:
        crome_feats.append(feat)

crome_gdf = gpd.GeoDataFrame(
    [{'geometry': shape(f['geometry']),
      'category': f['properties'].get('fs25_category',''),
      'lucode':   f['properties'].get('lucode','')}
     for f in crome_feats],
    crs='EPSG:4326'
).to_crs('EPSG:27700')

print(f"  CROME parcels in bbox: {len(crome_gdf)}")

# Find shared boundaries between parcels of DIFFERENT types
# These are the most likely hedgerow locations
inferred_hedges = []
MIN_HEDGE_LENGTH = 30  # metres — ignore tiny slivers

# Categories that typically have hedges between them
HEDGE_CATEGORY_PAIRS = {
    frozenset(['Grassland', 'Arable Cereals']),
    frozenset(['Grassland', 'Fallow']),
    frozenset(['Arable Cereals', 'Fallow']),
    frozenset(['Grassland', 'Arable Maize']),
    frozenset(['Arable Cereals', 'Arable Maize']),
}

# Spatial index for efficiency
from shapely.strtree import STRtree
tree_idx = STRtree(crome_gdf.geometry.values)

processed_pairs = set()
for i, row in crome_gdf.iterrows():
    nearby_idx = tree_idx.query(row.geometry.buffer(1))
    for j in nearby_idx:
        if i >= j: continue
        pair_key = (min(i,j), max(i,j))
        if pair_key in processed_pairs: continue
        processed_pairs.add(pair_key)

        row2 = crome_gdf.iloc[j]
        cat_pair = frozenset([row['category'], row2['category']])

        # Only draw hedge if categories differ in a meaningful way
        if row['category'] == row2['category']: continue
        if cat_pair not in HEDGE_CATEGORY_PAIRS: continue

        try:
            shared = row.geometry.intersection(row2.geometry)
            if shared.is_empty: continue
            if shared.geom_type in ('LineString', 'MultiLineString'):
                lines = [shared] if shared.geom_type == 'LineString' else list(shared.geoms)
                for line in lines:
                    if line.length >= MIN_HEDGE_LENGTH:
                        inferred_hedges.append(line)
        except Exception:
            continue

print(f"  Inferred hedge segments: {len(inferred_hedges)}")

# Reproject inferred hedges back to WGS84
if inferred_hedges:
    inferred_gdf = gpd.GeoDataFrame(
        [{'geometry': h, 'source': 'crome_boundary'} for h in inferred_hedges],
        crs='EPSG:27700'
    ).to_crs('EPSG:4326')
    inferred_lines_wgs84 = list(inferred_gdf.geometry)
else:
    inferred_lines_wgs84 = []

# ── 3. Combine and export ──────────────────────────────────────────────────────
print("Combining and exporting...")

features = []
total_length_m = 0

for h in osm_hedges:
    length = h.length * 111320 * math.cos(math.radians(MAP_LAT))
    total_length_m += length
    features.append({
        'type': 'Feature',
        'geometry': {'type': 'LineString', 'coordinates': list(h.coords)},
        'properties': {'source': 'osm', 'length_m': round(length, 1)}
    })

for h in inferred_lines_wgs84:
    coords = list(h.coords)
    length = h.length * 111320 * math.cos(math.radians(MAP_LAT))
    total_length_m += length
    features.append({
        'type': 'Feature',
        'geometry': {'type': 'LineString', 'coordinates': coords},
        'properties': {'source': 'crome_inferred', 'length_m': round(length, 1)}
    })

geojson_out = {'type': 'FeatureCollection', 'features': features}
with open(OUTPUT_FILE, 'w') as f:
    json.dump(geojson_out, f, separators=(',',':'))

print(f"\n=== Hedge Generation Complete ===")
print(f"  OSM hedges:       {len(osm_hedges)}")
print(f"  Inferred hedges:  {len(inferred_lines_wgs84)}")
print(f"  Total segments:   {len(features)}")
print(f"  Total length:     ~{total_length_m/1000:.1f} km")
print(f"  Output:           {OUTPUT_FILE}")
print()
print("Import into Giants Editor:")
print("  1. Extras → Import Splines → select hedge_splines.geojson")
print("  2. Assign hedge object to splines (e.g. Brambles, Hedgerow01)")
print("  3. Set spline spacing to ~1.5m for dense hedges")
