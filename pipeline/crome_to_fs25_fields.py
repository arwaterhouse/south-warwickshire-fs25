#!/usr/bin/env python3
"""
CROME 2024 → FS25 Field Type Mapper
South Warwickshire Map - Generated from DEFRA CROME data

Maps DEFRA CROME land use codes to Farming Simulator 25 crop/field types.
Input: GeoJSON (WGS84) with lucode field
Output: XML snippet / field data for maps4fs or Giants Editor

Usage:
    python3 crome_to_fs25_fields.py --input crome_south_warwickshire_fs25.geojson
"""

import json
import argparse
import sys
from pathlib import Path

# CROME lucode → FS25 fruitTypeIndex mapping
# Based on FS25 default fruit types (index from fruits.xml)
LUCODE_TO_FS25 = {
    # Arable crops
    "AC01": {"fs25_fruit": "wheat",         "category": "arable",    "priority": 1},
    "AC03": {"fs25_fruit": "barley",         "category": "arable",    "priority": 1},
    "AC06": {"fs25_fruit": "oilseedRape",   "category": "arable",    "priority": 1},
    "AC17": {"fs25_fruit": "barley",         "category": "arable",    "priority": 1},
    "AC19": {"fs25_fruit": "oat",            "category": "arable",    "priority": 1},
    "AC32": {"fs25_fruit": "maize",          "category": "arable",    "priority": 1},
    "AC37": {"fs25_fruit": "sugarBeet",      "category": "root",      "priority": 1},
    "AC38": {"fs25_fruit": "potato",         "category": "root",      "priority": 1},
    "AC44": {"fs25_fruit": "soybean",        "category": "arable",    "priority": 2},
    "AC63": {"fs25_fruit": "wheat",          "category": "arable",    "priority": 2},  # other cereals → wheat
    "AC65": {"fs25_fruit": "wheat",          "category": "arable",    "priority": 3},  # other arable
    "AC66": {"fs25_fruit": None,             "category": "fallow",    "priority": 4},  # fallow
    "AC67": {"fs25_fruit": "carrot",         "category": "vegetables","priority": 2},
    "AC68": {"fs25_fruit": "grass",          "category": "grassland", "priority": 3},
    
    # Grassland types
    "FA01": {"fs25_fruit": None,             "category": "farmyard",  "priority": 5},
    "LG03": {"fs25_fruit": "grass",          "category": "grassland", "priority": 2},
    "LG07": {"fs25_fruit": "grass",          "category": "grassland", "priority": 2},
    "LG14": {"fs25_fruit": "grass",          "category": "grassland", "priority": 3},
    "LG20": {"fs25_fruit": "grass",          "category": "grassland", "priority": 1},
    "LG21": {"fs25_fruit": "grass",          "category": "grassland", "priority": 2},
    "NA01": {"fs25_fruit": None,             "category": "woodland",  "priority": 5},
    "PG01": {"fs25_fruit": "grass",          "category": "grassland", "priority": 1},
    "TG01": {"fs25_fruit": "grass",          "category": "grassland", "priority": 2},
    "WO12": {"fs25_fruit": None,             "category": "woodland",  "priority": 5},
}

# Fields suitable for player-owned farms in FS25
PLAYABLE_CATEGORIES = {"arable", "root", "vegetables", "grassland", "fallow"}

# Minimum field size for FS25 (smaller parcels merged or skipped)
MIN_FIELD_AREA_HA = 0.2
IDEAL_FIELD_AREA_HA = 2.0   # typical FS25 field
MAX_FIELD_AREA_HA = 20.0    # very large fields split in Giants Editor


def load_geojson(path: str) -> dict:
    with open(path) as f:
        return json.load(f)


