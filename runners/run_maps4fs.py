#!/usr/bin/env python3
"""
run_maps4fs.py — South Warwickshire FS25
=========================================

Modes:
    python3 run_maps4fs.py                   # terrain only, no buildings
    python3 run_maps4fs.py --buildings       # auto-place your UK buildings

Files needed:
    data/south_warwickshire_enriched.osm   ← AUTHORITATIVE OSM SOURCE (do not use custom_osm.osm)
    config/fs25_texture_schema_uk.json
    config/fs25_texture_schema_uk_buildings.json    (only with --buildings)
    config/fs25_tree_schema_uk.json
    config/fs25_buildings_schema_uk.json            (only with --buildings)
    config/generation_settings.json
    runners/fs25-map-template-uk.zip                (only with --buildings, made by prepare_map_template.py)
    OR
    runners/fs25-map-template.zip                   (stock template, if no custom buildings)
"""

import json, os, sys

AUTO_BUILDINGS = "--buildings" in sys.argv

SCRIPT_DIR  = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR    = os.path.dirname(SCRIPT_DIR)
CONFIG_DIR  = os.path.join(ROOT_DIR, "config")
DATA_DIR    = os.path.join(ROOT_DIR, "data")
OUTPUT_DIR  = os.path.join(ROOT_DIR, "outputs")

# NOTE: Always use south_warwickshire_enriched.osm as the authoritative OSM source.
# custom_osm.osm is kept as a fallback only — do NOT edit it directly; edit the enriched file.
CUSTOM_OSM       = os.path.join(DATA_DIR, "south_warwickshire_enriched.osm")
TEXTURE_SCHEMA   = os.path.join(CONFIG_DIR,
    "fs25_texture_schema_uk_buildings.json" if AUTO_BUILDINGS
    else "fs25_texture_schema_uk.json")
TREE_SCHEMA      = os.path.join(CONFIG_DIR, "fs25_tree_schema_uk.json")
BUILDINGS_SCHEMA = os.path.join(CONFIG_DIR, "fs25_buildings_schema_uk.json")
GEN_SETTINGS     = os.path.join(CONFIG_DIR, "generation_settings.json")

# Template: prefer the UK one (with your buildings bundled), fall back to stock
CUSTOM_TEMPLATE = None
for t in ["fs25-map-template-uk.zip", "fs25-map-template.zip"]:
    p = os.path.join(SCRIPT_DIR, t)
    if os.path.isfile(p):
        CUSTOM_TEMPLATE = p
        break

os.makedirs(OUTPUT_DIR, exist_ok=True)

# ── Validate required files ───────────────────────────────────────────────────
required = [
    (CUSTOM_OSM,     "custom_osm.osm"),
    (TEXTURE_SCHEMA, os.path.basename(TEXTURE_SCHEMA)),
    (TREE_SCHEMA,    "fs25_tree_schema_uk.json"),
    (GEN_SETTINGS,   "generation_settings.json"),
]
if AUTO_BUILDINGS:
    required.append((BUILDINGS_SCHEMA, "fs25_buildings_schema_uk.json"))
    if not CUSTOM_TEMPLATE:
        print("WARNING: No map template found. maps4fs will try to download one from GitHub.")
        print("  Recommended: run prepare_map_template.py first to bundle your building files.")
        print()

for path, label in required:
    if not os.path.isfile(path):
        print(f"ERROR: Missing required file: {label}")
        print(f"       Expected at: {path}")
        sys.exit(1)

# ── Load configs ──────────────────────────────────────────────────────────────
with open(TEXTURE_SCHEMA)  as f: texture_schema  = json.load(f)
with open(TREE_SCHEMA)     as f: tree_schema     = json.load(f)
with open(GEN_SETTINGS)    as f: gen_settings_raw = json.load(f)
with open(CUSTOM_OSM, "rb") as f: custom_osm_data = f.read()

buildings_schema = None
if AUTO_BUILDINGS:
    with open(BUILDINGS_SCHEMA) as f:
        buildings_schema = json.load(f)
    # Validate no zero-dimension entries
    bad = [b["name"] for b in buildings_schema if b["width"] == 0 or b["depth"] == 0]
    if bad:
        print("ERROR: These buildings have 0×0 dimensions — fix before running --buildings:")
        for b in bad:
            print(f"  {b}")
        print("  Open fs25_buildings_schema_uk.json and add correct width/depth values.")
        sys.exit(1)

gen_settings_raw["BuildingSettings"]["generate_buildings"] = AUTO_BUILDINGS

# ── maps4fs ───────────────────────────────────────────────────────────────────
try:
    import maps4fs as mfs
except ImportError:
    print("ERROR: maps4fs not installed.  Run:  pip install maps4fs")
    sys.exit(1)

from maps4fs.generator.settings import GenerationSettings

print(f"maps4fs  {getattr(mfs, '__version__', 'unknown')}")
print(f"Mode     {'AUTO-BUILDINGS ✅' if AUTO_BUILDINGS else 'terrain only (no buildings)'}")
print(f"Template {CUSTOM_TEMPLATE or '(will download from GitHub)'}")
print(f"Output   {OUTPUT_DIR}")
print()

gen_settings = GenerationSettings.from_json(gen_settings_raw)
game = mfs.Game.from_code("FS25")

kwargs = dict(
    game=game,
    coordinates=(52.089387, -1.532290),
    size=4096,
    map_directory=OUTPUT_DIR,
    dtm_provider=mfs.dtm.SRTM30Provider,
    custom_osm=custom_osm_data,
    dem_settings=gen_settings.dem_settings,
    background_settings=gen_settings.background_settings,
    grle_settings=gen_settings.grle_settings,
    i3d_settings=gen_settings.i3d_settings,
    texture_settings=gen_settings.texture_settings,
    satellite_settings=gen_settings.satellite_settings,
    building_settings=gen_settings.building_settings,
    texture_custom_schema=texture_schema,
    tree_custom_schema=tree_schema,
)

if AUTO_BUILDINGS and buildings_schema:
    kwargs["buildings_custom_schema"] = buildings_schema
if CUSTOM_TEMPLATE:
    kwargs["custom_template"] = CUSTOM_TEMPLATE

mp = mfs.Map(**kwargs)

for component_name, step, total in mp.generate():
    pct = int(step / total * 100) if total else 0
    bar = "█" * (pct // 5) + "░" * (20 - pct // 5)
    print(f"\r  [{bar}] {pct:3d}%  {component_name:<35}", end="", flush=True)
print("\n")

print("✅  Done!")
print(f"   Output → {OUTPUT_DIR}")
if AUTO_BUILDINGS:
    print("   Buildings written to map.i3d")
else:
    print("   Open in Giants Editor → File → Open → output/map/map.i3d")
