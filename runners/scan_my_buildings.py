#!/usr/bin/env python3
"""
scan_my_buildings.py — South Warwickshire FS25 map
===================================================
Run this on your Mac ONCE (or whenever you add new building mods).

It auto-discovers every subfolder inside BUILDINGS_ROOT, treats each one as
a mod, reads dimensions from modDesc.xml / placeable XML / .i3d files, and
writes:

    config/fs25_buildings_schema_uk.json   — consumed by place_farm_placeables.py
                                             and run_maps4fs.py --buildings
    outputs/building_scan_report.txt       — human-readable review / fix list

Usage:
    python3 runners/scan_my_buildings.py

Override the scan root at the command line if needed:
    python3 runners/scan_my_buildings.py /path/to/other/BUILDINGS
"""

import os, sys, json, re
import xml.etree.ElementTree as ET
from pathlib import Path

# ── Where are your building mods? ─────────────────────────────────────────────
# Every immediate subfolder of this directory is treated as one mod.
DEFAULT_BUILDINGS_ROOT = "/Users/alexwaterhouse/Documents/Modelling/FS/BUILDINGS"

BUILDINGS_ROOT = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_BUILDINGS_ROOT
BUILDINGS_ROOT = os.path.expanduser(BUILDINGS_ROOT)

# ── Output paths (relative to repo root) ─────────────────────────────────────
SCRIPT_DIR  = Path(__file__).resolve().parent
ROOT_DIR    = SCRIPT_DIR.parent
SCHEMA_OUT  = ROOT_DIR / "config" / "fs25_buildings_schema_uk.json"
REPORT_OUT  = ROOT_DIR / "outputs" / "building_scan_report.txt"

# ── Category hints — keyword in file/folder name → FS25 category ──────────────
CATEGORY_HINTS = {
    "shed":       "farmyard",
    "barn":       "farmyard",
    "grain":      "farmyard",
    "storage":    "farmyard",
    "silo":       "farmyard",
    "workshop":   "farmyard",
    "machinery":  "farmyard",
    "dutch":      "farmyard",
    "stable":     "farmyard",
    "pigsty":     "farmyard",
    "cowshed":    "farmyard",
    "house":      "residential",
    "cottage":    "residential",
    "farmhouse":  "residential",
    "bungalow":   "residential",
    "terrace":    "residential",
    "church":     "religious",
    "chapel":     "religious",
    "office":     "commercial",
    "shop":       "retail",
    "windmill":   "decoration",
}


def guess_category(name: str) -> str:
    n = name.lower()
    for kw, cat in CATEGORY_HINTS.items():
        if kw in n:
            return cat
    return "farmyard"


def parse_dimensions_from_xml(xml_path: str) -> tuple[float, float] | None:
    """Try to extract width/depth from a placeable or storeItem XML."""
    try:
        tree = ET.parse(xml_path)
        root = tree.getroot()
        for elem in root.iter():
            for w_attr, d_attr in [
                ("sizeX", "sizeZ"), ("width", "depth"), ("width", "length"),
                ("sizeWidth", "sizeDepth"), ("sizeWidth", "sizeLength"),
            ]:
                if elem.get(w_attr) and elem.get(d_attr):
                    try:
                        return float(elem.get(w_attr)), float(elem.get(d_attr))
                    except (ValueError, TypeError):
                        pass
    except Exception:
        pass
    return None


