#!/usr/bin/env python3
"""
paint_deco_foliage.py — Generate FS25 foliage density maps from OSM + hedge data.
Usage:
  python pipeline/paint_deco_foliage.py            # --dry-run (default)
  python pipeline/paint_deco_foliage.py --apply    # write density PNGs + preview
"""

import argparse
import json
import math
import os
import shutil
import sys
import xml.etree.ElementTree as ET
from datetime import datetime

import numpy as np
from PIL import Image

try:
    import opensimplex
except ImportError:
    print("ERROR: opensimplex not installed. Run: pip install opensimplex")
    sys.exit(1)

# ── Constants ──────────────────────────────────────────────────────────────────
MAP_LAT = 52.089387
MAP_LON = -1.532290
MAP_SIZE = 4096
CANVAS_SIZE = 4096
PREVIEW_SIZE = 1024
HALF = 2048.0
LAT_DEG_PER_M = 1.0 / 111320.0
LON_DEG_PER_M = 1.0 / (111320.0 * math.cos(math.radians(MAP_LAT)))

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(SCRIPT_DIR)

HEDGE_GEOJSON = os.path.join(ROOT, "data", "fs25_hedges_edited.geojson")
OSM_FILE = os.path.join(ROOT, "data", "south_warwickshire_enriched.osm")
OUTPUT_DIR = os.path.join(ROOT, "outputs", "foliage_density")
PREVIEW_PATH = os.path.join(ROOT, "outputs", "foliage_preview.png")
BACKUP_BASE = os.path.join(ROOT, "outputs", "foliage_backup")

# ── Coordinate conversion ───────────────────────────────────────────────────────
def wgs84_to_px(lon, lat):
    x_m = (lon - MAP_LON) / LON_DEG_PER_M
    z_m = -(lat - MAP_LAT) / LAT_DEG_PER_M
    px = int((x_m + HALF) / MAP_SIZE * CANVAS_SIZE)
    py = int((z_m + HALF) / MAP_SIZE * CANVAS_SIZE)
    return px, py


# ── Noise ───────────────────────────────────────────────────────────────────────
def fbm(x, y, seed, octaves=4, persistence=0.5, lacunarity=2.0):
    total = 0.0
    amplitude = 1.0
    freq = 1.0
    for _ in range(octaves):
        total += amplitude * opensimplex.noise2(x * freq + seed * 100, y * freq + seed * 100)
        amplitude *= persistence
        freq *= lacunarity
    return (total + 1.0) / 2.0  # normalise to 0..1


# ── OSM parsing ─────────────────────────────────────────────────────────────────
def parse_osm(path):
    print(f"  Parsing OSM: {path}")
    tree = ET.parse(path)
    root = tree.getroot()

    nodes = {}
    for node in root.iter("node"):
        nid = node.get("id")
        lat = float(node.get("lat"))
        lon = float(node.get("lon"))
        nodes[nid] = (lon, lat)

    woodlands = []
    waters = []

    for way in root.iter("way"):
        tags = {t.get("k"): t.get("v") for t in way.findall("tag")}
        nd_refs = [nd.get("ref") for nd in way.findall("nd")]
        coords = [nodes[r] for r in nd_refs if r in nodes]

        landuse = tags.get("landuse", "")
        natural = tags.get("natural", "")
        waterway = tags.get("waterway", "")

        is_woodland = landuse in ("forest", "wood") or natural in ("wood", "scrub")
        is_water = (natural == "water"
                    or waterway in ("river", "stream", "ditch", "drain")
                    or landuse == "reservoir")

        if is_woodland and len(coords) >= 3:
            woodlands.append(coords)
        elif is_water and len(coords) >= 2:
            waters.append(coords)

    print(f"    Woodland polygons: {len(woodlands)}, Water ways: {len(waters)}")
    return woodlands, waters


