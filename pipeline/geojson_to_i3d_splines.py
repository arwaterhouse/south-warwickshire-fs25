#!/usr/bin/env python3
"""
geojson_to_i3d_splines.py — South Warwickshire FS25
=====================================================

Bridges the GeoJSON pipeline outputs into Giants Editor i3d spline files.

What it does:
  Reads GeoJSON feature collections produced by the pipeline scripts
  and converts them to i3d XML files that can be imported into Giants
  Editor via Scene → Merge Scene (or File → Import).

  After import, use the companion Lua scripts inside GE to:
    • sw_batch_spline_placer.lua    → place hedge/fence objects along all
                                      splines in a group in one pass
    • FSG-FS25-4x-RoadTracksHeightPaintFoliageBySpline-v3.lua
                                   → paint road textures + sink terrain
    • FSG-FS25-SplineToFieldConverter-v5.lua
                                   → convert field-boundary splines to
                                      FS25 field definitions
    • FSG-FS25-AlignChildsToTerrain-v1.lua
                                   → snap all placed objects to terrain

Outputs (written to outputs/):
  sw_hedge_splines.i3d    — 3 groups: osm_hedges (curated), osm_hedges_extra, inferred_hedges
  sw_road_splines.i3d     — 4 groups: roads, service_roads, dirt_tracks, footpaths
                            NOTE: maps4fs already generates road splines in
                            map/map/splines.i3d. Ours add hedge-painting &
                            terrain-sinking via the Lua scripts.
  sw_field_splines.i3d    — 1 group:  field_boundaries (from fs25_fields_osm.geojson)
  sw_water_splines.i3d    — 1 group:  waterways (streams, ditches)
  sw_forest_splines.i3d   — 1 group:  woodland_boundaries (for tree replicator zones)

Coordinate system:
  Maps4fs / Giants Engine uses a local flat coordinate system where:
    X  = East  (+ve)
    Z  = South (+ve)   ← note: increasing Z = moving south
    Y  = height (0 here; terrain-aligned in GE after import)
  Origin = map centre at (MAP_LAT, MAP_LON).
  For a 4×4 km map, the usable range is ±2048 m in both axes.

  Transform: given a WGS84 (lat, lon) coordinate,
    fs25_x = (lon - MAP_CENTRE_LON) * 111320 * cos(MAP_CENTRE_LAT_RAD)
    fs25_z = -(lat - MAP_CENTRE_LAT) * 111320
    fs25_y = 0.0   (snapped to terrain later in GE)

Usage:
  python3 geojson_to_i3d_splines.py [--output-dir ../outputs]
"""

import json
import math
import argparse
import os
import xml.etree.ElementTree as ET
from pathlib import Path

try:
    from shapely.geometry import shape, LineString, MultiLineString
    from shapely.ops import unary_union
    from shapely.strtree import STRtree
    import geopandas as gpd
    SHAPELY_AVAILABLE = True
except ImportError:
    SHAPELY_AVAILABLE = False

# ── Authoritative map centre (from run_maps4fs.py / maps4fs coordinates) ──────
MAP_CENTRE_LAT = 52.089387
MAP_CENTRE_LON = -1.532290
MAP_SIZE_M     = 4096           # full map size in metres
MAP_HALF_M     = MAP_SIZE_M / 2 # ±2048 m usable range

# Pre-computed constants
LAT_RAD       = math.radians(MAP_CENTRE_LAT)
M_PER_DEG_LAT = 111320.0
M_PER_DEG_LON = 111320.0 * math.cos(LAT_RAD)

# Minimum spline length in FS25 metres — skip shorter features
MIN_SPLINE_LEN_M = 8.0

# Maximum control vertices per spline.
# Very long hedges/roads are split into segments.
MAX_CVS_PER_SPLINE = 200

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR  = Path(__file__).resolve().parent
ROOT_DIR    = SCRIPT_DIR.parent
OUTPUTS_DIR = ROOT_DIR / "outputs"

INPUT_HEDGES_EDITED   = ROOT_DIR / "data" / "fs25_hedges_edited.geojson"  # user-edited authoritative hedge lines
INPUT_ROADS           = OUTPUTS_DIR / "fs25_roads.geojson"

# ── Field hedge road-clipping constants ──────────────────────────────────────
# Road exclusion clip buffer for field hedges.
# Removes hedge sections that overlap a road surface (junction areas etc).
ROAD_CLEARANCE_M = 1.0

# ── Road hedge generation constants ──────────────────────────────────────────
# Standard road half-width used when per-road width_m is not available.
ROAD_HEDGE_DEFAULT_WIDTH_M = 8.0

