#!/usr/bin/env python3
"""
scan_my_buildings.py — South Warwickshire FS25 map
===================================================
Run this on your PC ONCE before generating the map.

It scans your extracted mod folders for building .i3d files,
reads their real dimensions from modDesc.xml / placeable XML files,
and writes fs25_buildings_schema_uk.json with correct paths and sizes.

Usage:
    python3 scan_my_buildings.py

Put this script in the same folder as your other map config files.
It will ask you where your mods are extracted to.
"""

import os, sys, json, re, glob
import xml.etree.ElementTree as ET

# ── Where are your extracted mods? ────────────────────────────────────────────
# Edit these paths to point to your extracted mod folders.
# These are the mods you listed — update the paths to match where YOU extracted them.
# Each entry is: ("human label", "path/to/extracted/mod/root")
MOD_FOLDERS = [
    # Update these paths ↓↓↓
    ("British Farm Pack",        r"C:\Users\YOU\Desktop\mods\FS25_BritishFarmPack"),
    ("LivinOnAPlayer MachineShed", r"C:\Users\YOU\Desktop\mods\FS25_UK_MachineShed_3Bay"),
    ("LivinOnAPlayer ShedWorkshop", r"C:\Users\YOU\Desktop\mods\FS25_UK_Shed"),
    ("British Grain Sheds",      r"C:\Users\YOU\Desktop\mods\FS25_BritishGrainSheds"),
    ("Farmer_Andy BF Buildings", r"C:\Users\YOU\Desktop\mods\FS25_BFBritishBuildings"),
    ("UK Stone Buildings",       r"C:\Users\YOU\Desktop\mods\FS25_UKStoneBuildings"),
]

# ── Category hints — map mod names / file name fragments → category ────────────
# Edit or extend this if you know a specific building belongs to a category
CATEGORY_HINTS = {
    "shed":         "farmyard",
    "barn":         "farmyard",
    "grain":        "farmyard",
    "storage":      "farmyard",
    "silo":         "farmyard",
    "workshop":     "farmyard",
    "machinery":    "farmyard",
    "dutch":        "farmyard",
    "house":        "residential",
    "cottage":      "residential",
    "farmhouse":    "residential",
    "bungalow":     "residential",
    "terrace":      "residential",
    "church":       "religious",
    "chapel":       "religious",
    "office":       "commercial",
    "shop":         "retail",
}

def guess_category(name: str) -> str:
    n = name.lower()
    for kw, cat in CATEGORY_HINTS.items():
        if kw in n:
            return cat
    return "farmyard"  # default for unknown British farm buildings

def parse_dimensions_from_xml(xml_path: str) -> tuple[float, float] | None:
    """Try to extract width/depth from a placeable or storeItem XML."""
    try:
        tree = ET.parse(xml_path)
        root = tree.getroot()
        # Giants Editor stores size in various places — try the most common ones
        # 1. <placeable> → <storageExtension> sizeX / sizeZ
        for elem in root.iter():
            for attr_pair in [("sizeX", "sizeZ"), ("width", "depth"), ("width", "length"),
                               ("sizeWidth", "sizeDepth"), ("sizeWidth", "sizeLength")]:
                w_attr, d_attr = attr_pair
                if elem.get(w_attr) and elem.get(d_attr):
                    try:
                        return float(elem.get(w_attr)), float(elem.get(d_attr))
                    except (ValueError, TypeError):
                        pass
        # 2. look for <node> with scale or bounding box attrs
        # Not always present, skip if not found
    except Exception:
        pass
    return None