# ── Geometry helpers ─────────────────────────────────────────────────────────────
def seg_dist(px, py, ax, ay, bx, by):
    """Minimum distance from point (px,py) to segment (ax,ay)-(bx,by)."""
    dx, dy = bx - ax, by - ay
    if dx == 0 and dy == 0:
        return math.hypot(px - ax, py - ay)
    t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))
    return math.hypot(px - (ax + t * dx), py - (ay + t * dy))


def polyline_min_dist(px, py, coords):
    d = float("inf")
    for i in range(len(coords) - 1):
        ax, ay = coords[i]
        bx, by = coords[i + 1]
        d = min(d, seg_dist(px, py, ax, ay, bx, by))
    return d


def bbox(coords, pad=0):
    xs = [c[0] for c in coords]
    ys = [c[1] for c in coords]
    return int(min(xs) - pad), int(min(ys) - pad), int(max(xs) + pad), int(max(ys) + pad)


def point_in_polygon(px, py, poly):
    """Ray-cast point-in-polygon test."""
    n = len(poly)
    inside = False
    j = n - 1
    for i in range(n):
        xi, yi = poly[i]
        xj, yj = poly[j]
        if ((yi > py) != (yj > py)) and (px < (xj - xi) * (py - yi) / (yj - yi + 1e-12) + xi):
            inside = not inside
        j = i
    return inside


# ── Painting functions ───────────────────────────────────────────────────────────
def paint_line_buffer(canvas, coords_px, half_width_px, noise_scale, noise_amp,
                      gap_threshold, seed):
    if len(coords_px) < 2:
        return
    pad = int(half_width_px * 2.5)
    x0, y0, x1, y1 = bbox(coords_px, pad)
    x0, y0 = max(0, x0), max(0, y0)
    x1, y1 = min(CANVAS_SIZE - 1, x1), min(CANVAS_SIZE - 1, y1)

    cs = float(CANVAS_SIZE)
    for py in range(y0, y1 + 1):
        for px in range(x0, x1 + 1):
            dist = polyline_min_dist(px, py, coords_px)
            n_val = fbm(px / cs * noise_scale, py / cs * noise_scale, seed, octaves=3)
            w = half_width_px * (1 - noise_amp + n_val * noise_amp * 2)
            if dist < w:
                gap_n = fbm(px / cs * noise_scale * 0.5,
                            py / cs * noise_scale * 0.5, seed + 99, octaves=2)
                if gap_n > gap_threshold:
                    continue
                intensity = ((1 - dist / w) ** 2) * (0.6 + n_val * 0.4)
                if intensity > canvas[py, px]:
                    canvas[py, px] = intensity


def paint_polygon_fill(canvas, coords_px, density_min, density_max, edge_boost_px, seed):
    if len(coords_px) < 3:
        return
    x0, y0, x1, y1 = bbox(coords_px)
    x0, y0 = max(0, x0), max(0, y0)
    x1, y1 = min(CANVAS_SIZE - 1, x1), min(CANVAS_SIZE - 1, y1)

    cs = float(CANVAS_SIZE)
    poly = coords_px

    for py in range(y0, y1 + 1):
        # Scanline: find x-intersections
        intersections = []
        n = len(poly)
        j = n - 1
        for i in range(n):
            xi, yi = poly[i]
            xj, yj = poly[j]
            if (yi <= py < yj) or (yj <= py < yi):
                x_int = xi + (py - yi) * (xj - xi) / (yj - yi + 1e-12)
                intersections.append(x_int)
            j = i
        intersections.sort()

        for k in range(0, len(intersections) - 1, 2):
            ix0 = max(x0, int(math.ceil(intersections[k])))
            ix1 = min(x1, int(math.floor(intersections[k + 1])))
            for px in range(ix0, ix1 + 1):
                # Distance to polygon edge
                edge_dist = polyline_min_dist(px, py, poly)
                n_val = fbm(px / cs * 10, py / cs * 10, seed, octaves=4)
                base = density_min + n_val * (density_max - density_min)
                edge_factor = max(0.0, 1.0 - edge_dist / max(1, edge_boost_px))
                intensity = min(1.0, base + edge_factor * 0.3)
                if intensity > canvas[py, px]:
                    canvas[py, px] = intensity


