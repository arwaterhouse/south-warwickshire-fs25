#!/usr/bin/env python3
"""
Paint terrain texture weight maps from GeoJSON pipeline outputs.

Reads outputs/*.geojson and paints PNG weight maps in map/map/data/.

Textures updated:
  grass01/02_weight.png         - grassland & permanent pasture fields
  dirt01/02_weight.png          - arable / root-crop fields (bare soil)
  forestGround01/02_weight.png  - woodland / forest areas
  grassDirtPatchy01/02_weight.png - woodland edge / fallow transition
  asphalt01/02_weight.png       - main roads (secondary, tertiary)
  asphaltDirt01/02_weight.png   - minor roads (unclassified, residential, service)
  gravel01/02_weight.png        - farm tracks and bridleways
  waterPuddle01/02_weight.png   - water bodies and streams/ditches
  dirtDark01/02_weight.png      - hedge lines

Usage:
    python3 pipeline/paint_terrain_weights.py
"""

import json
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

# ── Map configuration (from main_settings.json) ───────────────────────────────
MAP_CENTRE_LAT = 52.089387
MAP_CENTRE_LON = -1.53229
MAP_SIZE_M     = 4096
IMAGE_SIZE     = 4096

_lat_per_m = 1.0 / 111320.0
_lon_per_m = 1.0 / (111320.0 * math.cos(math.radians(MAP_CENTRE_LAT)))

LAT_HALF = (MAP_SIZE_M / 2) * _lat_per_m
LON_HALF = (MAP_SIZE_M / 2) * _lon_per_m

LAT_MIN = MAP_CENTRE_LAT - LAT_HALF
LAT_MAX = MAP_CENTRE_LAT + LAT_HALF
LON_MIN = MAP_CENTRE_LON - LON_HALF
LON_MAX = MAP_CENTRE_LON + LON_HALF

REPO_ROOT   = Path(__file__).resolve().parent.parent
OUTPUTS_DIR = REPO_ROOT / "outputs"
DATA_DIR    = REPO_ROOT / "map" / "map" / "data"

# Road widths in metres (used for line buffering)
ROAD_WIDTH = {
    "road":       6.0,
    "service":    4.0,
    "dirt_track": 4.0,
    "footpath":   2.0,
}
HEDGE_WIDTH_M = 3.0


# ── Coordinate helpers ────────────────────────────────────────────────────────

def lonlat_to_pixel(lon: float, lat: float):
    """Convert WGS84 lon/lat → (px_x, px_y) in image space."""
    x = (lon - LON_MIN) / (LON_MAX - LON_MIN) * IMAGE_SIZE
    y = (LAT_MAX - lat) / (LAT_MAX - LAT_MIN) * IMAGE_SIZE  # north = top
    return (int(round(x)), int(round(y)))


def ring_to_pixels(ring):
    """Convert a GeoJSON coordinate ring [[lon,lat], …] → [(x,y), …]."""
    return [lonlat_to_pixel(c[0], c[1]) for c in ring]


def m_to_px(metres: float) -> int:
    """Convert a ground distance in metres to pixels."""
    return max(1, int(metres / MAP_SIZE_M * IMAGE_SIZE))


# ── GeoJSON I/O ───────────────────────────────────────────────────────────────

def load_geojson(name: str):
    path = OUTPUTS_DIR / name
    if not path.exists():
        print(f"  WARNING: {name} not found – skipping")
        return []
    with open(path) as f:
        return json.load(f)["features"]


# ── Drawing helpers ───────────────────────────────────────────────────────────

def draw_polygon_feature(draw: ImageDraw.ImageDraw, geometry: dict, value: int = 255):
    """Draw a Polygon or MultiPolygon geometry onto a PIL ImageDraw."""
    gtype = geometry["type"]
    if gtype == "Polygon":
        rings = geometry["coordinates"]
        pts = ring_to_pixels(rings[0])
        if len(pts) >= 3:
            draw.polygon(pts, fill=value)
    elif gtype == "MultiPolygon":
        for poly in geometry["coordinates"]:
            pts = ring_to_pixels(poly[0])
            if len(pts) >= 3:
                draw.polygon(pts, fill=value)


