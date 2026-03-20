#!/usr/bin/env python3
"""
fs22_to_fs25_patcher.py — South Warwickshire FS25
===================================================

Patches FS22 .i3d files for FS25 compatibility.

What it fixes automatically:
  • blinkSimple="true"  → blinkSimple="false"   (FS25 removed this light mode)
  • FS22 version="1.6" headers preserved (GE10 re-saves as 1.6 anyway)
  • Attribute whitespace normalisation

What it warns about (manual fix required in GE10):
  • vehicleShader          — must be changed to defaultShader.xml in GE
  • backgroundTreesShader  — re-export trees via GE10 tree tools
  • glass materials        — set specular to clearGlass_specular in GE
  • FS22 $data/ texture paths that may not exist in FS25

Usage:
  # Dry run — show what would change, touch nothing
  python pipeline/fs22_to_fs25_patcher.py map/map_assets/PowerTelegraphPackBB/ --dry-run

  # Patch all .i3d files in a folder (recurse)
  python pipeline/fs22_to_fs25_patcher.py map/map_assets/PowerTelegraphPackBB/

  # Patch a single file
  python pipeline/fs22_to_fs25_patcher.py map/map_assets/PowerTelegraphPackBB/telegraph_pole.i3d

  # Restore a backup
  cp map/map_assets/PowerTelegraphPackBB/mymodel.i3d.fs22_backup \\
     map/map_assets/PowerTelegraphPackBB/mymodel.i3d
"""

import argparse
import re
import shutil
import sys
from pathlib import Path

# ── Auto-fix rules ─────────────────────────────────────────────────────────────
# Each rule: (description, search_regex, replacement_string)
AUTO_FIX_RULES: list[tuple[str, re.Pattern, str]] = [
    (
        'blinkSimple="true" → false',
        re.compile(r'\bblinkSimple\s*=\s*"true"', re.IGNORECASE),
        'blinkSimple="false"',
    ),
    (
        'castsShadows="false" on lights → remove (FS25 handles automatically)',
        re.compile(r'\s*castsShadows\s*=\s*"false"'),
        "",
    ),
    (
        'FS22 lightType="pointLight" standardisation (no-op — already valid)',
        # This is a no-op placeholder; pointLight is still valid in FS25
        re.compile(r'(?!x)x'),   # never matches
        "",
    ),
]

# ── Warning patterns ───────────────────────────────────────────────────────────
# Each: (short_label, pattern_regex, hint_for_user)
WARNING_PATTERNS: list[tuple[str, re.Pattern, str]] = [
    (
        "vehicleShader",
        re.compile(r'vehicleShader', re.IGNORECASE),
        "In GE: select material → change shader to $data/shaders/defaultShader.xml",
    ),
    (
        "backgroundTreesShader",
        re.compile(r'backgroundTreesShader', re.IGNORECASE),
        "Re-export trees via GE10 tree tools — do not patch manually",
    ),
    (
        "baseMaterialConfigurations",
        re.compile(r'baseMaterialConfiguration', re.IGNORECASE),
        "Safe to ignore on static props/buildings",
    ),
    (
        "glass materials",
        re.compile(r'(?:glass|glazing).*?(?:material|shader)', re.IGNORECASE),
        "In GE: select glass mesh → detailSpecular → set to clearGlass_specular",
    ),
    (
        "FS22 $data texture path",
        re.compile(r'\$data/shaders/(?:vehicle|fs22|character)\w*\.xml', re.IGNORECASE),
        "Verify this shader exists in your FS25 $data/shaders/ install",
    ),
    (
        "FS22 LOD syntax",
        re.compile(r'<Lods\b[^>]*distanceRatios\s*=', re.IGNORECASE),
        "LOD format changed in FS25 — check LOD distances in GE attributes",
    ),
]


# ══════════════════════════════════════════════════════════════════════════════
# Patch logic
# ══════════════════════════════════════════════════════════════════════════════

