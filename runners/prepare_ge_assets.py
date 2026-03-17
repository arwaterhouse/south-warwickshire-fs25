#!/usr/bin/env python3
"""
prepare_ge_assets.py — South Warwickshire FS25
===============================================
Scans BUILDINGS_ROOT for every supported 3D model format and exports each
building into a clean, self-contained folder under outputs/ge_ready/.

Supported source formats (in preference order):
  .i3d    → fix texture paths, copy as-is  (GE native)
  .fbx    → copy as-is                     (GE can import directly)
  .obj    → copy with .mtl + textures      (GE can import directly)
  .glb    → convert to FBX via Blender     (if Blender is installed)
  .gltf   → convert to FBX via Blender     (if Blender is installed)
  .blend  → export to FBX via Blender      (if Blender is installed)
  .dae    → copy as-is / convert via Blender

For GE import:
  i3d  → File → Import → I3D
  fbx  → File → Import → FBX
  obj  → File → Import → OBJ

Usage:
    python3 runners/prepare_ge_assets.py
    python3 runners/prepare_ge_assets.py /path/to/BUILDINGS
"""

import os, sys, re, shutil, subprocess, tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

# ── Config ────────────────────────────────────────────────────────────────────
DEFAULT_BUILDINGS_ROOT = "/Users/alexwaterhouse/Documents/Modelling/FS/BUILDINGS"
BUILDINGS_ROOT = os.path.expanduser(sys.argv[1] if len(sys.argv) > 1 else DEFAULT_BUILDINGS_ROOT)

SCRIPT_DIR = Path(__file__).resolve().parent
ROOT_DIR   = SCRIPT_DIR.parent
OUTPUT_DIR = ROOT_DIR / "outputs" / "ge_ready"

# 3D formats in preference order (first found wins per folder)
MODEL_EXTS_ORDERED = [".i3d", ".fbx", ".obj", ".glb", ".gltf", ".blend", ".dae", ".3ds"]
MODEL_EXTS         = set(MODEL_EXTS_ORDERED)

# Texture / material extensions to always copy alongside the model
TEXTURE_EXTS = {".png", ".dds", ".jpg", ".jpeg", ".tga", ".bmp",
                ".mtl", ".xml", ".lua"}
SHAPE_SUFFIXES = (".shapes", ".i3d.shapes")

SKIP_DIRS = {"textures", "shaders", "materials", "sounds", "effects", "scripts"}

# Blender executable candidates (Mac + Linux)
BLENDER_CANDIDATES = [
    "/Applications/Blender.app/Contents/MacOS/Blender",
    "/Applications/Blender.app/Contents/MacOS/blender",
    "blender",
    "/usr/bin/blender",
    "/usr/local/bin/blender",
]

# ── Blender detection ─────────────────────────────────────────────────────────

def find_blender() -> str | None:
    for path in BLENDER_CANDIDATES:
        try:
            r = subprocess.run([path, "--version"], capture_output=True, timeout=5)
            if r.returncode == 0:
                return path
        except (FileNotFoundError, subprocess.TimeoutExpired):
            pass
    return None


BLENDER = find_blender()

# ── Folder discovery ──────────────────────────────────────────────────────────

def has_any_model(folder: str) -> bool:
    try:
        for f in os.listdir(folder):
            if Path(f).suffix.lower() in MODEL_EXTS:
                return True
    except PermissionError:
        pass
    return False


def has_building_files(folder: str) -> bool:
    """True if this folder directly contains model or xml files."""
    try:
        for f in os.listdir(folder):
            fl = f.lower()
            if Path(fl).suffix in MODEL_EXTS or (fl.endswith(".xml") and fl != "moddesc.xml"):
                return True
    except PermissionError:
        pass
    return False