def draw_line_feature(draw: ImageDraw.ImageDraw, geometry: dict,
                      width_px: int, value: int = 255):
    """Draw a LineString or MultiLineString geometry onto a PIL ImageDraw."""
    gtype = geometry["type"]
    if gtype == "LineString":
        pts = ring_to_pixels(geometry["coordinates"])
        if len(pts) >= 2:
            draw.line(pts, fill=value, width=width_px)
    elif gtype == "MultiLineString":
        for line in geometry["coordinates"]:
            pts = ring_to_pixels(line)
            if len(pts) >= 2:
                draw.line(pts, fill=value, width=width_px)


# ── Texture painter ───────────────────────────────────────────────────────────

def new_canvas() -> Image.Image:
    return Image.new("L", (IMAGE_SIZE, IMAGE_SIZE), 0)


def save_weight(img: Image.Image, texture_name: str):
    """Write the image to both variant weight files for a texture."""
    for variant in (1, 2):
        path = DATA_DIR / f"{texture_name}{variant:02d}_weight.png"
        img.save(str(path))
        print(f"  → {path.name}")


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    print("=" * 60)
    print("Paint Terrain Weights")
    print(f"  Map centre : {MAP_CENTRE_LAT}°N, {MAP_CENTRE_LON}°W")
    print(f"  Bbox lat   : [{LAT_MIN:.5f}, {LAT_MAX:.5f}]")
    print(f"  Bbox lon   : [{LON_MIN:.5f}, {LON_MAX:.5f}]")
    print(f"  Image size : {IMAGE_SIZE}×{IMAGE_SIZE} px")
    print("=" * 60)

    fields  = load_geojson("fs25_fields_osm.geojson")
    forests = load_geojson("fs25_forest.geojson")
    roads   = load_geojson("fs25_roads.geojson")
    water   = load_geojson("fs25_water.geojson")
    hedges  = load_geojson("fs25_hedges.geojson")

    print(f"\nLoaded: {len(fields)} fields, {len(forests)} forests, "
          f"{len(roads)} roads, {len(water)} water, {len(hedges)} hedges\n")

    # ── 1. Grass – grassland / permanent pasture ──────────────────────────────
    grass_categories = {"Grassland", "grassland"}
    grass_img = new_canvas()
    grass_draw = ImageDraw.Draw(grass_img)
    n = 0
    for feat in fields:
        if feat["properties"].get("fs25_category") in grass_categories:
            draw_polygon_feature(grass_draw, feat["geometry"])
            n += 1
    print(f"grass          : {n} features")
    save_weight(grass_img, "grass")

    # ── 2. Dirt – arable / root-crop / fallow fields ─────────────────────────
    arable_categories = {"Arable Cereals", "Arable Maize", "Fallow",
                         "arable", "root", "fallow", "vegetable"}
    dirt_img = new_canvas()
    dirt_draw = ImageDraw.Draw(dirt_img)
    n = 0
    for feat in fields:
        if feat["properties"].get("fs25_category") in arable_categories:
            draw_polygon_feature(dirt_draw, feat["geometry"])
            n += 1
    print(f"dirt           : {n} features")
    save_weight(dirt_img, "dirt")

    # ── 3. Forest ground – woodland areas ─────────────────────────────────────
    forest_img = new_canvas()
    forest_draw = ImageDraw.Draw(forest_img)
    n = 0
    # Also include fields categorised as Woodland
    for feat in fields:
        if feat["properties"].get("fs25_category") in ("Woodland", "woodland"):
            draw_polygon_feature(forest_draw, feat["geometry"])
            n += 1
    for feat in forests:
        draw_polygon_feature(forest_draw, feat["geometry"])
        n += 1
    print(f"forestGround   : {n} features")
    save_weight(forest_img, "forestGround")

    # ── 4. Grass-dirt patchy – fallow / forest edge transition ───────────────
    patchy_img = new_canvas()
    patchy_draw = ImageDraw.Draw(patchy_img)
    n = 0
    for feat in fields:
        if feat["properties"].get("fs25_category") in ("Fallow", "fallow", "Woodland", "woodland"):
            draw_polygon_feature(patchy_draw, feat["geometry"])
            n += 1
    print(f"grassDirtPatchy: {n} features")
    save_weight(patchy_img, "grassDirtPatchy")

    # ── 5. Asphalt – main tarmac roads (primary, secondary, tertiary) ──────────
    asphalt_img = new_canvas()
    asphalt_draw = ImageDraw.Draw(asphalt_img)
    asphalt_highways = {"primary", "secondary", "tertiary"}
    n = 0
    for feat in roads:
        props = feat["properties"]
        hw = props.get("highway", "")
        if hw in asphalt_highways:
            w = m_to_px(props.get("width_m", 10.0))
            draw_line_feature(asphalt_draw, feat["geometry"], w)
            n += 1
    print(f"asphalt        : {n} features")
    save_weight(asphalt_img, "asphalt")

    # ── 6. AsphaltDirt – minor roads (unclassified, residential, service) ────
    asphaltdirt_img = new_canvas()
    asphaltdirt_draw = ImageDraw.Draw(asphaltdirt_img)
    minor_highways = {"unclassified", "residential", "service"}
    n = 0
    for feat in roads:
        props = feat["properties"]
        hw = props.get("highway", "")
        if hw in minor_highways:
            w = m_to_px(props.get("width_m", 4.5))
            draw_line_feature(asphaltdirt_draw, feat["geometry"], w)
            n += 1
    print(f"asphaltDirt    : {n} features")
    save_weight(asphaltdirt_img, "asphaltDirt")

    # ── 7. Gravel – farm tracks and bridleways ────────────────────────────────
    gravel_img = new_canvas()
    gravel_draw = ImageDraw.Draw(gravel_img)
    track_highways = {"track", "bridleway"}
    n = 0
    for feat in roads:
        props = feat["properties"]
        hw = props.get("highway", "")
        fs25 = props.get("fs25_type", "")
        if hw in track_highways or fs25 == "dirt_track":
            w = m_to_px(props.get("width_m", 3.5))
            draw_line_feature(gravel_draw, feat["geometry"], w)
            n += 1
    print(f"gravel         : {n} features")
    save_weight(gravel_img, "gravel")

    # ── 8. WaterPuddle – water bodies (polygons) and streams/ditches (lines) ─
    water_img = new_canvas()
    water_draw = ImageDraw.Draw(water_img)
    n = 0
    stream_width_px = m_to_px(5)
    for feat in water:
        geom = feat["geometry"]
        if geom["type"] in ("Polygon", "MultiPolygon"):
            draw_polygon_feature(water_draw, geom)
        else:
            draw_line_feature(water_draw, geom, stream_width_px)
        n += 1
    print(f"waterPuddle    : {n} features")
    save_weight(water_img, "waterPuddle")

    # ── 9. DirtDark – hedge lines ─────────────────────────────────────────────
    dirtdark_img = new_canvas()
    dirtdark_draw = ImageDraw.Draw(dirtdark_img)
    hedge_w = m_to_px(HEDGE_WIDTH_M)
    n = 0
    for feat in hedges:
        draw_line_feature(dirtdark_draw, feat["geometry"], hedge_w)
        n += 1
    # Also use hedge_splines if available
    hedge_splines = load_geojson("hedge_splines.geojson")
    for feat in hedge_splines:
        draw_line_feature(dirtdark_draw, feat["geometry"], hedge_w)
        n += 1
    print(f"dirtDark       : {n} features")
    save_weight(dirtdark_img, "dirtDark")

    # ── 10. DirtMedium – farmyard areas ──────────────────────────────────────
    dirtmedium_img = new_canvas()
    dirtmedium_draw = ImageDraw.Draw(dirtmedium_img)
    n = 0
    for feat in fields:
        if feat["properties"].get("fs25_category") in ("Farmyard", "farmyard"):
            draw_polygon_feature(dirtmedium_draw, feat["geometry"])
            n += 1
    print(f"dirtMedium     : {n} features")
    save_weight(dirtmedium_img, "dirtMedium")

    print("\nDone. All weight PNGs written to map/map/data/")


if __name__ == "__main__":
    main()