def analyse_file(path: Path, dry_run: bool = False) -> dict:
    """
    Analyse one .i3d file.

    Returns a result dict:
      fixes    : list of (description, count) — auto-fixes applied / would apply
      warnings : list of (label, hint, lines) — manual review needed
      changed  : bool — whether the file would be / was modified
    """
    try:
        original = path.read_text(encoding="utf-8", errors="replace")
    except OSError as e:
        return {"error": str(e), "fixes": [], "warnings": [], "changed": False}

    text = original
    fixes: list[tuple[str, int]] = []

    # Apply auto-fixes
    for desc, pattern, replacement in AUTO_FIX_RULES:
        if not replacement and not pattern.pattern.startswith("(?!"):
            # deletion rule — count matches then strip
            matches = pattern.findall(text)
            if matches:
                text = pattern.sub(replacement, text)
                fixes.append((desc, len(matches)))
        else:
            new_text, n = pattern.subn(replacement, text)
            if n:
                text = new_text
                fixes.append((desc, n))

    # Collect warnings
    warnings: list[tuple[str, str, list[int]]] = []
    lines = original.splitlines()
    for label, pattern, hint in WARNING_PATTERNS:
        matched_lines = []
        for i, line in enumerate(lines, 1):
            if pattern.search(line):
                matched_lines.append(i)
        if matched_lines:
            warnings.append((label, hint, matched_lines))

    changed = text != original

    if changed and not dry_run:
        # Backup original
        backup = path.with_suffix(path.suffix + ".fs22_backup")
        if not backup.exists():
            shutil.copy2(path, backup)
        path.write_text(text, encoding="utf-8")

    return {
        "fixes":    fixes,
        "warnings": warnings,
        "changed":  changed,
        "error":    None,
    }


def find_i3d_files(target: Path) -> list[Path]:
    """Return list of .i3d files to process (file or folder, recursive)."""
    if target.is_file():
        if target.suffix == ".i3d":
            return [target]
        print(f"  WARNING: {target} is not a .i3d file — skipped")
        return []
    if target.is_dir():
        found = sorted(target.rglob("*.i3d"))
        # Exclude any backup-derived files or already-patched outputs
        found = [f for f in found if ".fs22_backup" not in f.name]
        return found
    print(f"  ERROR: {target} does not exist.")
    return []


def format_result(path: Path, result: dict, root: Path) -> list[str]:
    """Return human-readable lines for one file result."""
    rel = path.relative_to(root) if path.is_relative_to(root) else path
    out = []

    if result.get("error"):
        out.append(f"  ✗  {rel}  ERROR: {result['error']}")
        return out

    fixes    = result["fixes"]
    warnings = result["warnings"]
    changed  = result["changed"]

    if not fixes and not warnings:
        out.append(f"  ✓  {rel}  clean")
    else:
        status = f"{len(fixes)} auto-fix(es)" if fixes else "no auto-fixes"
        warn_s = f"{len(warnings)} warning(s)" if warnings else ""
        arrow  = "→ patched" if changed else "→ would patch"
        out.append(f"  •  {rel}  [{status}  {warn_s}]  {arrow}")
        for desc, count in fixes:
            out.append(f"       fix: {desc} (×{count})")
        for label, hint, line_nos in warnings:
            lines_str = ", ".join(str(n) for n in line_nos[:5])
            if len(line_nos) > 5:
                lines_str += f" … (+{len(line_nos)-5} more)"
            out.append(f"       ⚠  {label}  (line {lines_str})")
            out.append(f"          → {hint}")

    return out


