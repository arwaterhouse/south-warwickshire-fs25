#!/usr/bin/env python3
"""Auto-generated restore script — restores grass installation from backup 20260321_145330."""
import os, shutil

BACKUP_I3D = '/sessions/adoring-brave-cray/mnt/south-warwickshire-fs25/outputs/grass_backup/20260321_145330/map.i3d'
MAP_I3D    = '/sessions/adoring-brave-cray/mnt/south-warwickshire-fs25/map/map/map.i3d'
GRASS_DEST = '/sessions/adoring-brave-cray/mnt/south-warwickshire-fs25/map/map/foliage/grass'

# Restore map.i3d
if os.path.isfile(BACKUP_I3D):
    shutil.copy2(BACKUP_I3D, MAP_I3D)
    print(f"Restored map.i3d from backup.")
else:
    print(f"WARNING: backup map.i3d not found at {BACKUP_I3D}")

# Delete installed grass files
if os.path.isdir(GRASS_DEST):
    shutil.rmtree(GRASS_DEST)
    print(f"Deleted {GRASS_DEST}")
else:
    print(f"{GRASS_DEST} does not exist — nothing to delete.")

print("Restore complete.")