# Grass verge between tarmac edge and hedge centreline.
ROAD_HEDGE_VERGE_M = 1.0

# Road types to generate hedge splines for (both sides).
ROAD_HEDGE_TYPES = {"road", "service"}
INPUT_FIELDS_OSM      = OUTPUTS_DIR / "fs25_fields_osm.geojson"   # new OSM-based fields with lucode
INPUT_FIELDS_CROME    = OUTPUTS_DIR / "crome_south_warwickshire_fs25.geojson"  # fallback
INPUT_WATER           = OUTPUTS_DIR / "fs25_water.geojson"
INPUT_FOREST          = OUTPUTS_DIR / "fs25_forest.geojson"

# ── Coordinate helpers ────────────────────────────────────────────────────────

def latlon_to_fs25(lon: float, lat: float) -> tuple[float, float, float]:
    """Convert WGS84 (lon, lat) to FS25 world coordinates (x, y=0, z)."""
    x = (lon - MAP_CENTRE_LON) * M_PER_DEG_LON
    z = -(lat - MAP_CENTRE_LAT) * M_PER_DEG_LAT
    return x, 0.0, z


def convert_coords(coords_lonlat: list) -> list[tuple]:
    """Convert a list of [lon, lat] pairs to FS25 (x, y, z) tuples."""
    return [latlon_to_fs25(c[0], c[1]) for c in coords_lonlat]


def spline_length_fs25(cvs: list[tuple]) -> float:
    """Approximate spline length in FS25 metres from control vertices."""
    total = 0.0
    for i in range(len(cvs) - 1):
        dx = cvs[i+1][0] - cvs[i][0]
        dz = cvs[i+1][2] - cvs[i][2]
        total += math.sqrt(dx*dx + dz*dz)
    return total


def in_map_bounds(x: float, z: float, margin: float = 200.0) -> bool:
    """Return True if point is within map bounds (with margin)."""
    limit = MAP_HALF_M + margin
    return -limit <= x <= limit and -limit <= z <= limit


def clip_cvs_to_map(cvs: list[tuple]) -> list[tuple]:
    """Keep only CVs that are within map bounds + margin."""
    return [cv for cv in cvs if in_map_bounds(cv[0], cv[2])]


def chunk_cvs(cvs: list, max_size: int) -> list[list]:
    """Split a CV list into chunks of max_size with 1-point overlap."""
    if len(cvs) <= max_size:
        return [cvs]
    chunks = []
    i = 0
    while i < len(cvs):
        chunk = cvs[i:i + max_size]
        chunks.append(chunk)
        i += max_size - 1  # 1-point overlap for continuity
    return chunks


# ── i3d XML builder ───────────────────────────────────────────────────────────

class I3DBuilder:
    """Builds a Giants Engine i3d XML document containing spline shapes.

    Uses the NurbsCurve format confirmed working in GE10 (same as maps4fs
    splines.i3d output):
      Shapes section:  <NurbsCurve shapeId="N" degree="3" form="open">
                         <cv c="x, y, z" />
                       </NurbsCurve>
      Scene section:   <Shape nodeId="N" shapeId="N" />   (no materialIds)
    """

    def __init__(self, name: str):
        self.name = name
        self._node_id  = 0   # scene node counter (TransformGroups + Shapes)
        self._shape_id = 0   # geometry definition counter (NurbsCurve)

        self.root = ET.Element("i3D", {
            "name": name,
            "version": "1.6",
            "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
            "xsi:noNamespaceSchemaLocation":
                "http://i3d.giants.ch/schema/i3d-1.6.xsd",
        })
        ET.SubElement(self.root, "Files")
        # No Materials section — splines don't use materials

        self.shapes = ET.SubElement(self.root, "Shapes")
        self.scene  = ET.SubElement(self.root, "Scene")

    def _next_node_id(self) -> str:
        self._node_id += 1
        return str(self._node_id)

    def _next_shape_id(self) -> str:
        self._shape_id += 1
        return str(self._shape_id)

    def add_group(self, group_name: str,
                  splines: list[dict],
                  form: str = "open") -> int:
        """
        Add a TransformGroup containing multiple splines to the scene.

        splines: list of dicts with keys:
            'name'  : str  — unique spline name
            'cvs'   : list of (x, y, z) tuples

        Returns the number of splines actually added.
        """
        group_node_id = self._next_node_id()
        group_el = ET.SubElement(self.scene, "TransformGroup", {
            "name": group_name,
            "nodeId": group_node_id,
            "visibility": "true",
            "translation": "0 0 0",
            "rotation": "0 0 0",
            "scale": "1 1 1",
        })

        added = 0
        for spline_def in splines:
            cvs = spline_def["cvs"]
            base_name = spline_def["name"]

            chunks = chunk_cvs(cvs, MAX_CVS_PER_SPLINE)
            for ci, chunk in enumerate(chunks):
                if len(chunk) < 2:
                    continue
                length = spline_length_fs25(chunk)
                if length < MIN_SPLINE_LEN_M:
                    continue

                suffix = f"_{ci+1:02d}" if len(chunks) > 1 else ""
                spline_name = f"{base_name}{suffix}"
                shape_id    = self._next_shape_id()
                node_id     = self._next_node_id()

                # Scene node — shapeId matches NurbsCurve shapeId, no materialIds
                ET.SubElement(group_el, "Shape", {
                    "name": spline_name,
                    "nodeId": node_id,
                    "shapeId": shape_id,
                    "translation": "0 0 0",
                })

                # NurbsCurve geometry in <Shapes> — GE10 confirmed format
                curve_el = ET.SubElement(self.shapes, "NurbsCurve", {
                    "name": spline_name,
                    "shapeId": shape_id,
                    "degree": "3",
                    "form": form,
                })
                for x, y, z in chunk:
                    # CV coordinates MUST use comma-space format: "x, y, z"
                    ET.SubElement(curve_el, "cv", {
                        "c": f"{x:.3f}, {y:.3f}, {z:.3f}",
                    })

                added += 1

        return added

    def write(self, path: Path):
        """Write pretty-printed i3d XML to disk."""
        ET.indent(self.root, space="  ")
        tree = ET.ElementTree(self.root)
        ET.indent(tree, space="  ")
        with open(path, "w", encoding="utf-8") as f:
            f.write('<?xml version="1.0" encoding="utf-8"?>\n')
            f.write(ET.tostring(self.root, encoding="unicode"))
        print(f"  → {path}")


