#!/usr/bin/env python3
"""
build_ge_assets.py — South Warwickshire FS25
============================================
All-in-one pipeline:
  copy originals → find best model → collect all textures from every
  sub-level → resize → DDS-convert → patch references → size report.

Steps
-----
  1. Back up any existing outputs/ge_ready/  →  ge_ready_backup/<timestamp>/
  2. Discover building folders in BUILDINGS_ROOT (walks any depth)
  3. Pick the best model per folder  (i3d > fbx > obj > glb > blend > dae)
  4. Copy model + EVERY texture / material file found anywhere under source tree
  5. Resize textures to ≤ MAX_DIM (2048 px) per axis, snapped to power-of-two
  6. Convert PNG / JPG / TGA → DDS with the right BC compression slot:
       normal maps    → BC5  (falls back to BC3 if pure-Python path is used)
       alpha textures → BC3 / DXT5
       colour only    → BC1 / DXT1
     Tool priority:  nvcompress  ›  magick  ›  squish (pure Python)  ›  PNG
  7. Patch every .i3d / .mtl / .obj / .fbx / .dae to reference .dds filenames
  8. Per-asset and grand-total size report, duplicate map_assets warning

Usage
-----
    python3 runners/build_ge_assets.py
    python3 runners/build_ge_assets.py /path/to/BUILDINGS_ROOT
    python3 runners/build_ge_assets.py /path/to/BUILDINGS_ROOT /path/to/output

Notes
-----
  • i3d files are the native Giants Engine format and are always preferred.
  • Non-i3d models (.fbx / .obj) can be imported directly into GE:
      GE → File → Import → FBX  /  OBJ
  • .blend / .glb / .gltf are converted to FBX via Blender (headless) when
    Blender is installed.  Install: https://www.blender.org/download/
  • For full DDS conversion install one of:
      brew install nvidia-texture-tools   # nvcompress — best quality
      brew install imagemagick            # magick      — good quality
      pip3 install squish                 # pure Python  — no brew needed
"""

from __future__ import annotations

import os
import re
import sys
import shutil
import struct
import subprocess
import tempfile
import xml.etree.ElementTree as ET
from datetime import datetime
from pathlib import Path

# ── optional deps ─────────────────────────────────────────────────────────────
try:
    from PIL import Image
    import numpy as np
    PILLOW_OK = True
except ImportError:
    print("ERROR: Pillow is required.  pip3 install pillow numpy")
    sys.exit(1)

Image.MAX_IMAGE_PIXELS = None   # allow very large textures

try:
    import squish as _squish
    SQUISH_OK = True
except ImportError:
    SQUISH_OK = False

# ── paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT  = SCRIPT_DIR.parent

DEFAULT_BUILDINGS = "/Users/alexwaterhouse/Documents/Modelling/FS/BUILDINGS"
BUILDINGS_ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(DEFAULT_BUILDINGS)
OUTPUT_DIR     = Path(sys.argv[2]) if len(sys.argv) > 2 else REPO_ROOT / "outputs" / "ge_ready"
BACKUP_ROOT    = REPO_ROOT / "outputs" / "ge_ready_backup"

# ── config ────────────────────────────────────────────────────────────────────
MAX_DIM      = 2048
IMAGE_EXTS   = {".png", ".jpg", ".jpeg", ".tga", ".bmp", ".tif", ".tiff"}
DDS_EXT      = ".dds"
MODEL_EXTS_ORDERED = [".i3d", ".fbx", ".obj", ".glb", ".gltf", ".blend", ".dae", ".3ds"]
MODEL_EXTS         = set(MODEL_EXTS_ORDERED)
TEXTURE_EXTS = {".png", ".dds", ".jpg", ".jpeg", ".tga", ".bmp",
                ".mtl", ".xml", ".lua"}
SHAPE_SUFFIXES = (".shapes", ".i3d.shapes")
PATCH_EXTS   = {".i3d", ".mtl", ".fbx", ".obj", ".dae"}
SKIP_DIRS    = {"__macosx", ".git", ".ds_store"}
NORMAL_TOKENS = ("_n.", "_normal.", "_nrm.", "_norm.", "nrm.", "norm.")

