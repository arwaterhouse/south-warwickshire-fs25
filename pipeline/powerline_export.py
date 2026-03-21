#!/usr/bin/env python3
"""
powerline_export.py — South Warwickshire FS25
==============================================

Reads power line ways from data/custom_osm.osm and generates an i3d file
containing NurbsCurve splines ready for import into Giants Editor 10.

Outputs:
  outputs/sw_powerline_splines.i3d   — import into GE via File → Import
  outputs/powerline_summary.txt      — stats + GE workflow instructions

Spline groups produced:
  powerlines_high    — power=line ways   (high-voltage, pylon spacing ~80 m)
  powerlines_minor   — power=minor_line  (distribution/telegraph, spacing ~50 m)

Coordinate system:
  FS25 uses a flat local system where:
    X = East  (+ve)
    Z = South (+ve)   (Z increases going south)
    Y = 0.0           (terrain-snapped in GE after import)
  Origin = map centre at (MAP_LAT, MAP_LON).

Usage:
  python pipeline/powerline_export.py
"""

import math
import sys
import xml.etree.ElementTree as ET
from collections import defaultdict
from pathlib import Path

# ── Map constants (authoritative — do not change) ─────────────────────────────
MAP_LAT  = 52.089387
MAP_LON  = -1.532290
MAP_SIZE = 4096.0          # metres
MAP_HALF = MAP_SIZE / 2.0  # ±2048 m

_cos_lat      = math.cos(math.radians(MAP_LAT))
M_PER_DEG_LAT = 111320.0
M_PER_DEG_LON = 111320.0 * _cos_lat

# ── Paths ──────────────────────────────────────────────────────────────────────
SCRIPT_DIR  = Path(__file__).resolve().parent
ROOT_DIR    = SCRIPT_DIR.parent
DATA_DIR    = ROOT_DIR / "data"
OUTPUTS_DIR = ROOT_DIR / "outputs"

OSM_FILE     = DATA_DIR    / "custom_osm.osm"
I3D_OUT      = OUTPUTS_DIR / "sw_powerline_splines.i3d"
SUMMARY_OUT  = OUTPUTS_DIR / "powerline_summary.txt"

# ── Spline limits ──────────────────────────────────────────────────────────────
MIN_SPLINE_LEN_M  = 20.0   # skip ways shorter than this
MAX_CVS_PER_SPLINE = 200   # split very long ways into segments

# ── Power way classification ───────────────────────────────────────────────────
HIGH_VOLTAGE_VALUES  = {"line"}          # power=line
MINOR_LINE_VALUES    = {"minor_line", "cable"}  # power=minor_line / cable


# ══════════════════════════════════════════════════════════════════════════════
# Coordinate helpers
# ══════════════════════════════════════════════════════════════════════════════

def latlon_to_fs25(lat: float, lon: float) -> tuple[float, float, float]:
    """Convert WGS84 (lat, lon) → FS25 world (x, 0.0, z)."""
    x = (lon - MAP_LON) * M_PER_DEG_LON
    z = -(lat - MAP_LAT) * M_PER_DEG_LAT
    return x, 0.0, z


def in_map_bounds(x: float, z: float, margin: float = 256.0) -> bool:
    limit = MAP_HALF + margin
    return -limit <= x <= limit and -limit <= z <= limit


def spline_length(cvs: list) -> float:
    total = 0.0
    for i in range(len(cvs) - 1):
        dx = cvs[i+1][0] - cvs[i][0]
        dz = cvs[i+1][2] - cvs[i][2]
        total += math.sqrt(dx*dx + dz*dz)
    return total


def chunk_cvs(cvs: list, max_size: int) -> list:
    """Split CV list into overlapping chunks."""
    if len(cvs) <= max_size:
        return [cvs]
    chunks = []
    i = 0
    while i < len(cvs):
        chunk = cvs[i:i + max_size]
        chunks.append(chunk)
        i += max_size - 1
    return [c for c in chunks if len(c) >= 2]