# ── GeoJSON processors ────────────────────────────────────────────────────────

def load_geojson(path: Path) -> list:
    """Load GeoJSON features from a file. Returns [] if file missing."""
    if not path.exists():
        print(f"  WARNING: {path.name} not found — skipping.")
        return []
    with open(path) as f:
        data = json.load(f)
    return data.get("features", [])


def linestring_to_spline_def(feature, name: str) -> dict | None:
    """
    Convert a GeoJSON LineString feature to a spline definition dict.
    Returns None if the feature is too short or entirely out of bounds.
    """
    geom = feature.get("geometry", {})
    if geom.get("type") != "LineString":
        return None
    coords = geom.get("coordinates", [])
    if len(coords) < 2:
        return None

    cvs = convert_coords(coords)
    cvs = clip_cvs_to_map(cvs)
    if len(cvs) < 2:
        return None
    if spline_length_fs25(cvs) < MIN_SPLINE_LEN_M:
        return None

    return {"name": name, "cvs": cvs}


def polygon_outer_ring_to_spline(feature, name: str) -> dict | None:
    """
    Convert a GeoJSON Polygon outer ring to a closed spline definition.
    """
    geom = feature.get("geometry", {})
    gtype = geom.get("type", "")
    if gtype == "Polygon":
        ring = geom.get("coordinates", [[]])[0]
    elif gtype == "MultiPolygon":
        # Use largest ring by vertex count
        rings = [p[0] for p in geom.get("coordinates", [])]
        ring = max(rings, key=len, default=[])
    else:
        return None

    if len(ring) < 3:
        return None

    # Remove duplicate closing coordinate (GeoJSON polygons close on themselves)
    if ring[0] == ring[-1]:
        ring = ring[:-1]

    cvs = convert_coords(ring)
    cvs = clip_cvs_to_map(cvs)
    if len(cvs) < 3:
        return None
    if spline_length_fs25(cvs) < MIN_SPLINE_LEN_M:
        return None

    return {"name": name, "cvs": cvs}


# ── Hedge verge placement ─────────────────────────────────────────────────────