def parse_moddesc(mod_folder: str) -> list[dict]:
    """Parse modDesc.xml to find all placeable items and their XML files."""
    moddesc_path = os.path.join(mod_folder, "modDesc.xml")
    if not os.path.isfile(moddesc_path):
        return []

    items = []
    try:
        tree = ET.parse(moddesc_path)
        root = tree.getroot()

        # storeItems → item → filename  (the placeable XML relative to mod root)
        for item in root.iter("item"):
            filename = item.get("filename", "")
            if not filename:
                continue

            xml_path = os.path.normpath(os.path.join(mod_folder, filename))
            if not os.path.isfile(xml_path):
                continue

            # Now find the i3d file referenced inside this placeable XML
            try:
                pxml = ET.parse(xml_path)
                proot = pxml.getroot()

                i3d_path = None
                # <placeable> → <filename> OR embedded <node> filename attr
                for fname_elem in proot.iter("filename"):
                    fn = fname_elem.get("value") or fname_elem.text or ""
                    if fn.lower().endswith(".i3d"):
                        i3d_path = fn
                        break

                # fallback: first .i3d file mentioned anywhere in the XML
                if not i3d_path:
                    for elem in proot.iter():
                        for attr_val in elem.attrib.values():
                            if isinstance(attr_val, str) and attr_val.lower().endswith(".i3d"):
                                i3d_path = attr_val
                                break
                        if i3d_path:
                            break

                # Try to get dimensions
                dims = parse_dimensions_from_xml(xml_path)

                items.append({
                    "placeable_xml": xml_path,
                    "i3d_relative": i3d_path,
                    "dimensions": dims,
                    "name": os.path.splitext(os.path.basename(xml_path))[0],
                })
            except Exception:
                continue
    except Exception as e:
        print(f"  [WARN] Could not parse modDesc.xml in {mod_folder}: {e}")

    return items

def find_i3d_files(mod_folder: str) -> list[str]:
    """Fallback: find all .i3d files in the mod folder tree."""
    results = []
    for root_dir, dirs, files in os.walk(mod_folder):
        # Skip texture / shader subdirs — only want placeable i3d
        dirs[:] = [d for d in dirs if d.lower() not in
                   ("textures", "shaders", "materials", "sounds", "effects", "scripts")]
        for f in files:
            if f.lower().endswith(".i3d"):
                results.append(os.path.join(root_dir, f))
    return results

def extract_size_from_i3d(i3d_path: str) -> tuple[float, float] | None:
    """Try to read bounding box or node size from the i3d file itself."""
    try:
        tree = ET.parse(i3d_path)
        root = tree.getroot()
        # <Scene> → bounding boxes sometimes stored here
        for elem in root.iter():
            # Look for clipDistance or similar large values that indicate building scale
            for attr in ("boundingVolume", "clipDistance"):
                val = elem.get(attr)
                if val:
                    nums = re.findall(r"[-\d.]+", val)
                    if len(nums) >= 6:
                        try:
                            xs = [float(nums[i]) for i in [0, 3]]
                            zs = [float(nums[i]) for i in [2, 5]]
                            w = abs(xs[1] - xs[0])
                            d = abs(zs[1] - zs[0])
                            if 3 < w < 200 and 3 < d < 200:
                                return round(w, 1), round(d, 1)
                        except (ValueError, IndexError):
                            pass
    except Exception:
        pass
    return None

# ── Main scan ─────────────────────────────────────────────────────────────────

print("=" * 60)
print("  South Warwickshire FS25 — Building Scanner")
print("=" * 60)
print()

schema_entries = []
all_found = []