def discover_mod_folders(root: str) -> list[tuple[str, str]]:
    """(label, path) for every building folder, up to two levels deep."""
    result = []
    for cat in sorted(os.scandir(root), key=lambda e: e.name):
        if not cat.is_dir() or cat.name.startswith("."):
            continue
        if has_building_files(cat.path):
            result.append((cat.name, cat.path))
        else:
            for sub in sorted(os.scandir(cat.path), key=lambda e: e.name):
                if sub.is_dir() and not sub.name.startswith("."):
                    result.append((f"{cat.name}/{sub.name}", sub.path))
    return result


# ── Model finding ─────────────────────────────────────────────────────────────

def find_models_in_folder(folder: str) -> dict[str, list[str]]:
    """
    Walk folder and return {ext: [abs_paths]} for all model files found.
    Skips pure-asset subdirs.
    """
    by_ext: dict[str, list[str]] = {}
    for root_dir, dirs, files in os.walk(folder):
        dirs[:] = [d for d in dirs if d.lower() not in SKIP_DIRS]
        for f in files:
            ext = Path(f).suffix.lower()
            if ext in MODEL_EXTS:
                by_ext.setdefault(ext, []).append(os.path.join(root_dir, f))
    return by_ext


def best_models(by_ext: dict[str, list[str]]) -> list[tuple[str, str]]:
    """
    Return (ext, path) list using the best available format.
    Prefer i3d > fbx > obj > glb > gltf > blend > dae.
    """
    for ext in MODEL_EXTS_ORDERED:
        if ext in by_ext:
            return [(ext, p) for p in by_ext[ext]]
    return []


# ── Asset helpers ─────────────────────────────────────────────────────────────

def collect_i3d_refs(i3d_path: str) -> list[str]:
    src_dir = os.path.dirname(i3d_path)
    found = []
    ref_attrs = {
        "filename", "normalMapFilename", "specularMapFilename",
        "glossMapFilename", "emissiveMapFilename", "file",
        "colorMapFilename", "reflectionMapFilename",
    }
    try:
        for elem in ET.parse(i3d_path).getroot().iter():
            for attr, val in elem.attrib.items():
                if attr in ref_attrs or any(
                    val.lower().endswith(e)
                    for e in (".png", ".dds", ".shapes", ".i3d.shapes", ".xml")
                ):
                    c = os.path.normpath(os.path.join(src_dir, val))
                    if os.path.isfile(c) and c not in found:
                        found.append(c)
    except Exception:
        pass
    return found


def copy_textures_from_dir(src_dir: str, dst_dir: str) -> int:
    """
    Copy all texture / material / shape files from src_dir → dst_dir (flat).
    Also recurses into common texture subdirectories (textures/, Textures/,
    materials/, Maps/, etc.) so FBX assets from Sketchfab/similar are complete.
    """
    TEXTURE_SUBDIRS = {"textures", "texture", "materials", "material",
                       "maps", "images", "assets", "albedo", "normal"}
    n = 0

    def _copy_file(src: str) -> None:
        nonlocal n
        fl = os.path.basename(src).lower()
        if Path(fl).suffix in TEXTURE_EXTS or any(fl.endswith(s) for s in SHAPE_SUFFIXES):
            dst = os.path.join(dst_dir, os.path.basename(src))
            if not os.path.exists(dst):
                shutil.copy2(src, dst)
                n += 1

    # Files directly in src_dir
    for fname in os.listdir(src_dir):
        full = os.path.join(src_dir, fname)
        if os.path.isfile(full):
            _copy_file(full)
        elif os.path.isdir(full) and fname.lower() in TEXTURE_SUBDIRS:
            # One level of recursion into texture subfolders
            for sub_fname in os.listdir(full):
                sub_full = os.path.join(full, sub_fname)
                if os.path.isfile(sub_full):
                    _copy_file(sub_full)

    return n