BLENDER_CANDIDATES = [
    "/Applications/Blender.app/Contents/MacOS/Blender",
    "/Applications/Blender.app/Contents/MacOS/blender",
    "blender", "/usr/bin/blender", "/usr/local/bin/blender",
]

# ── helpers ───────────────────────────────────────────────────────────────────

def _prev_pow2(n: int) -> int:
    p = 1
    while p * 2 <= n:
        p *= 2
    return p


def _target_dim(w: int, h: int) -> tuple[int, int]:
    return _prev_pow2(min(w, MAX_DIM)), _prev_pow2(min(h, MAX_DIM))


def _has_real_alpha(img: Image.Image) -> bool:
    if img.mode in ("RGBA", "LA"):
        arr = np.array(img.getchannel("A"))
        return bool(arr.min() < 255)
    return False


def _is_normal(path: Path) -> bool:
    name = path.name.lower()
    return any(t in name for t in NORMAL_TOKENS)


def _dds_comp(path: Path, img: Image.Image) -> str:
    if _is_normal(path):
        return "bc5"
    if _has_real_alpha(img):
        return "bc3"
    return "bc1"


def _fmt_mb(b: int) -> str:
    return f"{b / 1_048_576:.1f} MB"


def _dir_size(path: Path) -> int:
    return sum(f.stat().st_size for f in path.rglob("*") if f.is_file())

# ── tool detection ────────────────────────────────────────────────────────────

def _detect_dds_tool() -> tuple[str | None, str | None]:
    # nvcompress
    try:
        r = subprocess.run(["nvcompress", "--version"], capture_output=True, timeout=5)
        if r.returncode == 0:
            return "nvcompress", "nvcompress"
    except FileNotFoundError:
        pass
    # ImageMagick
    for exe in ("magick", "convert"):
        try:
            r = subprocess.run([exe, "-list", "format"], capture_output=True, timeout=5)
            if r.returncode == 0 and b"DDS" in r.stdout.upper():
                return "magick", exe
        except FileNotFoundError:
            pass
    # squish (pure Python)
    if SQUISH_OK:
        return "squish", "squish"
    return None, None


def _find_blender() -> str | None:
    for p in BLENDER_CANDIDATES:
        try:
            r = subprocess.run([p, "--version"], capture_output=True, timeout=5)
            if r.returncode == 0:
                return p
        except (FileNotFoundError, subprocess.TimeoutExpired):
            pass
    return None

# ── DDS writers ───────────────────────────────────────────────────────────────