def offset_parallel_hedges(features: list, road_features: list) -> list:
    """
    Push individual hedge vertices away from any road they are too close to.

    For every vertex in every hedge linestring, we find the nearest road
    centreline.  If that vertex is closer than  road_width/2 + VERGE_WIDTH_M
    we move it radially outward to exactly that distance.

    This works regardless of the angle between hedge and road, so it handles
    roadside hedges, diagonal field boundaries, and everything in between.
    The clip pass that follows will still tidy up junction crossing sections.
    """
    if not SHAPELY_AVAILABLE or not road_features:
        return features

    from shapely.geometry import Point

    roads_gdf = gpd.GeoDataFrame(
        [{"geometry": shape(f["geometry"]),
          "width_m":  f.get("properties", {}).get("width_m", 4.0)}
         for f in road_features],
        crs="EPSG:4326",
    ).to_crs("EPSG:27700")

    hedges_gdf = gpd.GeoDataFrame(
        [{"geometry": shape(f["geometry"]),
          "props":    f.get("properties", {}),
          "idx":      i}
         for i, f in enumerate(features)
         if f.get("geometry", {}).get("type") == "LineString"],
        crs="EPSG:4326",
    ).to_crs("EPSG:27700")

    road_tree     = STRtree(roads_gdf.geometry.values)
    moved_points  = 0
    moved_hedges  = 0

    result_geoms = {}

    for _, hedge_row in hedges_gdf.iterrows():
        hedge_geom  = hedge_row.geometry
        orig_coords = list(hedge_geom.coords)
        new_coords  = []
        hedge_moved = False

        # Only process hedges that have any vertex near a road
        nearby_idxs = road_tree.query(hedge_geom.buffer(PARALLEL_SEARCH_M))

        # Build a quick lookup: road index → target clearance distance
        road_targets = []
        for ri in nearby_idxs:
            road = roads_gdf.iloc[ri]
            target = road.width_m / 2.0 + VERGE_WIDTH_M
            road_targets.append((road.geometry, target))

        for x, y in orig_coords:
            pt = Point(x, y)
            nx, ny = x, y
            best_push = 0.0  # track largest displacement so far

            for road_geom, target in road_targets:
                dist = pt.distance(road_geom)
                if dist >= target:
                    continue  # already far enough
                if dist < 0.01:
                    dist = 0.01

                # Nearest point on road centreline
                nearest = road_geom.interpolate(road_geom.project(pt))
                dx = x - nearest.x
                dy = y - nearest.y
                length = math.sqrt(dx * dx + dy * dy)
                if length < 0.001:
                    continue
                push = target - dist
                if push <= best_push:
                    continue  # a larger push from another road already applied
                # Scale to exactly target distance from this road
                scale = target / length
                nx = nearest.x + dx * scale
                ny = nearest.y + dy * scale
                best_push = push
                hedge_moved = True

            if best_push > 0:
                moved_points += 1
            new_coords.append((nx, ny))

        if hedge_moved:
            result_geoms[hedge_row["idx"]] = LineString(new_coords)
            moved_hedges += 1

    # Re-project shifted geometries back to WGS84
    out_features = []
    for i, feat in enumerate(features):
        if i in result_geoms:
            shifted_wgs84 = (
                gpd.GeoDataFrame([{"geometry": result_geoms[i]}], crs="EPSG:27700")
                .to_crs("EPSG:4326")
                .iloc[0]
                .geometry
            )
            out_features.append({
                "type":       "Feature",
                "geometry":   {"type": "LineString",
                               "coordinates": list(shifted_wgs84.coords)},
                "properties": feat.get("properties", {}),
            })
        else:
            out_features.append(feat)

    print(f"     verge push: {moved_hedges} hedges adjusted, "
          f"{moved_points} vertices moved to {VERGE_WIDTH_M}m from tarmac edge")
    return out_features


# ── Road exclusion ────────────────────────────────────────────────────────────

def build_road_exclusion_zone(road_features: list):
    """
    Build a Shapely geometry (in EPSG:27700 metres) representing the union of
    all road buffers.  Each road is buffered by  width_m/2 + ROAD_CLEARANCE_M
    so that hedge splines don't overlap with road surfaces.

    Returns None if Shapely/GeoPandas are not installed.
    """
    if not SHAPELY_AVAILABLE or not road_features:
        return None

    rows = []
    for feat in road_features:
        geom = shape(feat["geometry"])
        width_m = feat.get("properties", {}).get("width_m", 4.0)
        rows.append({"geometry": geom, "width_m": width_m})

    gdf = gpd.GeoDataFrame(rows, crs="EPSG:4326").to_crs("EPSG:27700")
    buffers = [
        row.geometry.buffer(row.width_m / 2.0 + ROAD_CLEARANCE_M)
        for _, row in gdf.iterrows()
    ]
    return unary_union(buffers)


