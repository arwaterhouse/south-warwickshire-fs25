#!/usr/bin/env python3
"""
Paint foliage density maps from GeoJSON pipeline outputs.

Reads outputs/*.geojson and generates foliage density PNGs in
outputs/foliage_density/ for use in Giants Editor or Maps4FS.

Output maps (all 4096×4096 greyscale, white = full density):
  forest_density.png       - tree / canopy coverage in woodland areas
  ground_foliage_density.png - understorey & ground cover (forest + grassland)
  grassland_density.png    - open grassland / meadow foliage
  scrub_density.png        - hedgerow & scrub corridor foliage
  arable_density.png       - in-field weed / stubble foliage (low density)

Usage:
    python3 pipeline/paint_foliage_layers.py
"""

import json
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

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

REPO_ROOT    = Path(__file__).resolve().parent.parent
OUTPUTS_DIR  = REPO_ROOT / "outputs"
FOLIAGE_DIR  = OUTPUTS_DIR / "foliage_density"

# Density value constants (0–255)
DENSITY_FULL   = 255   # dense coverage
DENSITY_HIGH   = 200   # e.g. closed-canopy forest understorey
DENSITY_MEDIUM = 140   # e.g. grassland / meadow
DENSITY_LOW    = 70    # e.g. arable field edges
DENSITY_SCRUB  = 180   # hedgerow / scrub corridors

# Hedge/scrub corridor width in metres
HEDGE_WIDTH_M = 8.0


# ── Coordinate helpers ────────────────────────────────────────────────────────

def lonlat_to_pixel(lon: float, lat: float):
    x = (lon - LON_MIN) / (LON_MAX - LON_MIN) * IMAGE_SIZE
    y = (LAT_MAX - lat) / (LAT_MAX - LAT_MIN) * IMAGE_SIZE
    return (int(round(x)), int(round(y)))


def ring_to_pixels(ring):
    return [lonlat_to_pixel(c[0], c[1]) for c in ring]


def m_to_px(metres: float) -> int:
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

def draw_polygon_feature(draw: ImageDraw.ImageDraw, geometry: dict, value: int):
    gtype = geometry["type"]
    if gtype == "Polygon":
        pts = ring_to_pixels(geometry["coordinates"][0])
        if len(pts) >= 3:
            draw.polygon(pts, fill=value)
    elif gtype == "MultiPolygon":
        for poly in geometry["coordinates"]:
            pts = ring_to_pixels(poly[0])
            if len(pts) >= 3:
                draw.polygon(pts, fill=value)


def draw_line_feature(draw: ImageDraw.ImageDraw, geometry: dict,
                      width_px: int, value: int):
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


def new_canvas() -> Image.Image:
    return Image.new("L", (IMAGE_SIZE, IMAGE_SIZE), 0)


def soft_blur(img: Image.Image, radius: int = 4) -> Image.Image:
    """Apply a Gaussian blur to soften hard polygon edges."""
    return img.filter(ImageFilter.GaussianBlur(radius=radius))


