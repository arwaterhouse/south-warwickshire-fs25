#!/usr/bin/env python3
"""
build_road_meshes.py  —  FS25 South Warwickshire road surface meshes
=======================================================================
Generates one i3d mesh file per road category from fs25_roads.geojson.

OUTPUT FILES (in map/assets/roads/):
  main_roads/roads_main.i3d       — primary, secondary, tertiary (10m)
  service_roads/roads_service.i3d — service roads (3m)
  minor_roads/roads_minor.i3d     — residential, unclassified (4–4.5m)
  farm_tracks/roads_tracks.i3d    — track, bridleway (3–3.5m)

EASY CUSTOMISATION
  ─ Widths  : edit ROAD_GROUPS below (width_override overrides GeoJSON width_m)
  ─ Textures: edit TEXTURE_FILE in each group entry
  ─ Add type: add a new entry in ROAD_GROUPS
"""

import json, math, os, shutil
from pathlib import Path
from PIL import Image

# ═══════════════════════════════════════════════════════════════════════════════
#  USER SETTINGS  ─  edit these to change widths / textures
# ═══════════════════════════════════════════════════════════════════════════════

ROAD_GROUPS = [
    {
        "name":           "roads_main",
        "label":          "Main roads (primary / secondary / tertiary)",
        "out_folder":     "map/assets/roads/main_roads",
        "texture_src":    "map/assets/roads/asphalt-white-6m/lane_diffuse.dds",
        "texture_file":   "lane_diffuse.dds",
        "highway_types":  {"primary", "secondary", "tertiary"},
        "width_override": 10.0,    # set to None to use per-road width_m from GeoJSON
    },
    {
        "name":           "roads_service",
        "label":          "Service roads",
        "out_folder":     "map/assets/roads/service_roads",
        "texture_src":    "map/assets/roads/asphalt-white-6m/lane_diffuse.dds",
        "texture_file":   "lane_diffuse.dds",
        "highway_types":  {"service"},
        "width_override": 3.0,
    },
    {
        "name":           "roads_minor",
        "label":          "Minor roads (residential / unclassified)",
        "out_folder":     "map/assets/roads/minor_roads",
        "texture_src":    "map/assets/roads/asphalt-white-6m/lane_diffuse.dds",
        "texture_file":   "lane_diffuse.dds",
        "highway_types":  {"residential", "unclassified"},
        "width_override": None,    # use per-road width_m (4m / 4.5m)
    },
    {
        "name":           "roads_tracks",
        "label":          "Farm tracks / bridleways",
        "out_folder":     "map/assets/roads/farm_tracks",
        "texture_src":    "map/assets/roads/gravel-bright/gravel-bright.dds",
        "texture_file":   "gravel-bright.dds",
        "highway_types":  {"track", "bridleway"},
        "width_override": None,    # use per-road width_m (3.5m / 2.5m)
    },
]

# ═══════════════════════════════════════════════════════════════════════════════
#  MAP / DEM SETTINGS  ─  should not need changing
# ═══════════════════════════════════════════════════════════════════════════════

REPO_ROOT      = Path(__file__).resolve().parent.parent
GEOJSON_PATH   = REPO_ROOT / "outputs" / "fs25_roads.geojson"
DEM_PATH       = REPO_ROOT / "map" / "map" / "data" / "dem.png"

MAP_CENTRE_LAT = 52.089387
MAP_CENTRE_LON = -1.532290
M_PER_DEG_LAT  = 111320.0
M_PER_DEG_LON  = 111320.0 * math.cos(math.radians(MAP_CENTRE_LAT))
MAP_HALF_SIZE  = 2048.0
HEIGHT_SCALE   = 255.0
DEM_MAX_VAL    = 65535.0
UV_WRAP        = 16.0          # keep well under GE's 32-tile cap

# ── DEM setup ─────────────────────────────────────────────────────────────────

_dem  = Image.open(str(DEM_PATH))
_dw, _dh = _dem.size
_pix  = _dem.load()

def sample_height(x: float, z: float) -> float:
    """Terrain height in metres at FS25 world coords (x, z)."""
    px = x + MAP_HALF_SIZE
    pz = z + MAP_HALF_SIZE
    px0 = max(0, min(_dw-1, int(px)));   px1 = max(0, min(_dw-1, px0+1))
    pz0 = max(0, min(_dh-1, int(pz)));   pz1 = max(0, min(_dh-1, pz0+1))
    fx  = max(0.0, min(1.0, px - int(px)))
    fz  = max(0.0, min(1.0, pz - int(pz)))
    raw = (_pix[px0,pz0]*(1-fx)*(1-fz) + _pix[px1,pz0]*fx*(1-fz) +
           _pix[px0,pz1]*(1-fx)*fz     + _pix[px1,pz1]*fx*fz)
    return raw * (HEIGHT_SCALE / DEM_MAX_VAL)