def _write_dds_header(f, w: int, h: int, fourcc: str, mipmaps: int = 0) -> None:
    """Write DDS magic + header for a single-surface BC-compressed texture."""
    DDSD_CAPS        = 0x1
    DDSD_HEIGHT      = 0x2
    DDSD_WIDTH       = 0x4
    DDSD_PIXELFORMAT = 0x1000
    DDSD_LINEARSIZE  = 0x80000
    DDPF_FOURCC      = 0x4
    DDSCAPS_TEXTURE  = 0x1000
    DDSCAPS_MIPMAP   = 0x400000
    DDSCAPS_COMPLEX  = 0x8

    is_dxt1    = fourcc.upper() == "DXT1"
    block_size = 8 if is_dxt1 else 16
    linear     = max(1, (w + 3) // 4) * max(1, (h + 3) // 4) * block_size

    flags = DDSD_CAPS | DDSD_HEIGHT | DDSD_WIDTH | DDSD_PIXELFORMAT | DDSD_LINEARSIZE
    caps  = DDSCAPS_TEXTURE
    if mipmaps > 1:
        flags |= 0x20000   # DDSD_MIPMAPCOUNT
        caps  |= DDSCAPS_MIPMAP | DDSCAPS_COMPLEX

    # DDS_PIXELFORMAT (32 bytes)
    pf = struct.pack("<II4sIIIII",
        32, DDPF_FOURCC, fourcc.upper().encode("ascii"),
        0, 0, 0, 0, 0)

    # DDS_HEADER (124 bytes)
    header = struct.pack("<IIIIIII",
        124, flags, h, w, linear, 0, mipmaps)
    header += b"\x00" * 44   # reserved1[11]
    header += pf
    header += struct.pack("<IIII", caps, 0, 0, 0)
    header += b"\x00" * 4    # reserved2

    f.write(b"DDS ")
    f.write(header)


def _to_dds_squish(img: Image.Image, dst: Path, comp: str) -> bool:
    """Pure-Python DDS via squish library.  BC5 falls back to BC3/DXT5."""
    try:
        import squish
    except ImportError:
        return False

    # squish needs RGBA bytes
    w, h = img.size
    rgba = img.convert("RGBA")
    raw  = rgba.tobytes()

    if comp in ("bc1",):
        flags  = squish.DXT1
        fourcc = "DXT1"
    else:                       # bc3 or bc5 (squish has no BC5)
        flags  = squish.DXT5
        fourcc = "DXT5"

    try:
        compressed = squish.compress(raw, w, h,
                                     flags | squish.COLOUR_ITERATIVE_CLUSTER_FIT)
    except Exception:
        return False

    try:
        with open(dst, "wb") as fh:
            _write_dds_header(fh, w, h, fourcc)
            fh.write(compressed)
        return True
    except Exception:
        dst.unlink(missing_ok=True)
        return False


def _to_dds_nvcompress(src: Path, dst: Path, comp: str) -> bool:
    try:
        r = subprocess.run(["nvcompress", f"-{comp}", str(src), str(dst)],
                           capture_output=True, timeout=300)
        return r.returncode == 0 and dst.exists()
    except Exception:
        return False


def _to_dds_magick(exe: str, src: Path, dst: Path, comp: str) -> bool:
    comp_map = {"bc1": "dxt1", "bc3": "dxt5", "bc5": "dxt5"}
    dxt = comp_map.get(comp, "dxt5")
    try:
        r = subprocess.run(
            [exe, str(src), "-define", f"dds:compression={dxt}", str(dst)],
            capture_output=True, timeout=300)
        return r.returncode == 0 and dst.exists()
    except Exception:
        return False

# ── reference patching ────────────────────────────────────────────────────────

def _patch_file(path: Path, old: str, new: str) -> bool:
    try:
        txt = path.read_text(encoding="utf-8", errors="replace")
        if old not in txt:
            return False
        path.write_text(txt.replace(old, new), encoding="utf-8")
        return True
    except Exception:
        return False


def _patch_folder(folder: Path, old_name: str, new_name: str) -> None:
    for f in folder.rglob("*"):
        if f.suffix.lower() in PATCH_EXTS and f.is_file():
            _patch_file(f, old_name, new_name)

# ── building discovery ────────────────────────────────────────────────────────

def _has_model(folder: Path) -> bool:
    try:
        return any(f.suffix.lower() in MODEL_EXTS for f in folder.iterdir())
    except PermissionError:
        return False


def _discover_buildings(root: Path) -> list[tuple[str, Path]]:
    """
    Walk root at any depth and return (label, folder_path) for every
    folder that directly contains at least one model file.
    """
    results: list[tuple[str, Path]] = []
    for dirpath, dirnames, filenames in os.walk(root):
        dp = Path(dirpath)
        # skip hidden / system dirs
        dirnames[:] = [d for d in dirnames
                       if d.lower() not in SKIP_DIRS and not d.startswith(".")]
        if any(Path(f).suffix.lower() in MODEL_EXTS for f in filenames):
            label = str(dp.relative_to(root))
            results.append((label, dp))
    return sorted(results, key=lambda x: x[0])


def _find_models(folder: Path) -> dict[str, list[Path]]:
    """Walk folder and return {ext: [paths]} for every model file found."""
    by_ext: dict[str, list[Path]] = {}
    for f in folder.rglob("*"):
        if f.is_file() and f.suffix.lower() in MODEL_EXTS:
            ext = f.suffix.lower()
            by_ext.setdefault(ext, []).append(f)
    return by_ext


def _best_models(by_ext: dict[str, list[Path]]) -> list[tuple[str, Path]]:
    for ext in MODEL_EXTS_ORDERED:
        if ext in by_ext:
            return [(ext, p) for p in by_ext[ext]]
    return []

# ── texture / material collection ────────────────────────────────────────────

def _collect_i3d_refs(i3d_path: Path) -> list[Path]:
    src_dir = i3d_path.parent
    found: list[Path] = []
    ref_attrs = {
        "filename", "normalMapFilename", "specularMapFilename",
        "glossMapFilename", "emissiveMapFilename", "file",
        "colorMapFilename", "reflectionMapFilename",
    }
    check_exts = (".png", ".dds", ".shapes", ".i3d.shapes", ".xml", ".jpg",
                  ".jpeg", ".tga")
    try:
        for elem in ET.parse(str(i3d_path)).getroot().iter():
            for attr, val in elem.attrib.items():
                if attr in ref_attrs or any(val.lower().endswith(e) for e in check_exts):
                    c = (src_dir / val).resolve()
                    if c.is_file() and c not in found:
                        found.append(c)
    except Exception:
        pass
    return found


def _collect_mtl_textures(mtl_path: Path) -> list[Path]:
    """Parse an .mtl file and return all referenced texture paths that exist."""
    found: list[Path] = []
    src_dir = mtl_path.parent
    try:
        for line in mtl_path.read_text(encoding="utf-8", errors="replace").splitlines():
            parts = line.strip().split()
            if len(parts) >= 2 and parts[0].lower().startswith("map_"):
                candidate = (src_dir / parts[-1]).resolve()
                if candidate.is_file() and candidate not in found:
                    found.append(candidate)
    except Exception:
        pass
    return found


def _copy_all_assets(src_tree: Path, dst_dir: Path) -> int:
    """
    Walk the entire src_tree (every depth) and copy every texture / material /
    shapes file into dst_dir (flat).  Skip model-format files.
    Returns number of files copied.
    """
    copied = 0
    for f in src_tree.rglob("*"):
        if not f.is_file():
            continue
        fl  = f.name.lower()
        ext = Path(fl).suffix
        is_shape = any(fl.endswith(s) for s in SHAPE_SUFFIXES)
        is_model = ext in MODEL_EXTS
        if (ext in TEXTURE_EXTS or is_shape) and not is_model:
            dst = dst_dir / f.name
            if not dst.exists():
                shutil.copy2(f, dst)
                copied += 1
    return copied


def _rewrite_i3d_paths(i3d_path: Path) -> None:
    """Strip path prefixes in .i3d — leave only bare filenames."""
    try:
        txt = i3d_path.read_text(encoding="utf-8", errors="replace")
        file_exts = r"\.(?:png|dds|jpg|jpeg|tga|shapes|xml)"
        txt = re.sub(
            rf'(["\'])([^"\']+?{file_exts})\1',
            lambda m: f'{m.group(1)}{os.path.basename(m.group(2))}{m.group(1)}',
            txt, flags=re.IGNORECASE,
        )
        i3d_path.write_text(txt, encoding="utf-8")
    except Exception as e:
        print(f"        ⚠  Path rewrite failed: {e}")

# ── Blender FBX conversion ────────────────────────────────────────────────────

_BLENDER_SCRIPT = """
import bpy, sys, os
src = sys.argv[sys.argv.index('--') + 1]
dst = sys.argv[sys.argv.index('--') + 2]
bpy.ops.wm.read_factory_settings(use_empty=True)
ext = os.path.splitext(src)[1].lower()
if   ext == '.blend': bpy.ops.wm.open_mainfile(filepath=src)
elif ext in ('.glb', '.gltf'): bpy.ops.import_scene.gltf(filepath=src)
elif ext == '.obj':   bpy.ops.wm.obj_import(filepath=src)
elif ext == '.dae':   bpy.ops.wm.collada_import(filepath=src)
elif ext == '.fbx':   bpy.ops.import_scene.fbx(filepath=src)
else: sys.exit(1)
for obj in bpy.context.scene.objects:
    if obj.type == 'MESH':
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
bpy.ops.export_scene.fbx(filepath=dst, use_selection=False, embed_textures=False,
    path_mode='COPY', axis_forward='-Z', axis_up='Y', bake_space_transform=True)
"""


def _convert_blender(blender: str, src: Path, dst_fbx: Path) -> bool:
    if not blender:
        return False
    with tempfile.NamedTemporaryFile(suffix=".py", mode="w",
                                     delete=False, encoding="utf-8") as tf:
        tf.write(_BLENDER_SCRIPT)
        script = tf.name
    try:
        r = subprocess.run(
            [blender, "--background", "--python", script, "--", str(src), str(dst_fbx)],
            capture_output=True, text=True, timeout=180)
        return r.returncode == 0 and dst_fbx.exists()
    except Exception:
        return False
    finally:
        os.unlink(script)

# ── texture optimisation ──────────────────────────────────────────────────────

def _optimise_texture(tex: Path, tool_name: str | None, tool_exe: str | None,
                      folder: Path) -> tuple[int, int, str]:
    """
    Process one texture file.
    Returns (bytes_before, bytes_after, action_tag).
    """
    before = tex.stat().st_size
    try:
        img = Image.open(tex)
        img.load()
    except Exception as e:
        return before, before, f"skip({e})"

    orig_w, orig_h = img.size
    tw, th = _target_dim(orig_w, orig_h)
    resized = tw != orig_w or th != orig_h
    if resized:
        img = img.resize((tw, th), Image.LANCZOS)

    # ── attempt DDS conversion ─────────────────────────────────────────
    dds_ok = False
    if tool_name:
        comp     = _dds_comp(tex, img)
        dds_path = tex.with_suffix(".dds")

        if tool_name == "squish":
            dds_ok = _to_dds_squish(img, dds_path, comp)
        else:
            # Need an actual file on disk for external tool
            if resized or tex.suffix.lower() not in (".png", ".tga"):
                tmp = tex.with_name(f"__tmp_{tex.stem}.png")
                img.save(str(tmp), optimize=True)
                src_for_conv = tmp
            else:
                tmp = None
                src_for_conv = tex

            if tool_name == "nvcompress":
                dds_ok = _to_dds_nvcompress(src_for_conv, dds_path, comp)
            else:  # magick
                dds_ok = _to_dds_magick(tool_exe, src_for_conv, dds_path, comp)

            if tmp:
                tmp.unlink(missing_ok=True)

        if dds_ok:
            _patch_folder(folder, tex.name, dds_path.name)
            tex.unlink()
            after = dds_path.stat().st_size
            tag = f"→DDS({comp})" + (" resized" if resized else "")
            return before, after, tag

    # ── PNG / JPEG fallback ────────────────────────────────────────────
    if tex.suffix.lower() in (".jpg", ".jpeg"):
        if img.mode == "RGBA":
            img = img.convert("RGB")
        img.save(str(tex), quality=90, optimize=True)
    else:
        img.save(str(tex), optimize=True, compress_level=9)

    after = tex.stat().st_size
    tag = ("resized+PNG" if resized else "PNG-opt")
    return before, after, tag

# ── export one building model ─────────────────────────────────────────────────

def _export_model(label: str, src_model: Path, ext: str, dst_dir: Path,
                  blender: str | None) -> str:
    """
    Copy / convert one model into dst_dir.
    Returns short status tag.
    """
    src_tree = src_model.parent  # start texture search here

    def _grab_textures() -> None:
        # Walk the model's folder AND its parent (catches model/ + sibling textures/)
        _copy_all_assets(src_tree, dst_dir)
        parent = src_tree.parent
        if parent != src_tree:
            _copy_all_assets(parent, dst_dir)

    if ext == ".i3d":
        dst = dst_dir / src_model.name
        shutil.copy2(src_model, dst)
        # Copy every explicitly-referenced file
        for ref in _collect_i3d_refs(src_model):
            dst_ref = dst_dir / ref.name
            if not dst_ref.exists():
                shutil.copy2(ref, dst_ref)
        _grab_textures()
        _rewrite_i3d_paths(dst)
        return "i3d"

    if ext in (".fbx", ".obj", ".dae", ".3ds"):
        dst = dst_dir / src_model.name
        shutil.copy2(src_model, dst)
        _grab_textures()
        if ext == ".obj":
            mtl = src_tree / (src_model.stem + ".mtl")
            if mtl.is_file():
                shutil.copy2(mtl, dst_dir / mtl.name)
                for t in _collect_mtl_textures(mtl):
                    dst_t = dst_dir / t.name
                    if not dst_t.exists():
                        shutil.copy2(t, dst_t)
        return ext.lstrip(".")

    # .blend / .glb / .gltf
    if blender:
        dst_fbx = dst_dir / (src_model.stem + ".fbx")
        if _convert_blender(blender, src_model, dst_fbx):
            _grab_textures()
            return "converted→fbx"
        return "blender-failed"

    # No blender — copy raw
    shutil.copy2(src_model, dst_dir / src_model.name)
    _grab_textures()
    return f"{ext.lstrip('.')} (needs Blender)"

# ── main ──────────────────────────────────────────────────────────────────────

def main() -> None:
    blender   = _find_blender()
    tool_name, tool_exe = _detect_dds_tool()

    print("=" * 62)
    print("  South Warwickshire FS25 — Build GE Assets")
    print("=" * 62)
    print(f"  Source   : {BUILDINGS_ROOT}")
    print(f"  Output   : {OUTPUT_DIR}")
    print(f"  Blender  : {blender or 'not found  (.blend/.glb → copied raw)'}")
    if tool_name:
        print(f"  DDS tool : {tool_name} ({tool_exe})  ✅")
    else:
        print("  DDS tool : none — will save optimised PNG")
        print("             brew install nvidia-texture-tools   # nvcompress")
        print("             brew install imagemagick             # magick")
        print("             pip3 install squish                  # Python DDS")
    print()

    # ── 1. validate source ────────────────────────────────────────────
    if not BUILDINGS_ROOT.is_dir():
        print(f"ERROR: BUILDINGS_ROOT not found:\n  {BUILDINGS_ROOT}")
        print("Pass the path as the first argument.")
        sys.exit(1)

    # ── 2. back up existing ge_ready ──────────────────────────────────
    if OUTPUT_DIR.exists():
        ts  = datetime.now().strftime("%Y-%m-%d_%H%M%S")
        bak = BACKUP_ROOT / ts
        print(f"  Backing up existing ge_ready → ge_ready_backup/{ts}/")
        shutil.copytree(OUTPUT_DIR, bak)
        shutil.rmtree(OUTPUT_DIR)
        print(f"  Backup size : {_fmt_mb(_dir_size(bak))}")
        print()

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # ── 3. discover buildings ─────────────────────────────────────────
    buildings = _discover_buildings(BUILDINGS_ROOT)
    if not buildings:
        print("No building folders found.  Nothing to do.")
        sys.exit(0)
    print(f"  {len(buildings)} building folder(s) found\n")

    counts = {"ok": 0, "no_model": 0, "needs_blender": 0}
    folder_sizes: list[tuple[str, int, int]] = []   # (name, before, after)

    for label, src_folder in buildings:
        by_ext   = _find_models(src_folder)
        candidates = _best_models(by_ext)

        if not candidates:
            all_exts = sorted({f.suffix.lower()
                               for f in src_folder.rglob("*") if f.is_file() and f.suffix})
            print(f"  ❌  {label}")
            print(f"       no 3D model — files: {' '.join(all_exts) or 'none'}")
            counts["no_model"] += 1
            continue

        out_label = label.replace("/", "_").replace("\\", "_")

        for ext, src_model in candidates:
            name    = src_model.stem
            dst_dir = OUTPUT_DIR / out_label / name
            dst_dir.mkdir(parents=True, exist_ok=True)

            # ── copy / convert model ───────────────────────────────
            status = _export_model(label, src_model, ext, dst_dir, blender)
            needs_blender = "needs Blender" in status or "blender-failed" in status

            # ── optimise every texture in dst_dir ─────────────────
            textures = [f for f in dst_dir.rglob("*")
                        if f.suffix.lower() in IMAGE_EXTS and f.is_file()
                        and f.suffix.lower() != DDS_EXT]

            tex_before = tex_after = 0
            tex_tags: dict[str, int] = {}
            for tex in textures:
                b, a, tag = _optimise_texture(tex, tool_name, tool_exe, dst_dir)
                tex_before += b
                tex_after  += a
                key = tag.split("(")[0].split(" ")[0]
                tex_tags[key] = tex_tags.get(key, 0) + 1

            # ── count DDS already present (not converted in this run) ──
            dds_existing = [f for f in dst_dir.rglob("*")
                            if f.suffix.lower() == DDS_EXT and f.is_file()]

            folder_total = _dir_size(dst_dir)
            folder_sizes.append((out_label, tex_before, tex_after))

            icon = "⚠️ " if needs_blender else "✅"
            saved_kb = (tex_before - tex_after) / 1024

            parts = []
            if tex_tags:
                for k, n in sorted(tex_tags.items()):
                    parts.append(f"{n}×{k}")
            if dds_existing and not textures:
                parts.append(f"{len(dds_existing)} DDS (already optimal)")
            if not parts:
                parts.append("no textures")

            summary = "  |  ".join(parts)
            pct = (saved_kb * 1024 / tex_before * 100) if tex_before else 0
            print(f"  {icon} {label}/{name}")
            print(f"       {status}  |  {summary}")
            if tex_before:
                print(f"       saved {saved_kb:,.0f} KB ({pct:.0f}%)  |  "
                      f"total {_fmt_mb(folder_total)}")

            if needs_blender:
                counts["needs_blender"] += 1
            else:
                counts["ok"] += 1

    # ── summary ───────────────────────────────────────────────────────
    total_before = sum(b for _, b, _ in folder_sizes)
    total_after  = sum(a for _, _, a in folder_sizes)
    grand_total  = _dir_size(OUTPUT_DIR)
    saved_mb     = (total_before - total_after) / 1_048_576

    print()
    print("─" * 62)
    print(f"  Exported       : {counts['ok']}")
    print(f"  No models      : {counts['no_model']}")
    if counts["needs_blender"]:
        print(f"  Needs Blender  : {counts['needs_blender']}")
    print(f"  Texture saved  : {saved_mb:.1f} MB")
    print(f"  Output size    : {_fmt_mb(grand_total)}")

    # ── top folders ───────────────────────────────────────────────────
    by_size = [(n, _dir_size(OUTPUT_DIR / n))
               for n in os.listdir(OUTPUT_DIR)
               if (OUTPUT_DIR / n).is_dir()]
    by_size.sort(key=lambda x: x[1], reverse=True)
    if by_size:
        print()
        print("  Top folders by size:")
        max_sz = by_size[0][1] if by_size else 1
        for name, sz in by_size[:10]:
            bar = "█" * max(1, int(sz / max_sz * 20))
            print(f"    {sz/1_048_576:7.0f} MB  {bar:<20}  {name}")

    # ── duplicate map_assets warning ──────────────────────────────────
    map_stripped = {n.removeprefix("map_assets_") for n, _ in by_size
                    if n.startswith("map_assets_")}
    dupes = [(n, s) for n, s in by_size
             if not n.startswith("map_assets_") and n in map_stripped]
    if dupes:
        dupe_mb = sum(s for _, s in dupes) / 1_048_576
        print()
        print(f"  ⚠  Possible duplicates ({dupe_mb:.0f} MB total):")
        print("     map_assets_X mirrors building folder X.")
        print("     If map_assets_X contains only XML (no .shapes files)")
        print("     you can safely delete it to recover space.")
        for n, s in dupes:
            print(f"       {s/1_048_576:6.0f} MB  {n}  ↔  map_assets_{n}")

    print()
    if tool_name:
        print("All textures converted to DDS and model references updated.")
    else:
        print("TIP: install a DDS tool for much greater size savings:")
        print("     pip3 install squish                  # quickest — no brew needed")
        print("     brew install nvidia-texture-tools    # nvcompress — best quality")
        print("     brew install imagemagick             # magick")
        print("     then re-run:  python3 runners/build_ge_assets.py")
    print()
    print("IMPORT INTO GIANTS EDITOR:")
    print("  i3d → File → Import → I3D   (native, always preferred)")
    print("  fbx → File → Import → FBX")
    print("  obj → File → Import → OBJ")
    print(f"\n  Assets are in: {OUTPUT_DIR}")
    print()


if __name__ == "__main__":
    main()
