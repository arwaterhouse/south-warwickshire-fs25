#!/usr/bin/env python3
"""
Generate FS25 fields.xml from CROME 2024 crop distribution data.

Uses CROME data for CROP TYPE DISTRIBUTION ONLY.
CROME hex polygon shapes are NOT used as field boundaries —
field boundaries are defined in the map i3d.

South Warwickshire, UK — 4 km² map

Usage:
    python3 generate_fields_xml.py \\
        --crome  ../../data/crome_south_warwickshire_fs25.geojson \\
        --output ../../map/map/config/fields.xml \\
        --fields 130

Outputs:
    fields.xml  — FS25-ready field initial states
    fields_distribution.json — crop distribution summary (for reference)
"""

import json
import math
import random
import argparse
from pathlib import Path
from collections import defaultdict

# ── Reproducible results ──────────────────────────────────────────────────────
RANDOM_SEED = 42

# ── CROME lucode → FS25 fruit type ───────────────────────────────────────────
# Fruit names must match FS25 uppercase fruit type identifiers exactly.
LUCODE_MAP = {
    # Arable cereals
    "AC01": {"fruit": "WHEAT",       "category": "arable"},
    "AC03": {"fruit": "BARLEY",      "category": "arable"},
    "AC17": {"fruit": "BARLEY",      "category": "arable"},
    "AC19": {"fruit": "OAT",         "category": "arable"},
    "AC63": {"fruit": "WHEAT",       "category": "arable"},   # other cereals
    "AC65": {"fruit": "WHEAT",       "category": "arable"},   # other arable

    # Oilseed
    "AC06": {"fruit": "OILSEEDRAPE", "category": "arable"},

    # Maize
    "AC32": {"fruit": "MAIZE",       "category": "arable"},

    # Root crops
    "AC37": {"fruit": "SUGARBEET",   "category": "root"},
    "AC38": {"fruit": "POTATO",      "category": "root"},

    # Vegetables
    "AC67": {"fruit": "CARROT",      "category": "arable"},

    # Legumes (rare in SW Warks but mapped)
    "AC44": {"fruit": "SOYBEAN",     "category": "arable"},

    # Fallow / bare — included as uncultivated fields, no fruit type
    "AC66": {"fruit": None,          "category": "fallow"},

    # Grassland — all map to GRASS
    "AC68": {"fruit": "GRASS",       "category": "grassland"},
    "LG03": {"fruit": "GRASS",       "category": "grassland"},
    "LG07": {"fruit": "GRASS",       "category": "grassland"},
    "LG14": {"fruit": "GRASS",       "category": "grassland"},
    "LG20": {"fruit": "GRASS",       "category": "grassland"},
    "LG21": {"fruit": "GRASS",       "category": "grassland"},
    "PG01": {"fruit": "GRASS",       "category": "grassland"},
    "TG01": {"fruit": "GRASS",       "category": "grassland"},

    # Non-playable — excluded
    "FA01": None,   # farmyard
    "NA01": None,   # woodland
    "WO12": None,   # woodland
}

# Categories that become in-game fields
PLAYABLE_CATEGORIES = {"arable", "root", "grassland", "fallow"}

# ── UK autumn game-start states (late August / early September) ───────────────
# Weighted list of (growthState, groundType) pairs per fruit type.
# growthState: GERMINATING | 1-6 | HARVESTED
# groundType:  CULTIVATED | PLOWED | HARVEST_READY | DEFAULT
#
# Rationale:
#   Game start: AUGUST (UK)
#
#   WHEAT      — harvest complete by Aug. Stubble/bare ground; NO re-drilling
#                until September. No germinating/early growth in August.
#   BARLEY     — spring barley harvest July-Aug. Mostly harvested or late
#                standing crop. NOT at stage 1 (planted March, way past that).
#   OAT        — same as barley, harvested by Aug.
#   OILSEEDRAPE— winter OSR harvested July. Some farmers drill new crop early
#                Aug so GERMINATING is valid. Majority still bare post-harvest.
#   MAIZE      — harvested Oct/Nov, so fully standing in Aug (stage 5-6).
#   SUGARBEET  — harvested Oct-Feb, still in ground (stage 5-6).
#   POTATO     — early varieties harvested Aug, main crop Sept-Oct.
#   CARROT     — main crop harvest Sept-Nov, still growing in Aug (stage 4-5).
#   GRASS      — cut multiple times by Aug; mix of regrowth and recently cut.
#   FALLOW     — ploughed or cultivated bare ground.