def clip_hedges_away_from_roads(features: list, road_excl_zone) -> list:
    """
    Given a list of GeoJSON hedge features (WGS84 LineStrings) and a road
    exclusion zone geometry (EPSG:27700), return a new flat list of GeoJSON
    LineString features with road-overlapping sections removed.

    Segments shorter than MIN_SPLINE_LEN_M after clipping are dropped.
    """
    if not SHAPELY_AVAILABLE or road_excl_zone is None:
        return features

    hedges_gdf = gpd.GeoDataFrame(
        [{"geometry": shape(f["geometry"]), "props": f.get("properties", {})}
         for f in features
         if f.get("geometry", {}).get("type") == "LineString"],
        crs="EPSG:4326",
    ).to_crs("EPSG:27700")

    clipped_features = []
    for _, row in hedges_gdf.iterrows():
        try:
            clipped = row.geometry.difference(road_excl_zone)
        except Exception:
            clipped = row.geometry

        if clipped.is_empty:
            continue

        # difference() can return LineString or MultiLineString
        if clipped.geom_type == "LineString":
            parts = [clipped]
        elif clipped.geom_type == "MultiLineString":
            parts = list(clipped.geoms)
        else:
            continue

        for part in parts:
            if part.length < MIN_SPLINE_LEN_M:
                continue
            # Re-project back to WGS84 for the normal conversion pipeline
            part_wgs84 = (
                gpd.GeoDataFrame([{"geometry": part}], crs="EPSG:27700")
                .to_crs("EPSG:4326")
                .iloc[0]
                .geometry
            )
            clipped_features.append({
                "type": "Feature",
                "geometry": {"type": "LineString",
                             "coordinates": list(part_wgs84.coords)},
                "properties": row.props,
            })

    return clipped_features


# ── Main processors ───────────────────────────────────────────────────────────

def build_hedge_i3d(features: list, output_path: Path,
                    road_excl_zone=None):
    """
    Build sw_hedge_splines.i3d from the user-edited field hedge data.
    Field hedges are trusted as-is (hand-edited from aerial imagery).
    Only clipping is applied to remove sections that cross road surfaces.
    Road-parallel hedges are handled separately in sw_road_hedge_splines.i3d.
    """
    builder = I3DBuilder("sw_hedge_splines")

    # Clip anything that overlaps a road surface (junction crossings etc)
    before = sum(1 for f in features if f.get("geometry", {}).get("type") == "LineString")
    features = clip_hedges_away_from_roads(features, road_excl_zone)
    print(f"     road clipping: {before} → {len(features)} segments "
          f"(clip buffer = road_width/2 + {ROAD_CLEARANCE_M}m)")

    hedge_splines = []
    i = 0
    for feat in features:
        if feat.get("geometry", {}).get("type") != "LineString":
            continue
        i += 1
        spline = linestring_to_spline_def(feat, f"hedge_{i:04d}")
        if spline:
            hedge_splines.append(spline)

    n = builder.add_group("hedges", hedge_splines, form="open")
    builder.write(output_path)
    print(f"     hedges: {n:>5} splines")


def build_road_hedge_i3d(road_features: list, output_path: Path):
    """
    Build sw_road_hedge_splines.i3d.

    Generates hedge splines as true parallel offsets of road centrelines.
    Each road gets two splines — one on each side — offset by:
        road_width / 2  +  ROAD_HEDGE_VERGE_M

    This guarantees hedges run perfectly parallel to roads at a consistent
    verge distance, regardless of how the original hedge survey data was drawn.

    Only ROAD_HEDGE_TYPES road types are processed (road, service).
    """
    if not SHAPELY_AVAILABLE:
        print("  WARNING: shapely not available — road hedge splines skipped")
        return

    from shapely.geometry import LineString as ShapelyLine, MultiLineString

    builder = I3DBuilder("sw_road_hedge_splines")

    # Project to metres for accurate offsetting
    roads_gdf = gpd.GeoDataFrame(
        [{"geometry": shape(f["geometry"]),
          "fs25_type": f.get("properties", {}).get("fs25_type", "road"),
          "width_m":   f.get("properties", {}).get("width_m", ROAD_HEDGE_DEFAULT_WIDTH_M),
          "name":      f.get("properties", {}).get("name", "")}
         for f in road_features
         if f.get("geometry", {}).get("type") == "LineString"],
        crs="EPSG:4326",
    ).to_crs("EPSG:27700")

    left_splines  = []
    right_splines = []
    li = ri = 0

    for _, row in roads_gdf.iterrows():
        if row.fs25_type not in ROAD_HEDGE_TYPES:
            continue

        offset_m = row.width_m / 2.0 + ROAD_HEDGE_VERGE_M

        for side, sign in (("left", 1), ("right", -1)):
            try:
                offset_geom = row.geometry.offset_curve(sign * offset_m)
            except Exception:
                continue

            if offset_geom is None or offset_geom.is_empty:
                continue

            # offset_curve can return LineString or MultiLineString
            parts = (list(offset_geom.geoms)
                     if offset_geom.geom_type == "MultiLineString"
                     else [offset_geom])

            for part in parts:
                if part.length < MIN_SPLINE_LEN_M:
                    continue

                # Re-project back to WGS84 then convert to FS25
                part_wgs84 = (
                    gpd.GeoDataFrame([{"geometry": part}], crs="EPSG:27700")
                    .to_crs("EPSG:4326")
                    .iloc[0]
                    .geometry
                )
                coords = list(part_wgs84.coords)
                cvs = convert_coords(coords)
                cvs = clip_cvs_to_map(cvs)
                if len(cvs) < 2:
                    continue
                if spline_length_fs25(cvs) < MIN_SPLINE_LEN_M:
                    continue

                if side == "left":
                    li += 1
                    left_splines.append({"name": f"road_hedge_L_{li:04d}", "cvs": cvs})
                else:
                    ri += 1
                    right_splines.append({"name": f"road_hedge_R_{ri:04d}", "cvs": cvs})

    nl = builder.add_group("road_hedges_left",  left_splines,  form="open")
    nr = builder.add_group("road_hedges_right", right_splines, form="open")
    builder.write(output_path)
    print(f"     road_hedges_left:  {nl:>4} splines")
    print(f"     road_hedges_right: {nr:>4} splines")
    print(f"     offset = road_width/2 + {ROAD_HEDGE_VERGE_M}m verge")