def parse_moddesc(mod_folder: str) -> list[dict]:
    """Parse modDesc.xml → list of placeable items with i3d path + dims."""
    moddesc_path = os.path.join(mod_folder, "modDesc.xml")
    if not os.path.isfile(moddesc_path):
        return []

    items = []
    try:
        tree = ET.parse(moddesc_path)
        root = tree.getroot()

        for item in root.iter("item"):
            filename = item.get("filename", "")
            if not filename:
                continue
            xml_path = os.path.normpath(os.path.join(mod_folder, filename))
            if not os.path.isfile(xml_path):
                continue

            try:
                pxml  = ET.parse(xml_path)
                proot = pxml.getroot()

                i3d_path = None
                for fname_elem in proot.iter("filename"):
                    fn = fname_elem.get("value") or fname_elem.text or ""
                    if fn.lower().endswith(".i3d"):
                        i3d_path = fn
                        break
                if not i3d_path:
                    for elem in proot.iter():
                        for attr_val in elem.attrib.values():
                            if isinstance(attr_val, str) and attr_val.lower().endswith(".i3d"):
                                i3d_path = attr_val
                                break
                        if i3d_path:
                            break

                dims = parse_dimensions_from_xml(xml_path)
                items.append({
                    "placeable_xml": xml_path,
                    "i3d_relative":  i3d_path,
                    "dimensions":    dims,
                    "name":          os.path.splitext(os.path.basename(xml_path))[0],
                })
            except Exception:
                continue
    except Exception as e:
        print(f"  [WARN] Could not parse modDesc.xml in {mod_folder}: {e}")

    return items


def find_i3d_files(mod_folder: str) -> list[str]:
    """Fallback: walk the mod folder for .i3d files, skipping asset-only dirs."""
    results = []
    skip = {"textures", "shaders", "materials", "sounds", "effects", "scripts"}
    for root_dir, dirs, files in os.walk(mod_folder):
        dirs[:] = [d for d in dirs if d.lower() not in skip]
        for f in files:
            if f.lower().endswith(".i3d"):
                results.append(os.path.join(root_dir, f))
    return results


def extract_size_from_i3d(i3d_path: str) -> tuple[float, float] | None:
    """Try to read a bounding box from the i3d file itself."""
    try:
        tree = ET.parse(i3d_path)
        root = tree.getroot()
        for elem in root.iter():
            for attr in ("boundingVolume", "clipDistance"):
                val = elem.get(attr)
                if val:
                    nums = re.findall(r"[-\d.]+", val)
                    if len(nums) >= 6:
                        try:
                            xs = [float(nums[i]) for i in [0, 3]]
                            zs = [float(nums[i]) for i in [2, 5]]
                            w  = abs(xs[1] - xs[0])
                            d  = abs(zs[1] - zs[0])
                            if 3 < w < 200 and 3 < d < 200:
                                return round(w, 1), round(d, 1)
                        except (ValueError, IndexError):
                            pass
    except Exception:
        pass
    return None


# ── Discover mod subfolders ────────────────────────────────────────────────────

print("=" * 60)
print("  South Warwickshire FS25 — Building Scanner")
print("=" * 60)
print()
print(f"Scanning: {BUILDINGS_ROOT}")
print()

if not os.path.isdir(BUILDINGS_ROOT):
    print(f"ERROR: BUILDINGS_ROOT not found: {BUILDINGS_ROOT}")
    print("  Either update DEFAULT_BUILDINGS_ROOT at the top of this script,")
    print("  or pass the path as an argument:  python3 runners/scan_my_buildings.py /path/to/BUILDINGS")
    sys.exit(1)

mod_folders = sorted(
    (entry.name, entry.path)
    for entry in os.scandir(BUILDINGS_ROOT)
    if entry.is_dir() and not entry.name.startswith(".")
)

print(f"  Found {len(mod_folders)} mod folder(s)\n")

# ── Scan each mod ──────────────────────────────────────────────────────────────

schema_entries = []