# ══════════════════════════════════════════════════════════════════════════════
# OSM parser
# ══════════════════════════════════════════════════════════════════════════════

def get_tag(element: ET.Element, key: str) -> str | None:
    for tag in element.findall("tag"):
        if tag.get("k") == key:
            return tag.get("v")
    return None


def parse_osm(path: Path) -> tuple[dict, list]:
    """
    Parse OSM file.

    Returns:
      node_coords : dict[node_id_str → (lat, lon)]
      power_ways  : list of dicts with keys:
                      'id', 'power', 'voltage', 'refs', 'name'
    """
    print(f"  Parsing {path.name} …")
    tree = ET.parse(path)
    root = tree.getroot()

    # Build node coordinate lookup
    node_coords: dict[str, tuple[float, float]] = {}
    for node in root.findall("node"):
        nid = node.get("id")
        lat = node.get("lat")
        lon = node.get("lon")
        if nid and lat and lon:
            node_coords[nid] = (float(lat), float(lon))

    print(f"    Loaded {len(node_coords):,} node positions")

    # Collect power ways
    power_ways = []
    for way in root.findall("way"):
        power_val = get_tag(way, "power")
        if not power_val:
            continue
        if power_val not in HIGH_VOLTAGE_VALUES | MINOR_LINE_VALUES:
            continue

        refs = [nd.get("ref") for nd in way.findall("nd") if nd.get("ref")]
        if len(refs) < 2:
            continue

        power_ways.append({
            "id":      way.get("id", "?"),
            "power":   power_val,
            "voltage": get_tag(way, "voltage") or "",
            "name":    get_tag(way, "name") or "",
            "refs":    refs,
        })

    print(f"    Found {len(power_ways)} power ways")
    return node_coords, power_ways


# ══════════════════════════════════════════════════════════════════════════════
# Spline builder
# ══════════════════════════════════════════════════════════════════════════════

def ways_to_splines(power_ways: list,
                    node_coords: dict) -> tuple[list, list]:
    """
    Convert power ways to FS25 spline definitions.

    Returns:
      high_splines  : list of {'name': str, 'cvs': [(x,y,z), …]}
      minor_splines : list of {'name': str, 'cvs': [(x,y,z), …]}
    """
    high_splines  = []
    minor_splines = []
    skipped_bounds = 0
    skipped_short  = 0
    skipped_nodes  = 0

    for way in power_ways:
        refs = way["refs"]
        cvs_raw = []
        missing = 0
        for ref in refs:
            if ref not in node_coords:
                missing += 1
                continue
            lat, lon = node_coords[ref]
            x, y, z = latlon_to_fs25(lat, lon)
            cvs_raw.append((x, y, z))

        if missing > 0:
            skipped_nodes += 1

        if len(cvs_raw) < 2:
            skipped_bounds += 1
            continue

        # Filter: keep only CVs within (extended) map bounds
        cvs = [cv for cv in cvs_raw if in_map_bounds(cv[0], cv[2])]
        if len(cvs) < 2:
            skipped_bounds += 1
            continue

        length = spline_length(cvs)
        if length < MIN_SPLINE_LEN_M:
            skipped_short += 1
            continue

        # Base name
        voltage = way["voltage"]
        label   = way["name"] or f"way_{way['id']}"
        if voltage:
            label = f"{label}_{voltage}V" if way["name"] else f"way_{way['id']}_{voltage}V"

        # Split if very long
        for ci, chunk in enumerate(chunk_cvs(cvs, MAX_CVS_PER_SPLINE)):
            if len(chunk) < 2:
                continue
            suffix = f"_{ci+1:02d}" if ci > 0 else ""
            spline = {"name": f"{label}{suffix}", "cvs": chunk}

            if way["power"] in HIGH_VOLTAGE_VALUES:
                high_splines.append(spline)
            else:
                minor_splines.append(spline)

    print(f"    Skipped (out of bounds): {skipped_bounds}")
    print(f"    Skipped (too short <{MIN_SPLINE_LEN_M}m): {skipped_short}")
    if skipped_nodes:
        print(f"    Ways with missing node refs: {skipped_nodes} (partial coords used)")

    return high_splines, minor_splines