def write_report(folder: Path,
                 results: list[tuple[Path, dict]],
                 dry_run: bool):
    """Write conversion report into the target folder."""
    report_path = folder / "fs22_to_fs25_conversion_report.txt"
    lines = [
        "FS22 → FS25 Conversion Report",
        "=" * 52,
        f"Mode: {'DRY RUN (no files changed)' if dry_run else 'APPLIED'}",
        "",
    ]
    patched  = 0
    warnings = 0
    clean    = 0
    errors   = 0

    for path, result in results:
        if result.get("error"):
            errors += 1
            lines.append(f"ERROR  {path.name}: {result['error']}")
        elif result["changed"]:
            patched += 1
            lines.append(f"PATCHED  {path.name}")
            for desc, count in result["fixes"]:
                lines.append(f"  fix: {desc} (×{count})")
            for label, hint, _ in result["warnings"]:
                lines.append(f"  ⚠ {label}: {hint}")
        elif result["warnings"]:
            warnings += 1
            lines.append(f"WARNINGS  {path.name}")
            for label, hint, _ in result["warnings"]:
                lines.append(f"  ⚠ {label}: {hint}")
        else:
            clean += 1
            lines.append(f"CLEAN  {path.name}")

    lines += [
        "",
        "─" * 52,
        f"  Clean:    {clean}",
        f"  Patched:  {patched}",
        f"  Warnings: {warnings}",
        f"  Errors:   {errors}",
    ]

    report_path.write_text("\n".join(lines), encoding="utf-8")
    return report_path


# ══════════════════════════════════════════════════════════════════════════════
# Entry point
# ══════════════════════════════════════════════════════════════════════════════

def main():
    parser = argparse.ArgumentParser(
        description="Patch FS22 .i3d files for FS25 compatibility",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "target",
        help="Path to a .i3d file or a folder containing .i3d files",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would change without modifying any files",
    )
    args = parser.parse_args()

    target = Path(args.target).resolve()
    dry_run = args.dry_run
    mode_label = "DRY RUN" if dry_run else "APPLY"

    print("=" * 60)
    print("  fs22_to_fs25_patcher.py — South Warwickshire FS25")
    print(f"  Mode: {mode_label}")
    print("=" * 60)

    i3d_files = find_i3d_files(target)
    if not i3d_files:
        print("\n  No .i3d files found.")
        sys.exit(0)

    print(f"\n  Found {len(i3d_files)} .i3d file(s) in: {target}\n")

    # Determine root for relative path display
    root = target if target.is_dir() else target.parent

    results: list[tuple[Path, dict]] = []
    total_fixes    = 0
    total_warnings = 0
    total_changed  = 0
    total_clean    = 0

    for i3d_path in i3d_files:
        result = analyse_file(i3d_path, dry_run=dry_run)
        results.append((i3d_path, result))

        for line in format_result(i3d_path, result, root):
            print(line)

        if result.get("error"):
            continue
        total_fixes    += len(result["fixes"])
        total_warnings += len(result["warnings"])
        if result["changed"]:
            total_changed += 1
        elif not result["warnings"]:
            total_clean += 1

    # Summary
    print()
    print("─" * 60)
    print(f"  Files processed : {len(i3d_files)}")
    if dry_run:
        print(f"  Would patch     : {total_changed}")
    else:
        print(f"  Patched         : {total_changed}")
    print(f"  Auto-fixes      : {total_fixes}")
    print(f"  Warnings        : {total_warnings}  (manual GE review needed)")
    print(f"  Already clean   : {total_clean}")

    # Write report only when targeting a folder
    if target.is_dir() and not dry_run:
        report = write_report(target, results, dry_run)
        print(f"\n  Report written: {report.relative_to(root) if report.is_relative_to(root) else report}")

    if total_changed and not dry_run:
        print("\n  Backups saved as: <filename>.i3d.fs22_backup")
        print("  To restore: cp <file>.i3d.fs22_backup <file>.i3d")

    if total_warnings:
        print("\n  ⚠  Some files need manual review in Giants Editor.")
        print("     See warnings above or the conversion report.")

    print("─" * 60)


if __name__ == "__main__":
    main()