CROP_STATES = {
    "WHEAT": [
        # All harvested — no re-drilling until September in UK
        ("HARVESTED",   "HARVEST_READY", 45),   # stubble still on ground
        ("HARVESTED",   "PLOWED",        40),   # ploughed post-harvest
        ("HARVESTED",   "CULTIVATED",    15),   # cultivated, preparing seedbed
    ],
    "BARLEY": [
        # Mostly harvested; a few late crops still standing
        ("HARVESTED",   "HARVEST_READY", 40),
        ("HARVESTED",   "PLOWED",        35),
        ("6",           "CULTIVATED",    15),   # late-ripening crop still up
        ("HARVESTED",   "CULTIVATED",    10),
    ],
    "OAT": [
        ("HARVESTED",   "HARVEST_READY", 40),
        ("HARVESTED",   "PLOWED",        35),
        ("6",           "CULTIVATED",    15),
        ("HARVESTED",   "CULTIVATED",    10),
    ],
    "OILSEEDRAPE": [
        # Winter OSR harvested July; some early-drilling new crop in Aug
        ("HARVESTED",   "HARVEST_READY", 30),
        ("HARVESTED",   "PLOWED",        30),
        ("GERMINATING", "CULTIVATED",    25),   # early Aug drillers
        ("1",           "CULTIVATED",    15),
    ],
    "MAIZE": [
        # Standing crop, not harvested until Oct-Nov
        ("6",           "CULTIVATED",    40),
        ("5",           "CULTIVATED",    45),
        ("4",           "CULTIVATED",    15),
    ],
    "SUGARBEET": [
        # Still in ground, harvested Oct-Feb
        ("6",           "CULTIVATED",    40),
        ("5",           "CULTIVATED",    40),
        ("4",           "CULTIVATED",    20),
    ],
    "POTATO": [
        # Early varieties harvested by Aug; main crop still growing
        ("HARVESTED",   "HARVEST_READY", 40),
        ("6",           "CULTIVATED",    30),
        ("5",           "CULTIVATED",    30),
    ],
    "CARROT": [
        # Main harvest Sept-Nov; fully grown but still in ground
        ("5",           "CULTIVATED",    45),
        ("6",           "CULTIVATED",    35),
        ("4",           "CULTIVATED",    20),
    ],
    "SOYBEAN": [
        ("5",           "CULTIVATED",    45),
        ("6",           "CULTIVATED",    35),
        ("4",           "CULTIVATED",    20),
    ],
    "GRASS": [
        # Cut 3+ times by August; mix of active regrowth and recently mown
        ("HARVESTED",   "DEFAULT",       30),   # just cut / silage taken
        ("4",           "DEFAULT",       30),   # regrowing
        ("5",           "DEFAULT",       25),   # good regrowth
        ("3",           "DEFAULT",       15),   # early regrowth after cut
    ],
    None: [  # fallow / bare
        (None,          "PLOWED",        55),
        (None,          "CULTIVATED",    45),
    ],
}


# ── South Warwickshire real-world arable distribution ────────────────────────
# Raw CROME area data is skewed by non-farmable land (road verges, village
# greens, rough pasture) and reports 57% grass. Real game fields in South
# Warwickshire around Shipston-on-Stour are predominantly arable.
# Source: AHDB Arable/combinable crop statistics for Warwickshire + local
# knowledge of the area. Percentages are of PLAYABLE FIELD count.
SW_DISTRIBUTION = {
    "WHEAT":       85,   # 35% — dominant crop, Cotswold limestone soils suit it
    "BARLEY":      53,   # 22% — both spring and winter barley widespread
    "OILSEEDRAPE": 36,   # 15% — yellow fields very visible in SW Warwickshire
    "OAT":         17,   #  7% — reasonable presence in rotation
    "GRASS":       29,   # 12% — some livestock/dairy farms, rough pasture
    "MAIZE":        5,   #  2% — growing in area for AD/dairy feed
    None:          12,   #  5% — fallow/set-aside/bare cultivated ground
    "SUGARBEET":    2,   #  1%
    "POTATO":       2,   #  1%
    "CARROT":       1,   # <1%
    "SOYBEAN":      1,   # <1%
}   # total = 243