def paint_blob(canvas, cx, cy, radius_px, seed):
    pad = int(radius_px * 1.5)
    x0, y0 = max(0, cx - pad), max(0, cy - pad)
    x1, y1 = min(CANVAS_SIZE - 1, cx + pad), min(CANVAS_SIZE - 1, cy + pad)

    cs = float(CANVAS_SIZE)
    for py in range(y0, y1 + 1):
        for px in range(x0, x1 + 1):
            dist = math.hypot(px - cx, py - cy)
            n = fbm(px / cs * 15, py / cs * 15, seed, octaves=3)
            effective_r = radius_px * (0.6 + n * 0.8)
            if dist < effective_r:
                intensity = (1 - dist / max(effective_r, 1e-9)) * (0.5 + n * 0.5)
                if intensity > canvas[py, px]:
                    canvas[py, px] = intensity


# ── Junction detection ───────────────────────────────────────────────────────────
def find_hedge_junctions(hedge_lines_px, proximity_px=8):
    endpoints = []
    for line in hedge_lines_px:
        if len(line) >= 2:
            endpoints.append(line[0])
            endpoints.append(line[-1])

    visited = [False] * len(endpoints)
    clusters = []
    for i, pt in enumerate(endpoints):
        if visited[i]:
            continue
        cluster = [pt]
        visited[i] = True
        for j in range(i + 1, len(endpoints)):
            if not visited[j]:
                if math.hypot(endpoints[j][0] - pt[0], endpoints[j][1] - pt[1]) <= proximity_px:
                    cluster.append(endpoints[j])
                    visited[j] = True
        if len(cluster) >= 2:
            cx = int(sum(p[0] for p in cluster) / len(cluster))
            cy = int(sum(p[1] for p in cluster) / len(cluster))
            clusters.append((cx, cy))

    return clusters


# ── Coverage stat ────────────────────────────────────────────────────────────────
def coverage_pct(canvas, threshold=0.05):
    return float(np.sum(canvas > threshold)) / (CANVAS_SIZE * CANVAS_SIZE) * 100.0


# ── Preview ──────────────────────────────────────────────────────────────────────
def generate_preview(layers, hedge_lines_px):
    print("\n  Generating preview...")
    scale = CANVAS_SIZE / PREVIEW_SIZE
    img = np.zeros((PREVIEW_SIZE, PREVIEW_SIZE, 3), dtype=np.uint8)

    # Base colour
    img[:, :] = (196, 168, 130)

    layer_order = [
        ("decoFoliage",  (74,  122,  58)),
        ("decoBushUS",   (90,   60,  30)),
        ("waterPlants",  (58,  107, 122)),
        ("decoBush",     (107, 140,  62)),
        ("forestPlants", (45,   90,  31)),
    ]

    for name, colour in layer_order:
        canvas = layers[name]
        lc = np.array(colour, dtype=np.float32)
        for py in range(PREVIEW_SIZE):
            for px in range(PREVIEW_SIZE):
                sy = int(py * scale)
                sx = int(px * scale)
                sy = min(sy, CANVAS_SIZE - 1)
                sx = min(sx, CANVAS_SIZE - 1)
                v = float(canvas[sy, sx])
                if v > 0.05:
                    base = img[py, px].astype(np.float32)
                    blended = base * (1 - v) + lc * v
                    img[py, px] = blended.clip(0, 255).astype(np.uint8)

    # Draw hedge lines on top
    prev_scale = PREVIEW_SIZE / CANVAS_SIZE
    for line in hedge_lines_px:
        for pt in line:
            ppx = int(pt[0] * prev_scale)
            ppy = int(pt[1] * prev_scale)
            if 0 <= ppx < PREVIEW_SIZE and 0 <= ppy < PREVIEW_SIZE:
                img[ppy, ppx] = (40, 60, 20)

    return img