# ══════════════════════════════════════════════════════════════════════════════
# i3d writer
# ══════════════════════════════════════════════════════════════════════════════

class I3DBuilder:
    """Minimal i3d builder matching the NurbsCurve format used by other pipeline scripts."""

    def __init__(self, name: str):
        self._node_id  = 0
        self._shape_id = 0

        self.root = ET.Element("i3D", {
            "name": name,
            "version": "1.6",
            "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
            "xsi:noNamespaceSchemaLocation":
                "http://i3d.giants.ch/schema/i3d-1.6.xsd",
        })
        ET.SubElement(self.root, "Files")
        self.shapes = ET.SubElement(self.root, "Shapes")
        self.scene  = ET.SubElement(self.root, "Scene")

    def _nid(self) -> str:
        self._node_id += 1
        return str(self._node_id)

    def _sid(self) -> str:
        self._shape_id += 1
        return str(self._shape_id)

    def add_group(self, group_name: str, splines: list) -> int:
        grp_id = self._nid()
        grp_el = ET.SubElement(self.scene, "TransformGroup", {
            "name": group_name,
            "nodeId": grp_id,
            "visibility": "true",
            "translation": "0 0 0",
            "rotation": "0 0 0",
            "scale": "1 1 1",
        })

        added = 0
        for sp in splines:
            cvs  = sp["cvs"]
            name = sp["name"]
            if len(cvs) < 2:
                continue

            sid = self._sid()
            nid = self._nid()

            ET.SubElement(grp_el, "Shape", {
                "name": name,
                "nodeId": nid,
                "shapeId": sid,
                "translation": "0 0 0",
            })

            curve_el = ET.SubElement(self.shapes, "NurbsCurve", {
                "name": name,
                "shapeId": sid,
                "degree": "3",
                "form": "open",
            })
            for x, y, z in cvs:
                ET.SubElement(curve_el, "cv", {"c": f"{x:.3f}, {y:.3f}, {z:.3f}"})

            added += 1

        return added

    def write(self, path: Path):
        ET.indent(self.root, space="  ")
        with open(path, "w", encoding="utf-8") as f:
            f.write('<?xml version="1.0" encoding="utf-8"?>\n')
            f.write(ET.tostring(self.root, encoding="unicode"))
        print(f"  → Written: {path.relative_to(ROOT_DIR)}")


# ══════════════════════════════════════════════════════════════════════════════
# Summary writer
# ══════════════════════════════════════════════════════════════════════════════

