#!/usr/bin/env python3
"""
optimise_ge_assets.py — South Warwickshire FS25
================================================
Optimises every building folder inside outputs/ge_ready/:

  1. Resize textures to the nearest power-of-two ≤ 2048 px per axis
     (Giants Editor / FS25 requires power-of-two texture dimensions)

  2. Convert PNG / JPG / TGA → DDS with correct compression:
       Normal maps  (_n / _normal / nrm)  → BC5  (best for normals)
       Textures with alpha channel         → BC3 / DXT5
       Everything else                     → BC1 / DXT1  (smallest)

  3. Patch every .i3d, .mtl, and .fbx file in the folder so the
     material references point at the new .dds filenames — textures
     will load correctly in Giants Editor and Blender without any
     manual re-linking.

DDS conversion tool priority (first found wins):
  nvcompress   →  brew install nvidia-texture-tools
  magick       →  brew install imagemagick
  (fallback)   →  saves optimised PNG in-place (no DDS, still resizes)

Usage:
    python3 runners/optimise_ge_assets.py
    python3 runners/optimise_ge_assets.py /path/to/ge_ready
"""

import os
import re
import sys
import subprocess
from pathlib import Path

try:
    from PIL import Image
    import numpy as np
except ImportError:
    print("ERROR: Pillow is required.  Run:  pip3 install pillow numpy")
    sys.exit(1)

# Allow very large textures (some FS25 assets exceed Pillow's default limit)
Image.MAX_IMAGE_PIXELS = None

# ── Paths ──────────────────────────────────────────────────────────────────
SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT  = SCRIPT_DIR.parent
GE_READY   = Path(sys.argv[1]) if len(sys.argv) > 1 else REPO_ROOT / "outputs" / "ge_ready"

# ── Config ─────────────────────────────────────────────────────────────────
MAX_DIM      = 2048          # maximum texture size per axis (FS25 practical limit)
IMAGE_EXTS   = {".png", ".jpg", ".jpeg", ".tga", ".bmp", ".tif", ".tiff"}
MODEL_EXTS   = {".i3d", ".mtl", ".fbx", ".obj", ".dae"}

# Filename tokens that identify a normal map
NORMAL_TOKENS = ("_n.", "_normal.", "_nrm.", "_norm.", "nrm.", "norm.")


# ── Helpers ────────────────────────────────────────────────────────────────

def prev_pow2(n: int) -> int:
    """Largest power-of-two that is ≤ n."""
    p = 1
    while p * 2 <= n:
        p *= 2
    return p


def target_dim(w: int, h: int):
    """Return (w2, h2) each snapped to the largest POT ≤ MAX_DIM."""
    return prev_pow2(min(w, MAX_DIM)), prev_pow2(min(h, MAX_DIM))


def image_has_alpha(img: Image.Image) -> bool:
    if img.mode in ("RGBA", "LA"):
        alpha = np.array(img.getchannel("A"))
        return bool(alpha.min() < 255)
    return False


def is_normal_map(path: Path) -> bool:
    name = path.name.lower()
    return any(tok in name for tok in NORMAL_TOKENS)


def dds_compression(path: Path, img: Image.Image) -> str:
    """Return the nvcompress / magick compression flag for this texture."""
    if is_normal_map(path):
        return "bc5"
    if image_has_alpha(img):
        return "bc3"
    return "bc1"


# ── Tool detection ─────────────────────────────────────────────────────────

def detect_dds_tool():
    """Return ('nvcompress'|'magick'|None, executable_name)."""
    # nvcompress (NVIDIA Texture Tools)
    try:
        r = subprocess.run(["nvcompress", "--version"],
                           capture_output=True, timeout=5)
        if r.returncode == 0:
            return "nvcompress", "nvcompress"
    except FileNotFoundError:
        pass

    # ImageMagick — check it has DDS support
    for exe in ("magick", "convert"):
        try:
            r = subprocess.run([exe, "-list", "format"],
                               capture_output=True, timeout=5)
            if r.returncode == 0 and b"DDS" in r.stdout.upper():
                return "magick", exe
        except FileNotFoundError:
            pass

    return None, None


# ── DDS conversion ─────────────────────────────────────────────────────────

def to_dds_nvcompress(src: Path, dst: Path, comp: str) -> bool:
    flag = f"-{comp}"
    try:
        r = subprocess.run(["nvcompress", flag, str(src), str(dst)],
                           capture_output=True, timeout=120)
        return r.returncode == 0 and dst.exists()
    except Exception:
        return False


def to_dds_magick(exe: str, src: Path, dst: Path, comp: str) -> bool:
    # magick DDS compression map: bc1→dxt1, bc3→dxt5, bc5→dxt5 (fallback)
    comp_map = {"bc1": "dxt1", "bc3": "dxt5", "bc5": "dxt5"}
    dxt = comp_map.get(comp, "dxt5")
    try:
        r = subprocess.run(
            [exe, str(src), "-define", f"dds:compression={dxt}", str(dst)],
            capture_output=True, timeout=120,
        )
        return r.returncode == 0 and dst.exists()
    except Exception:
        return False


# ── Reference patching ─────────────────────────────────────────────────────

def patch_file(path: Path, old: str, new: str) -> bool:
    """Replace every occurrence of `old` with `new` in a text file."""
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
        if old not in text:
            return False
        path.write_text(text.replace(old, new), encoding="utf-8")
        return True
    except Exception:
        return False


def patch_model_refs(folder: Path, old_name: str, new_name: str) -> list[str]:
    """
    Walk every model/material file in `folder` and replace `old_name`
    with `new_name`.  Returns list of patched filenames.
    """
    patched = []
    for f in folder.rglob("*"):
        if f.suffix.lower() in MODEL_EXTS and f.is_file():
            if patch_file(f, old_name, new_name):
                patched.append(f.name)
    return patched


