#!/usr/bin/env python3
"""
make_road_variants.py
=====================
Creates road i3d variants from the working maps4fs base mesh.
Rewidths vertex pairs and swaps textures.
Also appends gap-fill segments from the updated OSM.

  TO CHANGE WIDTH:   edit target_width in VARIANTS
  TO CHANGE TEXTURE: edit texture_src / texture_file in VARIANTS
  TO ADD A GAP FILL: add way IDs to GAP_FILL_WAYS in a variant
"""

import re, math, os, shutil, xml.etree.ElementTree as ET
from pathlib import Path
from PIL import Image

REPO = Path(__file__).resolve().parent.parent

SOURCE_I3D = REPO / "map/assets/roads/asphalt-white/roads_asphalt-white.i3d"
OSM_FILE   = REPO / "data/south_warwickshire_enriched.osm"
DEM_PATH   = REPO / "map/map/data/dem.png"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  VARIANTS — edit here
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
VARIANTS = [
    {
        "name":           "sw_roads_main",
        "out_folder":     "map/assets/roads/sw-roads-main",
        "target_width":   14.0,
        "texture_src":    "map/assets/roads/asphalt-white-6m/lane_diffuse.dds",
        "texture_file":   "lane_diffuse.dds",
        "gap_fill_ways":  [
            # Tysoe Road chain (SW → NE) — all action=modify primary ways from updated OSM
            "141196914", "141196922", "192025147", "192025146",
            "141196919", "485536367", "-66239", "-66245", "485536368",
            "308902753", "141196920", "141196921", "308902720",
            "35967764", "285406335", "308902734", "308902735",
            "53053479", "53053480", "58008801", "224385878",
            # Other modified primary roads across the map
            "26436851", "26436866", "141233947", "141626971",
            "25609276", "58008823", "281147142",
        ],
    },
    {
        "name":           "sw_roads_service",
        "out_folder":     "map/assets/roads/sw-roads-service",
        "target_width":   4.0,
        "texture_src":    "references/service_road_textures/Road_pbjhxep0_2K_BaseColor.jpg",
        "texture_file":   "Road_pbjhxep0_2K_BaseColor.jpg",
        "gap_fill_ways":  [
            # Service lanes with JOSM-local nodes (newly drawn by user)
            "696105558",   # Kirby Farm lane → Tysoe Road junction
            "243778698",   # eastern service road (action=modify, local nodes)
            "249593006",   # central service road (action=modify, local nodes)
            "249725037",   # western service road (action=modify, local nodes)
        ],
    },
]
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

MAP_CENTRE_LAT = 52.089387
MAP_CENTRE_LON = -1.532290
M_PER_DEG_LAT  = 111320.0
M_PER_DEG_LON  = 111320.0 * math.cos(math.radians(MAP_CENTRE_LAT))
MAP_HALF       = 2048.0
HEIGHT_SCALE   = 255.0
DEM_MAX        = 65535.0
UV_WRAP        = 16.0

_dem  = Image.open(str(DEM_PATH))
_dw, _dh = _dem.size
_pix  = _dem.load()

def sample_height(x, z):
    px0 = max(0, min(_dw-1, int(x + MAP_HALF)));   px1 = max(0, min(_dw-1, px0+1))
    pz0 = max(0, min(_dh-1, int(z + MAP_HALF)));   pz1 = max(0, min(_dh-1, pz0+1))
    fx  = max(0., min(1., x + MAP_HALF - int(x + MAP_HALF)))
    fz  = max(0., min(1., z + MAP_HALF - int(z + MAP_HALF)))
    raw = (_pix[px0,pz0]*(1-fx)*(1-fz) + _pix[px1,pz0]*fx*(1-fz) +
           _pix[px0,pz1]*(1-fx)*fz     + _pix[px1,pz1]*fx*fz)
    return raw * (HEIGHT_SCALE / DEM_MAX)

def lonlat_to_fs25(lon, lat):
    x =  (lon - MAP_CENTRE_LON) * M_PER_DEG_LON
    z = -(lat - MAP_CENTRE_LAT) * M_PER_DEG_LAT
    return x, sample_height(x, z), z

def perp_xz(dx, dz):
    ln = math.sqrt(dx*dx + dz*dz)
    if ln < 1e-9: return 0., 0.
    return -dz/ln, dx/ln