def rewrite_i3d_paths(i3d_path: str) -> None:
    """Replace any ../../ or absolute paths inside i3d with bare filenames."""
    try:
        txt = Path(i3d_path).read_text(encoding="utf-8", errors="replace")
        file_exts = r"\.(?:png|dds|jpg|jpeg|tga|shapes|xml)"
        txt = re.sub(
            rf'(["\'])([^"\']+?{file_exts})\1',
            lambda m: f'{m.group(1)}{os.path.basename(m.group(2))}{m.group(1)}',
            txt, flags=re.IGNORECASE,
        )
        Path(i3d_path).write_text(txt, encoding="utf-8")
    except Exception as e:
        print(f"      ⚠️  Path rewrite failed: {e}")


# ── Blender conversion ────────────────────────────────────────────────────────

BLENDER_EXPORT_SCRIPT = """
import bpy, sys, os

src  = sys.argv[sys.argv.index('--') + 1]
dst  = sys.argv[sys.argv.index('--') + 2]

# Clear scene
bpy.ops.wm.read_factory_settings(use_empty=True)

ext = os.path.splitext(src)[1].lower()
if ext == '.blend':
    bpy.ops.wm.open_mainfile(filepath=src)
elif ext in ('.glb', '.gltf'):
    bpy.ops.import_scene.gltf(filepath=src)
elif ext == '.obj':
    bpy.ops.wm.obj_import(filepath=src)
elif ext == '.dae':
    bpy.ops.wm.collada_import(filepath=src)
elif ext == '.fbx':
    bpy.ops.import_scene.fbx(filepath=src)
else:
    print(f'Unsupported: {ext}')
    sys.exit(1)

# Apply all transforms
for obj in bpy.context.scene.objects:
    if obj.type == 'MESH':
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

bpy.ops.export_scene.fbx(
    filepath=dst,
    use_selection=False,
    embed_textures=False,
    path_mode='COPY',
    axis_forward='-Z',
    axis_up='Y',
    bake_space_transform=True,
)
print(f'Exported: {dst}')
"""


def convert_to_fbx_via_blender(src_path: str, dst_fbx: str) -> bool:
    """Use Blender headlessly to convert src → FBX. Returns True on success."""
    if not BLENDER:
        return False
    with tempfile.NamedTemporaryFile(suffix=".py", mode="w",
                                     delete=False, encoding="utf-8") as tf:
        tf.write(BLENDER_EXPORT_SCRIPT)
        script_path = tf.name
    try:
        result = subprocess.run(
            [BLENDER, "--background", "--python", script_path,
             "--", src_path, dst_fbx],
            capture_output=True, text=True, timeout=120,
        )
        return result.returncode == 0 and os.path.isfile(dst_fbx)
    except Exception:
        return False
    finally:
        os.unlink(script_path)


# ── Export one building ───────────────────────────────────────────────────────

def export_building(label: str, src_model: str, ext: str, dst_dir: Path) -> str:
    """
    Copy / convert one model file into dst_dir.
    Returns a short status tag: 'i3d' | 'fbx' | 'obj' | 'converted' | 'failed'
    """
    src_dir  = os.path.dirname(src_model)
    basename = os.path.splitext(os.path.basename(src_model))[0]

    if ext == ".i3d":
        dst = dst_dir / os.path.basename(src_model)
        shutil.copy2(src_model, dst)
        for ref in collect_i3d_refs(src_model):
            dst_ref = dst_dir / os.path.basename(ref)
            if not dst_ref.exists():
                shutil.copy2(ref, dst_ref)
        copy_textures_from_dir(src_dir, str(dst_dir))
        rewrite_i3d_paths(str(dst))
        return "i3d"

    if ext in (".fbx", ".obj", ".dae", ".3ds"):
        dst = dst_dir / os.path.basename(src_model)
        shutil.copy2(src_model, dst)
        copy_textures_from_dir(src_dir, str(dst_dir))
        # For OBJ also copy the .mtl explicitly
        if ext == ".obj":
            mtl = os.path.join(src_dir, basename + ".mtl")
            if os.path.isfile(mtl):
                shutil.copy2(mtl, dst_dir / (basename + ".mtl"))
        return ext.lstrip(".")

    # .blend / .glb / .gltf — need Blender
    if BLENDER:
        dst_fbx = str(dst_dir / (basename + ".fbx"))
        ok = convert_to_fbx_via_blender(src_model, dst_fbx)
        if ok:
            copy_textures_from_dir(src_dir, str(dst_dir))
            return "converted→fbx"
        return "blender-failed"

    # No Blender — copy raw and flag
    dst = dst_dir / os.path.basename(src_model)
    shutil.copy2(src_model, dst)
    copy_textures_from_dir(src_dir, str(dst_dir))
    return f"{ext.lstrip('.')} (needs Blender to convert)"