for label, mod_folder in MOD_FOLDERS:
    mod_folder = os.path.expanduser(mod_folder)
    if not os.path.isdir(mod_folder):
        print(f"⚠️  NOT FOUND: {label}")
        print(f"   Path: {mod_folder}")
        print(f"   → Update the MOD_FOLDERS path at the top of this script")
        print()
        continue

    print(f"📂 {label}")
    print(f"   {mod_folder}")

    items = parse_moddesc(mod_folder)

    if not items:
        # Fallback: scan for i3d files directly
        i3d_files = find_i3d_files(mod_folder)
        for i3d in i3d_files:
            dims = extract_size_from_i3d(i3d)
            name = os.path.splitext(os.path.basename(i3d))[0]
            items.append({
                "i3d_absolute": i3d,
                "i3d_relative": None,
                "dimensions": dims,
                "name": name,
                "placeable_xml": None,
            })

    if not items:
        print(f"   ⚠️  No building files found — check folder structure")
        print()
        continue

    for item in items:
        name = item["name"]
        dims = item["dimensions"]
        i3d_abs = item.get("i3d_absolute")
        i3d_rel = item.get("i3d_relative")

        # Build the path that goes into the schema
        # maps4fs resolves /assets/... relative to the custom map template
        # The path must be how the file will be located INSIDE the template ZIP
        if i3d_abs:
            # Make it relative to the mod folder root
            try:
                rel = os.path.relpath(i3d_abs, mod_folder)
                schema_path = "/assets/buildings/" + rel.replace("\\", "/")
            except ValueError:
                schema_path = "/assets/buildings/" + os.path.basename(i3d_abs)
        elif i3d_rel:
            schema_path = "/assets/buildings/" + i3d_rel.replace("\\", "/").lstrip("./")
        else:
            schema_path = f"/assets/buildings/{name}/{name}.i3d"

        w, d = (dims[0], dims[1]) if dims else (0.0, 0.0)
        cat = guess_category(name)

        entry = {
            "file": schema_path,
            "name": name,
            "width": w,
            "depth": d,
            "type": "building",
            "categories": [cat],
            "regions": ["EU"],
            "_source": label,
            "_needs_dims": dims is None,
            "_local_path": i3d_abs or "",
        }
        schema_entries.append(entry)
        all_found.append(entry)

        dim_str = f"{w}×{d}m" if dims else "⚠️  DIMENSIONS UNKNOWN"
        print(f"   ✅  {name:40s}  {cat:12s}  {dim_str}")

    print()

print("=" * 60)
print(f"  Total buildings found: {len(schema_entries)}")
needs_dims = [e for e in schema_entries if e.get("_needs_dims")]
if needs_dims:
    print(f"  ⚠️  {len(needs_dims)} buildings have UNKNOWN dimensions — you must fill these in manually")
print("=" * 60)
print()

# ── Write the schema (clean version without internal _ keys) ──────────────────
clean_schema = []
for e in schema_entries:
    clean_schema.append({
        "file":       e["file"],
        "name":       e["name"],
        "width":      e["width"],
        "depth":      e["depth"],
        "type":       e["type"],
        "categories": e["categories"],
        "regions":    e["regions"],
    })

out_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "fs25_buildings_schema_uk.json")
with open(out_path, "w") as f:
    json.dump(clean_schema, f, indent=2)

print(f"✅  Written: {out_path}")
print()

# ── Write a human-readable report so you can review and fix dims ──────────────
report_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "building_scan_report.txt")
with open(report_path, "w") as f:
    f.write("South Warwickshire FS25 — Building Scan Report\n")
    f.write("=" * 60 + "\n\n")
    f.write("Review each entry below.\n")
    f.write("If dimensions show 0.0×0.0 you MUST measure the building in\n")
    f.write("Giants Editor or check the mod page and update the JSON.\n\n")

    for e in schema_entries:
        f.write(f"Name:       {e['name']}\n")
        f.write(f"Source:     {e['_source']}\n")
        f.write(f"Category:   {e['categories'][0]}\n")
        f.write(f"Dimensions: {e['width']}m × {e['depth']}m")
        if e.get("_needs_dims"):
            f.write("  ⚠️  UNKNOWN — fix this!")
        f.write(f"\nFile path:  {e['file']}\n")
        if e.get("_local_path"):
            f.write(f"Local file: {e['_local_path']}\n")
        f.write("\n")

print(f"📋  Review report written: {report_path}")
print()
print("NEXT STEPS:")
print("  1. Open building_scan_report.txt and check all dimensions")
print("  2. For any showing 0.0×0.0, measure in Giants Editor or check the mod page")
print("  3. Update those entries in fs25_buildings_schema_uk.json")
print("  4. Copy your .i3d files into your custom map template under the /assets/buildings/ path")
print("  5. Run: python3 run_maps4fs.py --buildings")