def write_summary(path: Path,
                  n_high: int,
                  n_minor: int,
                  high_splines: list,
                  minor_splines: list):
    total_len_high  = sum(spline_length(s["cvs"]) for s in high_splines)
    total_len_minor = sum(spline_length(s["cvs"]) for s in minor_splines)

    lines = [
        "South Warwickshire FS25 — Power Line Splines",
        "=" * 52,
        "",
        "Generated from: data/custom_osm.osm",
        f"Output file   : outputs/sw_powerline_splines.i3d",
        "",
        "Spline groups:",
        f"  powerlines_high  : {n_high:3d} splines  (~{total_len_high/1000:.1f} km total)",
        f"  powerlines_minor : {n_minor:3d} splines  (~{total_len_minor/1000:.1f} km total)",
        "",
        "=" * 52,
        "GIANTS EDITOR WORKFLOW",
        "=" * 52,
        "",
        "Prerequisites:",
        "  • GE 10 installed",
        "  • SplineToolkit.lua in GE scripts folder",
        "    (download: https://www.farming-simulator.com/mod.php?mod_id=354375)",
        "",
        "Step 1 — Import splines",
        "  File → Import → outputs/sw_powerline_splines.i3d",
        "  You'll see two groups added to the scene:",
        "    powerlines_high   — high-voltage routes (pylon spacing ~80 m)",
        "    powerlines_minor  — distribution/telegraph (pole spacing ~50 m)",
        "",
        "Step 2 — Snap splines to terrain",
        "  Select the powerlines group (or individual spline)",
        "  Scripts → SplineToolkit → Set Spline on Terrain",
        "  Height offset: 0",
        "  Click Execute",
        "",
        "Step 3 — Generate poles for minor lines",
        "  Select each spline in powerlines_minor",
        "  Scripts → SplineToolkit → Powerline Generator",
        "  Pole model: BulletBill wooden telegraph pole (FS25-patched)",
        "  Spacing: 50 m",
        "  Click Execute",
        "",
        "Step 4 — Generate pylons for high-voltage lines",
        "  Select each spline in powerlines_high",
        "  Same script, use pylon/lattice tower model",
        "  Spacing: 80 m",
        "  Click Execute",
        "",
        "Step 5 — Cleanup",
        "  • Delete any splines that don't match reality (check satellite view)",
        "  • Manually reposition any poles that land on roads or buildings",
        "  • Delete the trailing wire TransformGroup on each line end (GE artefact)",
        "",
        "Step 6 — Save",
        "  File → Save",
        "",
        "Map constants used:",
        f"  MAP_LAT  = {MAP_LAT}",
        f"  MAP_LON  = {MAP_LON}",
        f"  MAP_SIZE = {MAP_SIZE} m",
    ]

    path.write_text("\n".join(lines), encoding="utf-8")
    print(f"  → Written: {path.relative_to(ROOT_DIR)}")


# ══════════════════════════════════════════════════════════════════════════════
# Entry point
# ══════════════════════════════════════════════════════════════════════════════

def main():
    print("=" * 60)
    print("  powerline_export.py — South Warwickshire FS25")
    print("=" * 60)

    if not OSM_FILE.exists():
        print(f"\n  ERROR: {OSM_FILE} not found.")
        print("  Run check_power_osm.py first to diagnose the OSM file.")
        sys.exit(1)

    OUTPUTS_DIR.mkdir(parents=True, exist_ok=True)

    # Parse OSM
    node_coords, power_ways = parse_osm(OSM_FILE)

    if not power_ways:
        print("\n  No power ways found — OSM has no power line data.")
        print("  Run check_power_osm.py for instructions on adding power data.")
        sys.exit(1)

    # Count by type
    by_type: dict[str, int] = defaultdict(int)
    for w in power_ways:
        by_type[w["power"]] += 1
    print("\n  Power way breakdown:")
    for k, v in sorted(by_type.items()):
        print(f"    power={k}: {v}")

    # Build splines
    print("\n  Building FS25 splines …")
    high_splines, minor_splines = ways_to_splines(power_ways, node_coords)
    print(f"    powerlines_high  : {len(high_splines)}")
    print(f"    powerlines_minor : {len(minor_splines)}")

    if not high_splines and not minor_splines:
        print("\n  WARNING: 0 usable splines generated.")
        print("  All ways may be outside the 4096m map bounds or too short.")
        print("  Check that your OSM bbox overlaps the South Warwickshire map area.")

    # Write i3d
    print("\n  Writing i3d …")
    builder = I3DBuilder("sw_powerline_splines")
    n_high  = builder.add_group("powerlines_high",  high_splines)
    n_minor = builder.add_group("powerlines_minor", minor_splines)
    builder.write(I3D_OUT)

    # Write summary
    write_summary(SUMMARY_OUT, n_high, n_minor, high_splines, minor_splines)

    print(f"\n  Done — {n_high + n_minor} splines written.")
    print("  Next: open GE and follow outputs/powerline_summary.txt")
    print("=" * 60)


if __name__ == "__main__":
    main()