def lonlat_to_fs25(lon, lat):
    x =  (lon - MAP_CENTRE_LON) * M_PER_DEG_LON
    z = -(lat - MAP_CENTRE_LAT) * M_PER_DEG_LAT
    return x, sample_height(x, z), z

def perp_xz(dx, dz):
    """Unit perpendicular in XZ plane."""
    ln = math.sqrt(dx*dx + dz*dz)
    if ln < 1e-9: return 0.0, 0.0
    return -dz/ln, dx/ln

# ── Mesh builder ──────────────────────────────────────────────────────────────

def build_mesh(features, width_override):
    """Return (vertices, normals, uvs, faces) with correct UPWARD-facing winding."""
    vertices, normals, uvs, faces = [], [], [], []
    base = 1   # 1-based; converted to 0-based when writing i3d

    for feat in features:
        geom  = feat["geometry"]
        props = feat["properties"]
        w     = width_override if width_override else props.get("width_m", 4.0)
        half  = w / 2.0

        raw_segs = (geom["coordinates"]
                    if geom["type"] == "MultiLineString"
                    else [geom["coordinates"]])

        for seg in raw_segs:
            if len(seg) < 2:
                continue
            pts = [lonlat_to_fs25(c[0], c[1]) for c in seg]
            n   = len(pts)

            vL, vR = [], []
            for i, (x, y, z) in enumerate(pts):
                if   i == 0:     dx=pts[1][0]-pts[0][0]; dz=pts[1][2]-pts[0][2]
                elif i == n-1:   dx=pts[-1][0]-pts[-2][0]; dz=pts[-1][2]-pts[-2][2]
                else:            dx=pts[i+1][0]-pts[i-1][0]; dz=pts[i+1][2]-pts[i-1][2]
                px, pz = perp_xz(dx, dz)
                vL.append((x + px*half, y, z + pz*half))
                vR.append((x - px*half, y, z - pz*half))

            # UV v tiled along road length, wrapped to avoid GE's 32-tile cap
            dist  = 0.0
            uv_v  = [0.0]
            for i in range(1, n):
                seg_l = math.sqrt((pts[i][0]-pts[i-1][0])**2 + (pts[i][2]-pts[i-1][2])**2)
                dist += seg_l / w
                uv_v.append(dist % UV_WRAP)

            for i in range(n):
                lx,ly,lz = vL[i];  rx,ry,rz = vR[i]
                vertices += [(lx,ly,lz), (rx,ry,rz)]
                uvs      += [(0.0, uv_v[i]), (1.0, uv_v[i])]

                # Per-vertex normal from road plane
                if   i == 0:    ax=pts[1][0]-pts[0][0]; ay=pts[1][1]-pts[0][1]; az=pts[1][2]-pts[0][2]
                elif i == n-1:  ax=pts[-1][0]-pts[-2][0]; ay=pts[-1][1]-pts[-2][1]; az=pts[-1][2]-pts[-2][2]
                else:           ax=pts[i+1][0]-pts[i-1][0]; ay=pts[i+1][1]-pts[i-1][1]; az=pts[i+1][2]-pts[i-1][2]
                bx=rx-lx; by=ry-ly; bz=rz-lz
                nx=ay*bz-az*by; ny=az*bx-ax*bz; nz=ax*by-ay*bx
                ln=math.sqrt(nx*nx+ny*ny+nz*nz)
                if ln > 1e-9: nx/=ln; ny/=ln; nz/=ln
                else: nx,ny,nz = 0.0, 1.0, 0.0
                normals += [(nx,ny,nz), (nx,ny,nz)]

            # ── FACES with CORRECT UPWARD-FACING winding ──────────────────
            # Quad layout:  TL──TR   (TL/TR = next point, BL/BR = current)
            #               │  / │
            #               BL──BR
            # CCW from above (+Y down) = front face = UP
            #   Triangle 1: BL → TL → TR   (upper-left tri)
            #   Triangle 2: BL → TR → BR   (lower-right tri)
            for i in range(n-1):
                BL = base + i*2          # left  edge, current point
                BR = base + i*2 + 1      # right edge, current point
                TL = base + (i+1)*2      # left  edge, next point
                TR = base + (i+1)*2 + 1  # right edge, next point
                faces.append((BL, TL, TR))   # ← correct winding: normal UP
                faces.append((BL, TR, BR))   # ← correct winding: normal UP

            base += n * 2

    return vertices, normals, uvs, faces


# ── i3d writer ────────────────────────────────────────────────────────────────