def build_road_i3d(features: list, output_path: Path):
    """Build sw_road_splines.i3d from fs25_roads.geojson features."""
    builder = I3DBuilder("sw_road_splines")

    groups = {
        "road":        [],
        "service":     [],
        "dirt_track":  [],
        "footpath":    [],
    }
    counters = {k: 0 for k in groups}

    for feat in features:
        fs25_type = feat.get("properties", {}).get("fs25_type", "road")
        if fs25_type not in groups:
            fs25_type = "road"
        counters[fs25_type] += 1
        name   = f"{fs25_type}_{counters[fs25_type]:04d}"
        spline = linestring_to_spline_def(feat, name)
        if spline:
            # Attach width as a property comment (stored in name suffix)
            width = feat.get("properties", {}).get("width_m", 4.0)
            spline["width_m"] = width
            groups[fs25_type].append(spline)

    group_name_map = {
        "road":       "sw_roads",
        "service":    "sw_service_roads",
        "dirt_track": "sw_dirt_tracks",
        "footpath":   "sw_footpaths",
    }

    for key, splines in groups.items():
        n = builder.add_group(group_name_map[key], splines, form="open")
        print(f"     {group_name_map[key]:<22} {n:>5} splines")

    builder.write(output_path)


def build_field_i3d(features: list, output_path: Path):
    """
    Build sw_field_splines.i3d from field polygon features.

    Handles both property schemas:
      fs25_fields_osm.geojson  — uses 'fs25_category' (capitalised), 'fs25_crop'
      crome_south_warwickshire_fs25.geojson — uses 'fs25_category' (lowercase), 'fs25_fruit'
    """
    builder = I3DBuilder("sw_field_splines")

    field_splines = []
    field_i = 0

    SKIP_CATEGORIES = {"woodland", "farmyard", "Woodland", "Farmyard"}

    for feat in features:
        props    = feat.get("properties", {})
        category = props.get("fs25_category", "arable")
        if category in SKIP_CATEGORIES:
            continue
        field_i += 1
        # Support both property name variants
        crop = (props.get("fs25_crop") or props.get("fs25_fruit") or "field")
        # Sanitise crop name for use in XML attribute
        crop_safe = crop.replace(" ", "_").replace("/", "_")[:20]
        name  = f"field_{field_i:04d}_{crop_safe}"
        spline = polygon_outer_ring_to_spline(feat, name)
        if spline:
            field_splines.append(spline)

    n = builder.add_group("field_boundaries", field_splines, form="open")
    # SplineToFieldConverter expects open splines tracing the boundary
    print(f"     field_boundaries: {n:>5} splines")
    builder.write(output_path)


def build_forest_i3d(features: list, output_path: Path):
    """
    Build sw_forest_splines.i3d from fs25_forest.geojson polygon features.
    Woodland boundaries as splines — useful for:
      • FSG-FS25-TreeReplicatorByPaint-v7.lua (paint woodland texture first, then scatter trees)
      • FSG-FS25-SelectionReplicatorByPaint-v1.lua (scatter undergrowth)
    """
    builder = I3DBuilder("sw_forest_splines")

    woodland_splines = []
    w_i = 0

    for feat in features:
        geom_type = feat.get("geometry", {}).get("type", "")
        if geom_type not in ("Polygon", "MultiPolygon"):
            continue
        w_i += 1
        name  = feat.get("properties", {}).get("name", "") or f"woodland_{w_i:04d}"
        name  = f"woodland_{w_i:04d}_{name[:20].replace(' ','_')}"
        spline = polygon_outer_ring_to_spline(feat, name)
        if spline:
            woodland_splines.append(spline)

    n = builder.add_group("woodland_boundaries", woodland_splines, form="open")
    print(f"     woodland_boundaries: {n:>5} splines")
    builder.write(output_path)