def classify_features(geojson: dict) -> dict:
    """Classify each CROME parcel into FS25 field data."""
    results = {
        "playable_fields": [],
        "grassland": [],
        "woodland": [],
        "farmyard": [],
        "skipped_small": [],
        "stats": {}
    }
    
    total_playable_ha = 0
    category_counts = {}
    
    for feat in geojson["features"]:
        props = feat["properties"]
        lucode = props.get("lucode", "")
        area_ha = props.get("area_ha", 0)
        
        mapping = LUCODE_TO_FS25.get(lucode, {
            "fs25_fruit": "wheat", "category": "arable", "priority": 3
        })
        
        cat = mapping["category"]
        category_counts[cat] = category_counts.get(cat, 0) + 1
        
        field_data = {
            "lucode": lucode,
            "crop_name": props.get("crop_name", lucode),
            "fs25_fruit": mapping["fs25_fruit"],
            "category": cat,
            "area_ha": round(area_ha, 3),
            "priority": mapping["priority"],
            "geometry": feat["geometry"]
        }
        
        if area_ha < MIN_FIELD_AREA_HA:
            results["skipped_small"].append(field_data)
        elif cat == "woodland":
            results["woodland"].append(field_data)
        elif cat == "farmyard":
            results["farmyard"].append(field_data)
        elif cat == "grassland":
            results["grassland"].append(field_data)
        elif cat in PLAYABLE_CATEGORIES:
            results["playable_fields"].append(field_data)
            total_playable_ha += area_ha
    
    results["stats"] = {
        "total_features": len(geojson["features"]),
        "playable_fields": len(results["playable_fields"]),
        "grassland_parcels": len(results["grassland"]),
        "woodland_parcels": len(results["woodland"]),
        "farmyard_parcels": len(results["farmyard"]),
        "skipped_small": len(results["skipped_small"]),
        "total_playable_ha": round(total_playable_ha, 1),
        "category_breakdown": category_counts
    }
    
    return results


def export_field_summary_csv(results: dict, output_path: str):
    """Export playable fields to CSV for review."""
    import csv
    fields = results["playable_fields"] + results["grassland"]
    fields.sort(key=lambda x: (-x["area_ha"], x["priority"]))
    
    with open(output_path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["field_id", "lucode", "crop_name", "fs25_fruit", "category", "area_ha", "priority"])
        for i, field in enumerate(fields, 1):
            writer.writerow([
                f"field_{i:04d}",
                field["lucode"],
                field["crop_name"],
                field["fs25_fruit"] or "N/A",
                field["category"],
                field["area_ha"],
                field["priority"]
            ])
    print(f"  CSV: {output_path} ({len(fields)} fields)")


def print_summary(stats: dict):
    print("\n=== FS25 Field Classification Summary ===")
    print(f"  Total CROME parcels:    {stats['total_features']:,}")
    print(f"  Playable arable fields: {stats['playable_fields']:,}")
    print(f"  Grassland parcels:      {stats['grassland_parcels']:,}")
    print(f"  Woodland areas:         {stats['woodland_parcels']:,}")
    print(f"  Farmyard areas:         {stats['farmyard_parcels']:,}")
    print(f"  Skipped (<{MIN_FIELD_AREA_HA}ha):      {stats['skipped_small']:,}")
    print(f"  Total playable area:    {stats['total_playable_ha']:,} ha")
    print("\n  Category breakdown:")
    for cat, count in sorted(stats['category_breakdown'].items(), key=lambda x: -x[1]):
        print(f"    {cat:<15} {count:>5} parcels")


def main():
    parser = argparse.ArgumentParser(description="CROME 2024 to FS25 field mapper")
    parser.add_argument("--input", default="crome_south_warwickshire_fs25.geojson",
                        help="Input GeoJSON file")
    parser.add_argument("--output-csv", default="fs25_fields.csv",
                        help="Output CSV of classified fields")
    args = parser.parse_args()
    
    print(f"Loading {args.input}...")
    geojson = load_geojson(args.input)
    print(f"  {len(geojson['features']):,} features loaded")
    
    print("Classifying parcels...")
    results = classify_features(geojson)
    
    print_summary(results["stats"])
    export_field_summary_csv(results, args.output_csv)
    
    print("\nDone.")


if __name__ == "__main__":
    main()