# ── Per-building processing ────────────────────────────────────────────────

def process_building(folder: Path, tool_name, tool_exe) -> dict:
    stats = {
        "resized": 0, "converted": 0, "optimised": 0,
        "bytes_before": 0, "bytes_after": 0,
    }

    textures = [f for f in folder.rglob("*")
                if f.suffix.lower() in IMAGE_EXTS and f.is_file()]

    for tex in textures:
        stats["bytes_before"] += tex.stat().st_size

        try:
            img = Image.open(tex)
            img.load()  # force full decode now so errors surface here
        except Exception as e:
            print(f"       ⚠️  skipping {tex.name}: {e}")
            stats["bytes_after"] += tex.stat().st_size
            continue
        orig_w, orig_h = img.size
        tw, th = target_dim(orig_w, orig_h)
        resized = (tw != orig_w or th != orig_h)

        if resized:
            img = img.resize((tw, th), Image.LANCZOS)

        # ── Try DDS conversion ─────────────────────────────────────────
        dds_ok = False
        if tool_name:
            comp     = dds_compression(tex, img)
            dds_path = tex.with_suffix(".dds")

            # Write a temporary PNG if we resized or source isn't PNG/TGA
            if resized or tex.suffix.lower() not in (".png", ".tga"):
                tmp = tex.with_name(f"__tmp_{tex.stem}.png")
                img.save(str(tmp), optimize=True)
                src_for_conv = tmp
            else:
                tmp = None
                src_for_conv = tex

            if tool_name == "nvcompress":
                dds_ok = to_dds_nvcompress(src_for_conv, dds_path, comp)
            else:
                dds_ok = to_dds_magick(tool_exe, src_for_conv, dds_path, comp)

            if tmp:
                tmp.unlink(missing_ok=True)

            if dds_ok:
                # Patch every model file in this folder to reference the .dds
                patch_model_refs(folder, tex.name, dds_path.name)
                tex.unlink()
                stats["bytes_after"] += dds_path.stat().st_size
                stats["converted"] += 1
                continue

        # ── Fallback: optimised PNG / JPEG ────────────────────────────
        if tex.suffix.lower() in (".jpg", ".jpeg"):
            if img.mode == "RGBA":
                img = img.convert("RGB")
            img.save(str(tex), quality=90, optimize=True)
        else:
            img.save(str(tex), optimize=True, compress_level=9)

        stats["bytes_after"] += tex.stat().st_size
        if resized:
            stats["resized"] += 1
        else:
            stats["optimised"] += 1

    return stats


# ── Main ───────────────────────────────────────────────────────────────────

def main():
    if not GE_READY.is_dir():
        print(f"ERROR: ge_ready folder not found:\n  {GE_READY}")
        print("Run prepare_ge_assets.py first.")
        sys.exit(1)

    tool_name, tool_exe = detect_dds_tool()

    print("=" * 60)
    print("  South Warwickshire FS25 — Optimise GE Assets")
    print("=" * 60)
    print(f"  Source  : {GE_READY}")
    print(f"  Max dim : {MAX_DIM}×{MAX_DIM} px  (power-of-two)")
    if tool_name:
        print(f"  DDS tool: {tool_name} ({tool_exe})  ✅")
    else:
        print("  DDS tool: not found — textures will be optimised PNG only")
        print("            To enable DDS:  brew install nvidia-texture-tools")
    print()

    # Collect top-level building folders
    building_folders = sorted(
        [d for d in GE_READY.iterdir() if d.is_dir()],
        key=lambda d: d.name,
    )
    print(f"  {len(building_folders)} building folder(s) found\n")

    total_before = total_after = 0
    total_resized = total_converted = total_optimised = 0

    for folder in building_folders:
        # Each top-level folder may itself contain sub-folders per model
        # Process recursively by finding the leaf dirs that contain textures
        texture_files = [f for f in folder.rglob("*")
                         if f.suffix.lower() in IMAGE_EXTS and f.is_file()]
        if not texture_files:
            print(f"  ─  {folder.name}  (no textures)")
            continue

        stats = process_building(folder, tool_name, tool_exe)

        total_before    += stats["bytes_before"]
        total_after     += stats["bytes_after"]
        total_resized   += stats["resized"]
        total_converted += stats["converted"]
        total_optimised += stats["optimised"]

        saved_kb = (stats["bytes_before"] - stats["bytes_after"]) / 1024
        pct      = (saved_kb * 1024 / stats["bytes_before"] * 100
                    if stats["bytes_before"] else 0)

        parts = []
        if stats["converted"]:
            parts.append(f"{stats['converted']} → DDS")
        if stats["resized"]:
            parts.append(f"{stats['resized']} resized")
        if stats["optimised"]:
            parts.append(f"{stats['optimised']} PNG-opt")
        tag = "  ".join(parts) if parts else "no textures"

        print(f"  ✅  {folder.name}")
        print(f"       {tag}  |  saved {saved_kb:.0f} KB  ({pct:.0f}%)")

    total_saved_mb = (total_before - total_after) / 1_048_576
    print()
    print("─" * 60)
    print(f"  Total saved  : {total_saved_mb:.1f} MB")
    print(f"  DDS converts : {total_converted}")
    print(f"  Resized      : {total_resized}")
    print(f"  PNG-opt only : {total_optimised}")
    print()
    if not tool_name:
        print("TIP: Install nvcompress for full DDS conversion:")
        print("     brew install nvidia-texture-tools")
        print("     then re-run this script.")
    else:
        print("All textures converted to DDS and model references updated.")
        print("Import the .i3d / .fbx / .obj files into Giants Editor as normal.")
    print()


if __name__ == "__main__":
    main()