def save_foliage(img: Image.Image, name: str):
    path = FOLIAGE_DIR / name
    img.save(str(path), optimize=True, compress_level=9)
    print(f"  → {path.name}  (max={np.max(np.array(img))})")


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    FOLIAGE_DIR.mkdir(parents=True, exist_ok=True)

    print("=" * 60)
    print("Paint Foliage Density Layers")
    print(f"  Map centre : {MAP_CENTRE_LAT}°N, {MAP_CENTRE_LON}°W")
    print(f"  Bbox lat   : [{LAT_MIN:.5f}, {LAT_MAX:.5f}]")
    print(f"  Bbox lon   : [{LON_MIN:.5f}, {LON_MAX:.5f}]")
    print(f"  Image size : {IMAGE_SIZE}×{IMAGE_SIZE} px")
    print(f"  Output dir : {FOLIAGE_DIR}")
    print("=" * 60)

    fields       = load_geojson("fs25_fields_osm.geojson")
    forests      = load_geojson("fs25_forest.geojson")
    hedges       = load_geojson("fs25_hedges.geojson")
    hedge_splines = load_geojson("hedge_splines.geojson")

    hedge_w_px = m_to_px(HEDGE_WIDTH_M)

    print(f"\nLoaded: {len(fields)} fields, {len(forests)} forests, "
          f"{len(hedges)} hedges, {len(hedge_splines)} hedge splines\n")

    # ── 1. Forest density ─────────────────────────────────────────────────────
    # High density inside woodland polygons.
    forest_img = new_canvas()
    forest_draw = ImageDraw.Draw(forest_img)
    n = 0
    for feat in forests:
        draw_polygon_feature(forest_draw, feat["geometry"], DENSITY_FULL)
        n += 1
    for feat in fields:
        if feat["properties"].get("fs25_category") in ("Woodland", "woodland"):
            draw_polygon_feature(forest_draw, feat["geometry"], DENSITY_FULL)
            n += 1
    print(f"forest_density     : {n} features")
    save_foliage(soft_blur(forest_img, radius=6), "forest_density.png")

    # ── 2. Ground foliage density ─────────────────────────────────────────────
    # Composite: forest (high) + grassland (medium) + hedge corridors (scrub).
    ground_img = new_canvas()
    ground_draw = ImageDraw.Draw(ground_img)
    n_forest = n_grass = n_hedge = 0

    # Forest areas – dense understorey
    for feat in forests:
        draw_polygon_feature(ground_draw, feat["geometry"], DENSITY_HIGH)
        n_forest += 1
    for feat in fields:
        cat = feat["properties"].get("fs25_category", "")
        if cat in ("Woodland", "woodland"):
            draw_polygon_feature(ground_draw, feat["geometry"], DENSITY_HIGH)
            n_forest += 1

    # Grassland / meadow – medium ground cover
    for feat in fields:
        cat = feat["properties"].get("fs25_category", "")
        if cat in ("Grassland", "grassland"):
            draw_polygon_feature(ground_draw, feat["geometry"], DENSITY_MEDIUM)
            n_grass += 1

    # Hedge & scrub corridors on top
    for feat in hedges:
        draw_line_feature(ground_draw, feat["geometry"], hedge_w_px, DENSITY_SCRUB)
        n_hedge += 1
    for feat in hedge_splines:
        draw_line_feature(ground_draw, feat["geometry"], hedge_w_px, DENSITY_SCRUB)
        n_hedge += 1

    print(f"ground_foliage     : {n_forest} forest + {n_grass} grass + {n_hedge} hedge")
    save_foliage(soft_blur(ground_img, radius=3), "ground_foliage_density.png")

    # ── 3. Grassland density ──────────────────────────────────────────────────
    # Purely open grassland / meadow areas.
    grass_img = new_canvas()
    grass_draw = ImageDraw.Draw(grass_img)
    n = 0
    for feat in fields:
        cat = feat["properties"].get("fs25_category", "")
        if cat in ("Grassland", "grassland"):
            draw_polygon_feature(grass_draw, feat["geometry"], DENSITY_MEDIUM)
            n += 1
    # Fallow / transitional areas get a lighter coverage
    for feat in fields:
        cat = feat["properties"].get("fs25_category", "")
        if cat in ("Fallow", "fallow"):
            draw_polygon_feature(grass_draw, feat["geometry"], DENSITY_LOW)
            n += 1
    print(f"grassland_density  : {n} features")
    save_foliage(soft_blur(grass_img, radius=2), "grassland_density.png")

    # ── 4. Scrub / hedge density ──────────────────────────────────────────────
    # Hedgerow corridors and scrub patches as thick line buffers.
    scrub_img = new_canvas()
    scrub_draw = ImageDraw.Draw(scrub_img)
    n = 0
    for feat in hedges:
        draw_line_feature(scrub_draw, feat["geometry"], hedge_w_px, DENSITY_FULL)
        n += 1
    for feat in hedge_splines:
        draw_line_feature(scrub_draw, feat["geometry"], hedge_w_px, DENSITY_FULL)
        n += 1
    print(f"scrub_density      : {n} features")
    save_foliage(soft_blur(scrub_img, radius=3), "scrub_density.png")

    # ── 5. Arable density ─────────────────────────────────────────────────────
    # Low-level foliage representing crop residues / weeds on arable land.
    arable_categories = {"Arable Cereals", "Arable Maize", "arable", "root", "vegetable"}
    arable_img = new_canvas()
    arable_draw = ImageDraw.Draw(arable_img)
    n = 0
    for feat in fields:
        cat = feat["properties"].get("fs25_category", "")
        if cat in arable_categories:
            draw_polygon_feature(arable_draw, feat["geometry"], DENSITY_LOW)
            n += 1
    print(f"arable_density     : {n} features")
    save_foliage(soft_blur(arable_img, radius=2), "arable_density.png")

    # ── Summary ───────────────────────────────────────────────────────────────
    print(f"\nDone. Foliage density maps written to {FOLIAGE_DIR}/")


if __name__ == "__main__":
    main()