# ── Main ─────────────────────────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true", help="Write density PNGs and backup")
    parser.add_argument("--dry-run", action="store_true", help="Preview only (default)")
    args = parser.parse_args()
    apply = args.apply

    mode = "APPLY" if apply else "DRY-RUN"
    print(f"=== paint_deco_foliage.py [{mode}] ===\n")

    # ── Load hedges ──────────────────────────────────────────────────────────────
    print("Stage 1: Loading hedge lines...")
    with open(HEDGE_GEOJSON) as f:
        hedge_gj = json.load(f)

    hedge_lines_wgs = []
    for feat in hedge_gj.get("features", []):
        geom = feat.get("geometry", {})
        if geom.get("type") == "LineString":
            hedge_lines_wgs.append(geom["coordinates"])  # list of [lon, lat]

    print(f"  Hedge lines loaded: {len(hedge_lines_wgs)}")

    hedge_lines_px = []
    for line in hedge_lines_wgs:
        px_line = [wgs84_to_px(c[0], c[1]) for c in line]
        hedge_lines_px.append(px_line)

    # ── Load OSM ─────────────────────────────────────────────────────────────────
    print("\nStage 2: Loading OSM features...")
    woodlands_wgs, waters_wgs = parse_osm(OSM_FILE)

    woodlands_px = [[wgs84_to_px(c[0], c[1]) for c in poly] for poly in woodlands_wgs]
    waters_px = [[wgs84_to_px(c[0], c[1]) for c in line] for line in waters_wgs]

    # ── Detect junctions ─────────────────────────────────────────────────────────
    print("\nStage 3: Detecting hedge junctions...")
    junctions = find_hedge_junctions(hedge_lines_px, proximity_px=8)
    print(f"  Junctions found: {len(junctions)}")

    # ── Initialise canvases ───────────────────────────────────────────────────────
    layers = {
        "decoFoliage":  np.zeros((CANVAS_SIZE, CANVAS_SIZE), dtype=np.float32),
        "forestPlants": np.zeros((CANVAS_SIZE, CANVAS_SIZE), dtype=np.float32),
        "decoBush":     np.zeros((CANVAS_SIZE, CANVAS_SIZE), dtype=np.float32),
        "waterPlants":  np.zeros((CANVAS_SIZE, CANVAS_SIZE), dtype=np.float32),
        "decoBushUS":   np.zeros((CANVAS_SIZE, CANVAS_SIZE), dtype=np.float32),
    }

    # ── Paint hedges → decoFoliage ────────────────────────────────────────────────
    print("\nStage 4: Painting hedge lines → decoFoliage...")
    for i, line in enumerate(hedge_lines_px):
        if i % 50 == 0:
            print(f"  Hedge {i}/{len(hedge_lines_px)}")
        paint_line_buffer(
            layers["decoFoliage"], line,
            half_width_px=4, noise_scale=6, noise_amp=0.5,
            gap_threshold=0.73, seed=i * 3
        )
    print(f"  Done. {len(hedge_lines_px)} lines painted.")

    # ── Paint junctions → decoBushUS ──────────────────────────────────────────────
    print("\nStage 5: Painting junctions → decoBushUS...")
    cs = float(CANVAS_SIZE)
    for k, (cx, cy) in enumerate(junctions):
        n_val = fbm(cx / cs * 5, cy / cs * 5, k)
        radius = 6 + int(n_val * 10)
        paint_blob(layers["decoBushUS"], cx, cy, radius, seed=k * 7)
    print(f"  Done. {len(junctions)} junction blobs painted.")

    # ── Paint woodland polygons → forestPlants ────────────────────────────────────
    print("\nStage 6: Painting woodland polygons → forestPlants...")
    for i, poly in enumerate(woodlands_px):
        if i % 20 == 0:
            print(f"  Woodland {i}/{len(woodlands_px)}")
        paint_polygon_fill(
            layers["forestPlants"], poly,
            density_min=0.45, density_max=0.90, edge_boost_px=35, seed=i * 11
        )
    print(f"  Done. {len(woodlands_px)} woodland polygons painted.")

    # ── Paint woodland edges → decoBush ───────────────────────────────────────────
    print("\nStage 7: Painting woodland edges → decoBush...")
    for i, poly in enumerate(woodlands_px):
        if i % 20 == 0:
            print(f"  Woodland edge {i}/{len(woodlands_px)}")
        # Close ring
        ring = poly if poly[0] == poly[-1] else poly + [poly[0]]
        edge_band = int(10 + fbm(i * 0.3, i * 0.7, 42) * 10)
        paint_line_buffer(
            layers["decoBush"], ring,
            half_width_px=edge_band, noise_scale=5, noise_amp=0.6,
            gap_threshold=0.90, seed=i * 5
        )
    print(f"  Done. {len(woodlands_px)} woodland edges painted.")

    # ── Paint water lines → waterPlants ───────────────────────────────────────────
    print("\nStage 8: Painting water lines → waterPlants...")
    for i, line in enumerate(waters_px):
        if i % 100 == 0:
            print(f"  Water {i}/{len(waters_px)}")
        paint_line_buffer(
            layers["waterPlants"], line,
            half_width_px=3, noise_scale=8, noise_amp=0.4,
            gap_threshold=0.85, seed=i * 13
        )
    print(f"  Done. {len(waters_px)} water lines painted.")

    # ── Coverage stats ────────────────────────────────────────────────────────────
    print("\n── Layer coverage ──────────────────────────────────────────────────")
    for name, canvas in layers.items():
        pct = coverage_pct(canvas)
        print(f"  {name:16s}: {pct:.2f}% pixels > 0.05")

    # ── Preview (always) ──────────────────────────────────────────────────────────
    os.makedirs(os.path.dirname(PREVIEW_PATH), exist_ok=True)
    preview_arr = generate_preview(layers, hedge_lines_px)
    Image.fromarray(preview_arr).save(PREVIEW_PATH)
    print(f"\n  Preview saved: {PREVIEW_PATH}")

    if not apply:
        print("\n[DRY-RUN] No density PNGs written. Run with --apply to write outputs.")
        return

    # ── Apply: backup existing density files ─────────────────────────────────────
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_dir = os.path.join(BACKUP_BASE, timestamp)
    if os.path.isdir(OUTPUT_DIR) and os.listdir(OUTPUT_DIR):
        print(f"\nBacking up existing density files to {backup_dir}...")
        os.makedirs(backup_dir, exist_ok=True)
        for fn in os.listdir(OUTPUT_DIR):
            src = os.path.join(OUTPUT_DIR, fn)
            shutil.copy2(src, os.path.join(backup_dir, fn))
        # Write restore script
        restore_path = os.path.join(ROOT, "pipeline", "restore_foliage_backup.py")
        with open(restore_path, "w") as f:
            f.write(f'''#!/usr/bin/env python3
"""Auto-generated restore script — restores foliage density PNGs from backup {timestamp}."""
import shutil, os
BACKUP = {repr(backup_dir)}
DEST   = {repr(OUTPUT_DIR)}
os.makedirs(DEST, exist_ok=True)
for fn in os.listdir(BACKUP):
    shutil.copy2(os.path.join(BACKUP, fn), os.path.join(DEST, fn))
    print(f"Restored {{fn}}")
print("Done.")
''')
        print(f"  Restore script written: {restore_path}")

    # ── Write density PNGs ────────────────────────────────────────────────────────
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print(f"\nWriting density PNGs to {OUTPUT_DIR}...")
    for name, canvas in layers.items():
        out = (canvas * 255).clip(0, 255).astype(np.uint8)
        path = os.path.join(OUTPUT_DIR, f"{name}_density.png")
        Image.fromarray(out, mode="L").save(path)
        print(f"  Wrote: {path}")

    print("\n=== Done ===")


if __name__ == "__main__":
    main()