def weighted_choice(rng, options):
    """Pick from [(value, weight)] or [(v1, v2, weight)] list."""
    total = sum(o[-1] for o in options)
    r = rng.uniform(0, total)
    cumulative = 0
    for option in options:
        cumulative += option[-1]
        if r <= cumulative:
            return option[:-1]  # strip weight
    return options[-1][:-1]


def compute_distribution(geojson_path: str, use_sw_override: bool = True) -> tuple:
    """
    Return crop distribution as {fruit: count} and total field count.

    By default uses the SW_DISTRIBUTION override which reflects real South
    Warwickshire arable farming patterns. Raw CROME area data is available
    with --use-crome-distribution but is skewed by non-farmable grassland.
    """
    if use_sw_override:
        total = sum(SW_DISTRIBUTION.values())
        print("  Using South Warwickshire arable distribution (not raw CROME areas)")
        print(f"  Total fields in distribution: {total}")
        print()
        print("  Crop distribution:")
        for fruit, count in sorted(SW_DISTRIBUTION.items(), key=lambda x: -x[1]):
            label = fruit if fruit else "FALLOW (bare)"
            pct = count / total * 100
            print(f"    {label:<16} {count:>4} fields  ({pct:.1f}%)")
        # Return field counts as pseudo-areas (count = area weight)
        return dict(SW_DISTRIBUTION), float(total)

    # Raw CROME area-weighted path
    with open(geojson_path) as f:
        data = json.load(f)

    area_by_fruit = defaultdict(float)
    skipped = 0

    for feat in data["features"]:
        props = feat["properties"]
        lucode = props.get("lucode", "")
        area_ha = float(props.get("area_ha", 0))
        mapping = LUCODE_MAP.get(lucode)
        if mapping is None:
            skipped += 1
            continue
        category = mapping["category"]
        if category not in PLAYABLE_CATEGORIES:
            skipped += 1
            continue
        area_by_fruit[mapping["fruit"]] += area_ha

    total_ha = sum(area_by_fruit.values())
    print(f"  CROME parcels processed: {len(data['features']):,}")
    print(f"  Non-playable skipped:    {skipped:,}")
    print(f"  Playable area:           {total_ha:.1f} ha")
    print()
    print("  Crop distribution by area (raw CROME):")
    for fruit, ha in sorted(area_by_fruit.items(), key=lambda x: -x[1]):
        label = fruit if fruit else "FALLOW (bare)"
        print(f"    {label:<16} {ha:>8.1f} ha  ({ha/total_ha*100:.1f}%)")

    return dict(area_by_fruit), total_ha


def build_field_list(distribution: dict, total_ha: float, num_fields: int, rng: random.Random) -> list:
    """
    Build a list of field crop assignments proportional to CROME distribution.
    Returns list of {fruit, growthState, groundType, angle, weedState, spray} dicts.
    """
    # Convert area distribution to field counts
    fruit_types = list(distribution.keys())
    fruit_areas = [distribution[f] for f in fruit_types]

    # How many fields per crop type (proportional, at least 1 per type)
    counts = []
    for area in fruit_areas:
        count = max(1, round((area / total_ha) * num_fields))
        counts.append(count)

    # Scale to exactly num_fields
    total_assigned = sum(counts)
    if total_assigned != num_fields:
        # Adjust the largest group
        largest_idx = counts.index(max(counts))
        counts[largest_idx] += num_fields - total_assigned

    # Build flat field list
    fields = []
    for fruit, count in zip(fruit_types, counts):
        states = CROP_STATES.get(fruit, CROP_STATES[None])
        for _ in range(count):
            growth, ground = weighted_choice(rng, states)
            fields.append({
                "fruit":       fruit,
                "growthState": growth,
                "groundType":  ground,
                "angle":       rng.randint(0, 359),
                # ~15% of fields have some weed pressure, 5% heavy
                "weedState":   rng.choices([0, 1, 2], weights=[85, 10, 5])[0],
                # Most arable fields have been fertilized; grassland less so
                "sprayed":     (fruit not in (None, "GRASS")) and rng.random() < 0.55,
            })

    rng.shuffle(fields)
    return fields