def rewidth_positions(pos_strings, target_width):
    """Rescale alternating L/R vertex pairs to target_width."""
    half = target_width / 2.
    out  = []
    for i in range(0, len(pos_strings) - 1, 2):
        x0,y0,z0 = (float(v) for v in pos_strings[i].split())
        x1,y1,z1 = (float(v) for v in pos_strings[i+1].split())
        mx=(x0+x1)/2.; my=(y0+y1)/2.; mz=(z0+z1)/2.
        dx=x0-mx; dz=z0-mz
        d=math.sqrt(dx*dx+dz*dz)
        if d < 1e-6:
            out += [pos_strings[i], pos_strings[i+1]]; continue
        nx=dx/d*half; nz=dz/d*half
        out.append(f"{mx+nx:.6f} {my:.6f} {mz+nz:.6f}")
        out.append(f"{mx-nx:.6f} {my:.6f} {mz-nz:.6f}")
    if len(pos_strings) % 2 == 1:
        out.append(pos_strings[-1])
    return out


def gap_fill_geometry(way_ids, width):
    """Generate extra vertices+tris for OSM ways not in the maps4fs mesh."""
    tree = ET.parse(str(OSM_FILE))
    root = tree.getroot()
    node_coords = {n.get('id'): (float(n.get('lat')), float(n.get('lon')))
                   for n in root.findall('node')}

    all_verts, all_tris = [], []
    base = 1  # 1-based; caller will offset by existing vert count

    for wid in way_ids:
        way = root.find(f"way[@id='{wid}']")
        if way is None:
            print(f"  WARNING: way {wid} not found in OSM"); continue

        nds  = [nd.get('ref') for nd in way.findall('nd')]
        pts  = [lonlat_to_fs25(node_coords[n][1], node_coords[n][0])
                for n in nds if n in node_coords]
        if len(pts) < 2:
            continue

        half = width / 2.
        n    = len(pts)
        vL, vR = [], []

        for i, (x,y,z) in enumerate(pts):
            if   i == 0:    dx=pts[1][0]-pts[0][0]; dz=pts[1][2]-pts[0][2]
            elif i == n-1:  dx=pts[-1][0]-pts[-2][0]; dz=pts[-1][2]-pts[-2][2]
            else:           dx=pts[i+1][0]-pts[i-1][0]; dz=pts[i+1][2]-pts[i-1][2]
            px,pz = perp_xz(dx, dz)
            vL.append((x+px*half, y, z+pz*half))
            vR.append((x-px*half, y, z-pz*half))

        dist=0.; uv_v=[0.]
        for i in range(1, n):
            sl = math.sqrt((pts[i][0]-pts[i-1][0])**2+(pts[i][2]-pts[i-1][2])**2)
            dist += sl/width; uv_v.append(dist % UV_WRAP)

        seg_verts = []
        for i in range(n):
            lx,ly,lz = vL[i]; rx,ry,rz = vR[i]
            # normal
            if   i==0:    ax=pts[1][0]-pts[0][0];ay=pts[1][1]-pts[0][1];az=pts[1][2]-pts[0][2]
            elif i==n-1:  ax=pts[-1][0]-pts[-2][0];ay=pts[-1][1]-pts[-2][1];az=pts[-1][2]-pts[-2][2]
            else:         ax=pts[i+1][0]-pts[i-1][0];ay=pts[i+1][1]-pts[i-1][1];az=pts[i+1][2]-pts[i-1][2]
            bx=rx-lx;by=ry-ly;bz=rz-lz
            nx=ay*bz-az*by;ny=az*bx-ax*bz;nz=ax*by-ay*bx
            ln=math.sqrt(nx*nx+ny*ny+nz*nz)
            if ln>1e-9: nx/=ln;ny/=ln;nz/=ln
            else: nx,ny,nz=0.,1.,0.
            seg_verts.append(((lx,ly,lz),(nx,ny,nz),(0.,uv_v[i])))
            seg_verts.append(((rx,ry,rz),(nx,ny,nz),(1.,uv_v[i])))

        seg_start = len(all_verts)
        all_verts += seg_verts

        # CORRECT winding: (BL,TL,TR) and (BL,TR,BR) → normals UP
        for i in range(n-1):
            BL = seg_start + i*2 + 1        # 1-based
            BR = seg_start + i*2 + 2
            TL = seg_start + (i+1)*2 + 1
            TR = seg_start + (i+1)*2 + 2
            all_tris.append((BL, TL, TR))
            all_tris.append((BL, TR, BR))

        print(f"  Gap fill way {wid}: {n} nodes → {len(seg_verts)//2} cross-sections")

    return all_verts, all_tris