def write_i3d(group, vertices, normals, uvs, faces):
    out_dir  = Path(group["out_folder"])
    out_dir.mkdir(parents=True, exist_ok=True)

    # Copy texture
    tex_dst = out_dir / group["texture_file"]
    if not tex_dst.exists():
        shutil.copy2(group["texture_src"], str(tex_dst))

    # Bounding volume
    xs = [v[0] for v in vertices]; ys = [v[1] for v in vertices]; zs = [v[2] for v in vertices]
    cx=(min(xs)+max(xs))/2; cy=(min(ys)+max(ys))/2; cz=(min(zs)+max(zs))/2
    bv_r = max(math.sqrt((v[0]-cx)**2+(v[1]-cy)**2+(v[2]-cz)**2) for v in vertices)

    name    = group["name"]
    tex     = group["texture_file"]
    i3d_path = out_dir / f"{name}.i3d"

    with open(str(i3d_path), "w", encoding="iso-8859-1") as f:
        f.write("<?xml version='1.0' encoding='iso-8859-1'?>\n")
        f.write(f'<i3D xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'
                f' name="{name}" version="1.6"'
                f' xsi:noNamespaceSchemaLocation="http://i3d.giants.ch/schema/i3d-1.6.xsd">\n')
        f.write(f'  <Asset>\n')
        f.write(f'    <Export program="build_road_meshes.py" version="3.0" date="2026-03-18" />\n')
        f.write(f'  </Asset>\n')
        f.write(f'  <Files>\n')
        f.write(f'    <File fileId="1" filename="{tex}" relativePath="true" />\n')
        f.write(f'  </Files>\n')
        f.write(f'  <Materials>\n')
        f.write(f'    <Material materialId="1" name="{name}_mat"'
                f' diffuseColor="1 1 1 1" specularColor="0.3 0.3 0.3">\n')
        f.write(f'      <Texture fileId="1" />\n')
        f.write(f'    </Material>\n')
        f.write(f'  </Materials>\n')
        f.write(f'  <Shapes>\n')
        f.write(f'    <IndexedTriangleSet name="{name}_shape" shapeId="1"'
                f' bvCenter="{cx:.6f} {cy:.6f} {cz:.6f}"'
                f' bvRadius="{bv_r:.6f}" count="{len(faces)}">\n')
        f.write(f'      <Vertices count="{len(vertices)}" normal="true" uv0="true">\n')
        for i, (x,y,z) in enumerate(vertices):
            nx,ny,nz = normals[i]
            u, v     = uvs[i]
            f.write(f'        <v p="{x:.6f} {y:.6f} {z:.6f}"'
                    f' n="{nx:.6f} {ny:.6f} {nz:.6f}"'
                    f' t0="{u:.6f} {v:.6f}" />\n')
        f.write(f'      </Vertices>\n')
        f.write(f'      <Triangles count="{len(faces)}">\n')
        for a,b,c in faces:
            f.write(f'        <t vi="{a-1} {b-1} {c-1}" />\n')  # 0-based
        f.write(f'      </Triangles>\n')
        f.write(f'    </IndexedTriangleSet>\n')
        f.write(f'  </Shapes>\n')
        f.write(f'  <Scene>\n')
        f.write(f'    <TransformGroup name="{name}" nodeId="1">\n')
        f.write(f'      <Shape name="{name}_shape" nodeId="2" shapeId="1"'
                f' static="true" compound="false" collision="true" materialIds="1" />\n')
        f.write(f'    </TransformGroup>\n')
        f.write(f'  </Scene>\n')
        f.write(f'</i3D>\n')

    return i3d_path, len(vertices), len(faces), (cx,cy,cz), bv_r


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    print("Loading GeoJSON…")
    with open(str(GEOJSON_PATH)) as f:
        all_features = json.load(f)["features"]

    for group in ROAD_GROUPS:
        hw_set   = group["highway_types"]
        feats    = [f for f in all_features if f["properties"].get("highway") in hw_set]
        if not feats:
            print(f"  SKIP {group['name']} — no matching features")
            continue

        verts, norms, uvs, faces = build_mesh(feats, group["width_override"])
        i3d_path, nv, nf, bvc, bvr = write_i3d(group, verts, norms, uvs, faces)

        ys = [v[1] for v in verts]
        print(f"\n{group['label']}")
        print(f"  Features  : {len(feats)}")
        print(f"  Vertices  : {nv},  Triangles: {nf}")
        print(f"  Y range   : {min(ys):.1f}m – {max(ys):.1f}m")
        print(f"  bvCenter  : {bvc[0]:.1f} {bvc[1]:.1f} {bvc[2]:.1f}")
        print(f"  → {i3d_path}")

    print("\nAll road meshes written.")


if __name__ == "__main__":
    main()