def build_water_i3d(features: list, output_path: Path):
    """Build sw_water_splines.i3d from fs25_water.geojson linestring features."""
    builder = I3DBuilder("sw_water_splines")

    water_splines = []
    w_i = 0

    for feat in features:
        geom = feat.get("geometry", {})
        if geom.get("type") != "LineString":
            continue
        w_i += 1
        wtype = feat.get("properties", {}).get("waterway", "stream")
        name  = f"{wtype}_{w_i:04d}"
        spline = linestring_to_spline_def(feat, name)
        if spline:
            water_splines.append(spline)

    n = builder.add_group("waterways", water_splines, form="open")
    print(f"     waterways:        {n:>5} splines")
    builder.write(output_path)


# ── Sanity check ──────────────────────────────────────────────────────────────

def sanity_check():
    """Verify the coordinate transform is sane with a known landmark."""
    # Stratford-upon-Avon centre: ~52.1918° N, 1.7083° W
    # Should be south-east of map centre in FS25 coordinates
    test_lat, test_lon = 52.1918, -1.7083
    x, _, z = latlon_to_fs25(test_lon, test_lat)
    # Stratford is NW of our centre, so x should be negative, z should be negative
    assert x < 0, f"Expected negative X for Stratford (west), got {x:.0f}"
    assert z < 0, f"Expected negative Z for Stratford (north), got {z:.0f}"
    print(f"  Sanity check OK — Stratford-upon-Avon → FS25 ({x:.0f}, 0, {z:.0f})")

    # Check map centre itself maps to origin
    cx, _, cz = latlon_to_fs25(MAP_CENTRE_LON, MAP_CENTRE_LAT)
    assert abs(cx) < 0.01 and abs(cz) < 0.01, f"Centre should be ~0,0 got {cx},{cz}"
    print(f"  Map centre → FS25 ({cx:.3f}, 0, {cz:.3f})  ✓")


# ── Inconsistency check ───────────────────────────────────────────────────────

def warn_inconsistency():
    """
    Previously there was a map-centre mismatch between crome_osm_to_fs25.py
    and run_maps4fs.py. This has been resolved — both now use the authoritative
    centre: MAP_CENTRE_LAT=52.089387, MAP_CENTRE_LON=-1.532290.
    Function retained as a no-op.
    """
    pass


