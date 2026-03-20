#!/usr/bin/env python3
"""
check_power_osm.py — South Warwickshire FS25
=============================================

Diagnose whether data/custom_osm.osm contains power infrastructure tags
(power lines, poles, towers) needed by powerline_export.py.

Usage:
  python pipeline/check_power_osm.py
"""

import xml.etree.ElementTree as ET
from collections import Counter
from pathlib import Path

# ── Paths ──────────────────────────────────────────────────────────────────────
SCRIPT_DIR = Path(__file__).resolve().parent
ROOT_DIR   = SCRIPT_DIR.parent
OSM_FILE   = ROOT_DIR / "data" / "custom_osm.osm"

# ── Power tag values we care about ────────────────────────────────────────────
POWER_NODE_VALUES = {"pole", "tower", "portal", "terminal", "generator",
                     "substation", "transformer"}
POWER_WAY_VALUES  = {"line", "minor_line", "cable"}

# ── Overpass query for the South Warwickshire bounding box ────────────────────
# bbox = (min_lat, min_lon, max_lat, max_lon)
MAP_BBOX = (52.071, -1.562, 52.108, -1.502)

OVERPASS_QUERY = f"""\
[out:xml][timeout:90];
(
  way["power"="line"]({MAP_BBOX[0]},{MAP_BBOX[1]},{MAP_BBOX[2]},{MAP_BBOX[3]});
  way["power"="minor_line"]({MAP_BBOX[0]},{MAP_BBOX[1]},{MAP_BBOX[2]},{MAP_BBOX[3]});
  node["power"="pole"]({MAP_BBOX[0]},{MAP_BBOX[1]},{MAP_BBOX[2]},{MAP_BBOX[3]});
  node["power"="tower"]({MAP_BBOX[0]},{MAP_BBOX[1]},{MAP_BBOX[2]},{MAP_BBOX[3]});
);
out body;
>;
out skel qt;"""


def parse_osm(path: Path):
    """Parse OSM file and return (nodes, ways) as lists of Element."""
    tree = ET.parse(path)
    root = tree.getroot()
    nodes = root.findall("node")
    ways  = root.findall("way")
    return nodes, ways


def get_tag(element, key: str) -> str | None:
    for tag in element.findall("tag"):
        if tag.get("k") == key:
            return tag.get("v")
    return None


def audit_power(nodes, ways):
    node_power: Counter = Counter()
    way_power:  Counter = Counter()

    for node in nodes:
        v = get_tag(node, "power")
        if v:
            node_power[v] += 1

    for way in ways:
        v = get_tag(way, "power")
        if v:
            way_power[v] += 1

    return node_power, way_power


def main():
    print("=" * 60)
    print("  Power OSM checker — South Warwickshire FS25")
    print("=" * 60)

    if not OSM_FILE.exists():
        print(f"\n  ERROR: OSM file not found: {OSM_FILE}")
        print("  Expected location: data/custom_osm.osm")
        return

    print(f"\n  Parsing: {OSM_FILE.relative_to(ROOT_DIR)}")
    nodes, ways = parse_osm(OSM_FILE)
    print(f"  Total nodes: {len(nodes):,}   Total ways: {len(ways):,}")

    node_power, way_power = audit_power(nodes, ways)

    # ── Node power tags ────────────────────────────────────────────────────────
    print("\n  power= tags on NODES:")
    if node_power:
        for v, n in sorted(node_power.items(), key=lambda x: -x[1]):
            marker = "✓" if v in POWER_NODE_VALUES else "?"
            print(f"    {marker}  power={v}: {n}")
    else:
        print("    (none found)")

    # ── Way power tags ─────────────────────────────────────────────────────────
    print("\n  power= tags on WAYS:")
    if way_power:
        for v, n in sorted(way_power.items(), key=lambda x: -x[1]):
            marker = "✓" if v in POWER_WAY_VALUES else "?"
            print(f"    {marker}  power={v}: {n}")
    else:
        print("    (none found)")

    # ── Verdict ────────────────────────────────────────────────────────────────
    has_ways   = any(v in POWER_WAY_VALUES  for v in way_power)
    has_struct = any(v in POWER_NODE_VALUES for v in node_power)

    print("\n" + "─" * 60)
    if has_ways:
        print("  RESULT: power ways found — OSM is ready for powerline_export.py")
        print(f"    power line ways : {sum(way_power[v] for v in POWER_WAY_VALUES if v in way_power)}")
        print(f"    pole/tower nodes: {sum(node_power[v] for v in POWER_NODE_VALUES if v in node_power)}")
        print("\n  Next step:")
        print("    python pipeline/powerline_export.py")
    else:
        print("  RESULT: NO power ways found in OSM — splines cannot be generated.")
        print("\n  To fix, download power data from Overpass Turbo:")
        print("    1. Go to: https://overpass-turbo.eu/")
        print("    2. Paste this query:\n")
        print(OVERPASS_QUERY)
        print()
        print("    3. Click Export → Download as OSM")
        print("    4. Open the downloaded file and copy all <node> and <way> elements")
        print("    5. Paste them into data/custom_osm.osm just before </osm>")
        print("    6. Re-run this script to confirm")

        if has_struct:
            print(f"\n  Note: pole/tower nodes ARE present ({sum(node_power.values())} total)")
            print("  but no line/minor_line ways were found — poles without routes.")

    print("─" * 60)


if __name__ == "__main__":
    main()