for label, mod_folder in mod_folders:
    print(f"📂 {label}")

    items = parse_moddesc(mod_folder)

    if not items:
        # Fallback: find .i3d files directly
        i3d_files = find_i3d_files(mod_folder)
        for i3d in i3d_files:
            dims = extract_size_from_i3d(i3d)
            name = os.path.splitext(os.path.basename(i3d))[0]
            items.append({
                "i3d_absolute":  i3d,
                "i3d_relative":  None,
                "dimensions":    dims,
                "name":          name,
                "placeable_xml": None,
            })

    if not items:
        print(f"   ⚠️  No building files found — check folder structure\n")
        continue

    for item in items:
        name    = item["name"]
        dims    = item["dimensions"]
        i3d_abs = item.get("i3d_absolute")
        i3d_rel = item.get("i3d_relative")

        # Try to get dims from the i3d itself if the XML didn't have them
        if not dims and i3d_abs and os.path.isfile(i3d_abs):
            dims = extract_size_from_i3d(i3d_abs)
        if not dims and i3d_rel:
            candidate = os.path.normpath(os.path.join(mod_folder, i3d_rel))
            if os.path.isfile(candidate):
                dims = extract_size_from_i3d(candidate)

        # Build template-relative path
        if i3d_abs:
            try:
                rel = os.path.relpath(i3d_abs, mod_folder)
                schema_path = f"/assets/buildings/{label}/{rel.replace(os.sep, '/')}"
            except ValueError:
                schema_path = f"/assets/buildings/{label}/{os.path.basename(i3d_abs)}"
        elif i3d_rel:
            schema_path = f"/assets/buildings/{label}/{i3d_rel.replace(chr(92), '/').lstrip('./')}"
        else:
            schema_path = f"/assets/buildings/{label}/{name}/{name}.i3d"

        w, d  = (dims[0], dims[1]) if dims else (0.0, 0.0)
        cat   = guess_category(name)

        schema_entries.append({
            "file":        schema_path,
            "name":        name,
            "width":       w,
            "depth":       d,
            "type":        "building",
            "categories":  [cat],
            "regions":     ["EU"],
            # internal keys stripped before writing clean schema
            "_source":     label,
            "_local_path": i3d_abs or "",
            "_needs_dims": dims is None,
        })

        dim_str = f"{w}×{d}m" if dims else "⚠️  DIMS UNKNOWN"
        print(f"   ✅  {name:45s}  {cat:12s}  {dim_str}")

    print()

# ── Summary ───────────────────────────────────────────────────────────────────

print("=" * 60)
print(f"  Total buildings scanned : {len(schema_entries)}")
needs_dims = [e for e in schema_entries if e["_needs_dims"]]
if needs_dims:
    print(f"  ⚠️  {len(needs_dims)} with UNKNOWN dimensions — see report")
print("=" * 60)
print()

# ── Write clean schema ────────────────────────────────────────────────────────

SCHEMA_OUT.parent.mkdir(parents=True, exist_ok=True)
clean = [
    {k: v for k, v in e.items() if not k.startswith("_")}
    for e in schema_entries
]
with open(SCHEMA_OUT, "w") as f:
    json.dump(clean, f, indent=2)
print(f"✅  Schema written : {SCHEMA_OUT}")

# ── Write human-readable report ───────────────────────────────────────────────

REPORT_OUT.parent.mkdir(parents=True, exist_ok=True)
with open(REPORT_OUT, "w") as f:
    f.write("South Warwickshire FS25 — Building Scan Report\n")
    f.write("=" * 60 + "\n\n")
    f.write(f"Scanned root: {BUILDINGS_ROOT}\n\n")
    f.write("If dimensions show 0.0×0.0 you MUST measure the building in\n")
    f.write("Giants Editor or check the mod page and update the JSON.\n\n")
    for e in schema_entries:
        f.write(f"Name:       {e['name']}\n")
        f.write(f"Source:     {e['_source']}\n")
        f.write(f"Category:   {e['categories'][0]}\n")
        f.write(f"Dimensions: {e['width']}m × {e['depth']}m")
        if e["_needs_dims"]:
            f.write("  ⚠️  UNKNOWN — fix this!")
        f.write(f"\nFile path:  {e['file']}\n")
        if e["_local_path"]:
            f.write(f"Local file: {e['_local_path']}\n")
        f.write("\n")

print(f"📋  Report written  : {REPORT_OUT}")
print()
print("NEXT STEPS:")
print("  1. Check outputs/building_scan_report.txt for any 0.0×0.0 dimensions")
print("  2. Fix those entries in config/fs25_buildings_schema_uk.json")
print("  3. Run: python3 pipeline/place_farm_placeables.py")
print("  4. Run: python3 runners/run_maps4fs.py --buildings")