# ── Entry point ───────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Convert GeoJSON pipeline outputs to Giants Editor i3d splines"
    )
    parser.add_argument(
        "--output-dir",
        default=str(OUTPUTS_DIR),
        help="Directory to write .i3d files (default: outputs/)",
    )
    parser.add_argument(
        "--skip-hedges",       action="store_true", help="Skip field hedge splines"
    )
    parser.add_argument(
        "--skip-road-hedges",  action="store_true", help="Skip road hedge splines"
    )
    parser.add_argument(
        "--skip-roads",        action="store_true", help="Skip road splines"
    )
    parser.add_argument(
        "--skip-fields",  action="store_true", help="Skip field boundary splines"
    )
    parser.add_argument(
        "--skip-water",   action="store_true", help="Skip waterway splines"
    )
    args = parser.parse_args()

    out_dir = Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    print("=" * 60)
    print("  GeoJSON → i3d Spline Converter")
    print(f"  Map centre: {MAP_CENTRE_LAT}, {MAP_CENTRE_LON}")
    print(f"  Map size:   {MAP_SIZE_M}m ({MAP_HALF_M}m half-extent)")
    print("=" * 60)

    sanity_check()
    warn_inconsistency()

    if not args.skip_hedges:
        print("Building field hedge splines...")
        # Build road exclusion zone to clip field hedges that cross road surfaces
        road_excl_zone = None
        if SHAPELY_AVAILABLE:
            road_feats_for_clip = load_geojson(INPUT_ROADS)
            road_excl_zone = build_road_exclusion_zone(road_feats_for_clip)
            if road_excl_zone:
                print(f"  Road exclusion zone built from {len(road_feats_for_clip)} roads "
                      f"(clearance = {ROAD_CLEARANCE_M}m)")
            else:
                print("  WARNING: could not build road exclusion zone — hedges unclipped")
        else:
            print("  WARNING: shapely not available — hedge road-clipping skipped")
        features = load_geojson(INPUT_HEDGES_EDITED)
        if features:
            build_hedge_i3d(features, out_dir / "sw_hedge_splines.i3d",
                            road_excl_zone=road_excl_zone)

    if not args.skip_road_hedges:
        print("Building road hedge splines...")
        road_feats = load_geojson(INPUT_ROADS)
        if road_feats:
            n_road = sum(1 for f in road_feats
                         if f.get("properties", {}).get("fs25_type") in ROAD_HEDGE_TYPES)
            print(f"  {n_road} road/service roads → parallel hedge offsets "
                  f"(width={ROAD_HEDGE_DEFAULT_WIDTH_M}m, verge={ROAD_HEDGE_VERGE_M}m)")
            build_road_hedge_i3d(road_feats, out_dir / "sw_road_hedge_splines.i3d")

    if not args.skip_roads:
        print("Building road splines...")
        print("  NOTE: maps4fs already generated road splines in map/map/splines.i3d")
        print("        Our splines are for Lua texture-painting & terrain sinking only.")
        features = load_geojson(INPUT_ROADS)
        if features:
            build_road_i3d(features, out_dir / "sw_road_splines.i3d")

    if not args.skip_fields:
        print("Building field boundary splines...")
        # Prefer the newer OSM-based fields file, fall back to CROME
        features = load_geojson(INPUT_FIELDS_OSM)
        if not features:
            print("  fs25_fields_osm.geojson not found, falling back to CROME geojson")
            features = load_geojson(INPUT_FIELDS_CROME)
        if features:
            build_field_i3d(features, out_dir / "sw_field_splines.i3d")

    if not args.skip_water:
        print("Building waterway splines...")
        features = load_geojson(INPUT_WATER)
        # Only LineString water features (not ponds)
        features = [f for f in features
                    if f.get("geometry", {}).get("type") == "LineString"]
        if features:
            build_water_i3d(features, out_dir / "sw_water_splines.i3d")

    print("Building forest/woodland boundary splines...")
    features = load_geojson(INPUT_FOREST)
    if features:
        build_forest_i3d(features, out_dir / "sw_forest_splines.i3d")

    print()
    print("=" * 60)
    print("  Done. Import workflow in Giants Editor:")
    print()
    print("  FIELD HEDGES (sw_hedge_splines.i3d):")
    print("    1. Scene → Merge Scene → select sw_hedge_splines.i3d")
    print("    2. Select the 'hedges' group")
    print("    3. Run sw_batch_spline_placer.lua to place hedge objects")
    print("    4. Select placed objects group → run AlignChildsToTerrain")
    print()
    print("  ROAD HEDGES (sw_road_hedge_splines.i3d):")
    print("    1. Scene → Merge Scene → select sw_road_hedge_splines.i3d")
    print("    2. Two groups: road_hedges_left / road_hedges_right")
    print("    3. Run sw_batch_spline_placer.lua on each group")
    print("    4. Select placed objects group → run AlignChildsToTerrain")
    print("    NOTE: visually check and delete splines where no real hedge exists")
    print()
    print("  ROADS (sw_road_splines.i3d):")
    print("    1. Scene → Merge Scene → select sw_road_splines.i3d")
    print("    2. Select road splines → run RoadTracksHeightPaintFoliageBySpline")
    print("       (paints 3 texture layers + sinks road surface into terrain)")
    print("    3. Select dirt_tracks → run paintTerrainBySpline for track texture")
    print()
    print("  FIELDS (sw_field_splines.i3d):")
    print("    1. Scene → Merge Scene → select sw_field_splines.i3d")
    print("    2. Select 'field_boundaries' group")
    print("    3. Run SplineToFieldConverter to create field definitions")
    print()
    print("  FOREST (sw_forest_splines.i3d):")
    print("    1. Scene → Merge Scene → select sw_forest_splines.i3d")
    print("    2. Use woodland boundaries as paint guides (paintTerrainBySpline)")
    print("    3. Then run TreeReplicatorByPaint inside painted woodland areas")
    print()
    print("  ROADS — maps4fs already generated splines in map/map/splines.i3d")
    print("    sw_road_splines.i3d is for Lua texture/terrain scripts only.")
    print("    Delete road splines from scene after painting to avoid duplicates.")
    print()
    print("  ALL PLACED OBJECTS:")
    print("    → After any terrain height change, select placed object groups")
    print("      and run AlignChildsToTerrain to re-snap to terrain")
    print("=" * 60)


if __name__ == "__main__":
    main()