# ── Main ──────────────────────────────────────────────────────────────────────

if not os.path.isdir(BUILDINGS_ROOT):
    print(f"ERROR: BUILDINGS_ROOT not found:\n  {BUILDINGS_ROOT}")
    print("Run on your Mac, or pass the path as an argument.")
    sys.exit(1)

print("=" * 60)
print("  South Warwickshire FS25 — Prepare GE Assets")
print("=" * 60)
print(f"  Source  : {BUILDINGS_ROOT}")
print(f"  Output  : {OUTPUT_DIR}")
print(f"  Blender : {BLENDER or 'not found — .blend/.glb/.gltf will be copied raw'}")
print()

if OUTPUT_DIR.exists():
    shutil.rmtree(OUTPUT_DIR)
OUTPUT_DIR.mkdir(parents=True)

mod_folders = discover_mod_folders(BUILDINGS_ROOT)
print(f"  Found {len(mod_folders)} building folder(s)\n")

counts = {"ok": 0, "skipped": 0, "needs_blender": 0}

for label, folder_path in mod_folders:
    by_ext = find_models_in_folder(folder_path)
    candidates = best_models(by_ext)

    if not candidates:
        # Show what IS in the folder so the user knows what to do
        all_files = []
        for rd, _, fnames in os.walk(folder_path):
            for f in fnames:
                all_files.append(f)
        exts = sorted({Path(f).suffix.lower() for f in all_files if Path(f).suffix})
        if all_files:
            ext_summary = "  ".join(exts) if exts else "unknown types"
            print(f"  ❌  {label}")
            print(f"       └─ {len(all_files)} file(s) but no 3D model — found: {ext_summary}")
            print(f"       └─ Need one of: .fbx  .obj  .glb  .blend  .i3d")
        else:
            print(f"  ❌  {label}")
            print(f"       └─ folder is empty — model not yet sourced")
        counts["skipped"] += 1
        continue

    out_label = label.replace("/", "_")

    for ext, src_model in candidates:
        name    = os.path.splitext(os.path.basename(src_model))[0]
        dst_dir = OUTPUT_DIR / out_label / name
        dst_dir.mkdir(parents=True, exist_ok=True)

        status = export_building(label, src_model, ext, dst_dir)
        n_files = len(list(dst_dir.iterdir()))

        needs_blender = "needs Blender" in status or "blender-failed" in status
        icon = "⚠️ " if needs_blender else "✅"
        print(f"  {icon} {label}/{name}")
        print(f"       └─ {status}  ({n_files} file{'s' if n_files != 1 else ''})")

        if needs_blender:
            counts["needs_blender"] += 1
        else:
            counts["ok"] += 1

print()
print(f"  Exported   : {counts['ok']}")
print(f"  No models  : {counts['skipped']}")
if counts["needs_blender"]:
    print(f"  Needs Blender : {counts['needs_blender']}")
    print()
    print("  Install Blender to auto-convert .blend / .glb / .gltf → FBX")
    print("  https://www.blender.org/download/")
print()
print("IMPORT INTO GIANTS EDITOR:")
print("  i3d files → File → Import → I3D")
print("  fbx files → File → Import → FBX")
print("  obj files → File → Import → OBJ")
print(f"\n  Assets are in: {OUTPUT_DIR}")
print()
print("TO PLACE BUILDINGS ON THE MAP:")
print("  python3 pipeline/place_farm_placeables.py")
print("  python3 pipeline/place_windmill.py")