def render_xml(fields: list) -> str:
    """Render fields list to FS25 fields.xml content."""
    lines = [
        '<?xml version="1.0" encoding="utf-8" standalone="no" ?>',
        '<map xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"',
        '     xsi:noNamespaceSchemaLocation="../../../../shared/xml/schema/fields.xsd">',
        '    <!-- Generated from CROME 2024 data — South Warwickshire -->',
        '    <!-- Crop distribution reflects real DEFRA land-use survey data -->',
        '    <!-- CROME hex shapes NOT used — only statistical distribution -->',
        '    <fields>',
    ]

    for field_id, f in enumerate(fields, start=1):
        weed = f["weedState"]
        lines.append(f'        <field fieldId="{field_id}" weedState="{weed}">')

        # Fruit element — omit entirely for bare/fallow fields
        if f["fruit"] is not None:
            lines.append(f'            <fruit type="{f["fruit"]}" growthState="{f["growthState"]}"/>')

        lines.append(f'            <ground type="{f["groundType"]}" angle="{f["angle"]}" />')

        spray = 'FERTILIZER" level="1' if f["sprayed"] else 'NONE" level="0'
        lines.append(f'            <spray type="{spray}" />')

        lines.append('        </field>')

    lines += ['    </fields>', '</map>', '']
    return '\n'.join(lines)


def save_distribution_summary(distribution: dict, total_ha: float, num_fields: int, output_path: str):
    """Save JSON summary of crop distribution for reference."""
    summary = {
        "source": "CROME 2024 — DEFRA land use survey",
        "area": "South Warwickshire 4km x 4km",
        "total_playable_ha": round(total_ha, 1),
        "target_fields": num_fields,
        "distribution": {}
    }
    for fruit, ha in sorted(distribution.items(), key=lambda x: -x[1]):
        label = fruit if fruit else "FALLOW"
        pct = round(ha / total_ha * 100, 1) if total_ha else 0
        count = max(1, round((ha / total_ha) * num_fields))
        summary["distribution"][label] = {
            "area_ha": round(ha, 1),
            "percent": pct,
            "approx_fields": count,
        }
    with open(output_path, "w") as f:
        json.dump(summary, f, indent=2)
    print(f"  Distribution summary: {output_path}")


def main():
    parser = argparse.ArgumentParser(
        description="Generate FS25 fields.xml from CROME crop distribution"
    )
    parser.add_argument(
        "--crome",
        default="../../data/crome_south_warwickshire_fs25.geojson",
        help="Path to CROME GeoJSON file",
    )
    parser.add_argument(
        "--output",
        default="../../map/map/config/fields.xml",
        help="Output fields.xml path",
    )
    parser.add_argument(
        "--fields",
        type=int,
        default=243,
        help="Target number of in-game fields — must match field count in map i3d (default: 243)",
    )
    parser.add_argument(
        "--use-crome-distribution",
        action="store_true",
        default=False,
        help="Use raw CROME area-weighted distribution instead of SW arable override",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=RANDOM_SEED,
        help="Random seed for reproducibility",
    )
    args = parser.parse_args()

    rng = random.Random(args.seed)

    print(f"=== FS25 Field XML Generator — South Warwickshire ===\n")
    use_crome = args.use_crome_distribution
    if use_crome:
        print(f"Loading CROME data: {args.crome}")
    distribution, total_ha = compute_distribution(args.crome, use_sw_override=not use_crome)

    print(f"\nGenerating {args.fields} fields...")
    fields = build_field_list(distribution, total_ha, args.fields, rng)

    xml = render_xml(fields)

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(xml)
    print(f"  Written: {output_path}  ({len(fields)} fields)")

    # Save distribution summary alongside the XML
    summary_path = output_path.parent / "fields_distribution.json"
    save_distribution_summary(distribution, total_ha, args.fields, str(summary_path))

    print("\nDone.")


if __name__ == "__main__":
    main()