def make_variant(v):
    name     = v["name"]
    out_dir  = REPO / v["out_folder"]
    tw       = v["target_width"]
    tex_src  = REPO / v["texture_src"]
    tex_file = v["texture_file"]
    gaps     = v.get("gap_fill_ways", [])

    out_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(str(tex_src), str(out_dir / tex_file))

    with open(str(SOURCE_I3D), encoding="iso-8859-1") as f:
        content = f.read()

    # --- Rewidth all position attributes ---
    pos_matches = list(re.finditer(r'p="([^"]+)"', content))
    positions   = [m.group(1) for m in pos_matches]
    print(f"  Verts: {len(positions)}, rewidthing 16m → {tw}m")
    new_positions = rewidth_positions(positions, tw)

    parts   = re.split(r'p="[^"]+"', content)
    rebuilt = parts[0]
    for np_, part in zip(new_positions, parts[1:]):
        rebuilt += f'p="{np_}"' + part
    content = rebuilt

    # --- Rename ALL occurrences of roads_asphalt-white → variant name ---
    content = content.replace('name="roads_asphalt-white"',
                              f'name="{name}"')
    content = content.replace('name="roads_asphalt-white_material"',
                              f'name="{name}_material"')
    content = content.replace('name="roads_asphalt-white_shape"',
                              f'name="{name}_shape"')
    content = content.replace('<i3D name="roads_asphalt-white"',
                              f'<i3D name="{name}"')

    # --- Swap texture filename ---
    content = re.sub(r'filename="[^"]*\.(dds|jpg|png)"',
                     f'filename="{tex_file}"', content, count=1)

    # --- Append gap-fill geometry if any ---
    if gaps:
        existing_vcount = len(positions)
        gap_verts, gap_tris = gap_fill_geometry(gaps, tw)

        if gap_verts:
            # Build vertex XML lines
            new_v_lines = ""
            for (pos, norm, uv) in gap_verts:
                new_v_lines += (
                    f'        <v p="{pos[0]:.6f} {pos[1]:.6f} {pos[2]:.6f}"'
                    f' n="{norm[0]:.6f} {norm[1]:.6f} {norm[2]:.6f}"'
                    f' t0="{uv[0]:.6f} {uv[1]:.6f}" />\n'
                )

            # Build triangle XML lines (offset by existing vert count, 0-based)
            new_t_lines = ""
            for a,b,c in gap_tris:
                ai = existing_vcount + a - 1
                bi = existing_vcount + b - 1
                ci = existing_vcount + c - 1
                new_t_lines += f'        <t vi="{ai} {bi} {ci}" />\n'

            # Update vertex count
            old_vc = re.search(r'<Vertices count="(\d+)"', content)
            if old_vc:
                new_vc = int(old_vc.group(1)) + len(gap_verts)
                content = content.replace(old_vc.group(0),
                                          f'<Vertices count="{new_vc}"', 1)

            # Update triangle count
            old_tc = re.search(r'<Triangles count="(\d+)"', content)
            if old_tc:
                new_tc = int(old_tc.group(1)) + len(gap_tris)
                content = content.replace(old_tc.group(0),
                                          f'<Triangles count="{new_tc}"', 1)

            # Insert before </Vertices>
            content = content.replace('      </Vertices>',
                                      new_v_lines + '      </Vertices>', 1)
            # Insert before </Triangles>
            content = content.replace('      </Triangles>',
                                      new_t_lines + '      </Triangles>', 1)

            print(f"  Added {len(gap_verts)} gap verts, {len(gap_tris)} gap tris")

    out_path = out_dir / f"{name}.i3d"
    with open(str(out_path), "w", encoding="iso-8859-1") as f:
        f.write(content)

    kb = out_path.stat().st_size // 1024
    print(f"  → {out_path}  ({kb}KB)")
    return out_path


def main():
    for v in VARIANTS:
        print(f"\n{v['name']}  width={v['target_width']}m  tex={v['texture_file']}")
        make_variant(v)
    print("\nDone.")


if __name__ == "__main__":
    main()
