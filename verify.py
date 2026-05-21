#!/usr/bin/env python3
import subprocess
import sys

if len(sys.argv) != 2:
    raise SystemExit(f"Usage: {sys.argv[0]} <path/to/volume.nii.gz>")

seg = sys.argv[1]


label_mappings = {
    10: "Left-Thalamus",
    11: "Left-Caudate",
    12: "Left-Putamen",
    13: "Left-Pallidum",
    16: "Brain-Stem",
    17: "Left-Hippocampus",
    18: "Left-Amygdala",
    26: "Left-Accumbens",
    49: "Right-Thalamus",
    50: "Right-Caudate",
    51: "Right-Putamen",
    52: "Right-Pallidum",
    53: "Right-Hippocampus",
    54: "Right-Amygdala",
    58: "Right-Accumbens",
}

print("Subcortical structures extracted\n")
for label, name in sorted(label_mappings.items()):
    check = subprocess.run(
        ["fslstats", seg, "-l", str(label - 0.5), "-u",
         str(label + 0.5), "-V"],
        capture_output=True, text=True
    )
    # print(check.stdout if check.stdout != "" else check.stderr)
    nvoxels = int(check.stdout.strip().split()[0])
    status = f"{nvoxels:>5d} voxels" if nvoxels > 0 else "NOT FOUND"
    print(f"Label {label:2d}: {name:<25} {status}")
