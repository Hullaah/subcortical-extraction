#!/usr/bin/env python3
"""
compute_volumes.py — Compute volumes (mm^3) of segmented subcortical
structures from binary masks produced by extract-masks-one.sh.

Expected layout:
    nii/masks/<SUBJECT>/<SUBJECT>_<STRUCTURE>_mask.nii.gz

Usage:
    python compute_volumes.py [--masks-dir nii/masks] [--out subcortical_volumes.xlsx]
"""

import argparse
import sys
from pathlib import Path

import nibabel as nib
import numpy as np
import pandas as pd


def parse_structure(mask_path: Path, subject: str) -> str:
    """Recover STRUCTURE from '<SUBJECT>_<STRUCTURE>_mask.nii.gz'."""
    stem = mask_path.name
    if stem.endswith(".nii.gz"):
        stem = stem[: -len(".nii.gz")]
    prefix = f"{subject}_"
    suffix = "_mask"
    if not stem.startswith(prefix) or not stem.endswith(suffix):
        raise ValueError(f"Unexpected mask filename: {mask_path.name}")
    return stem[len(prefix) : -len(suffix)]


def compute_volume(mask_path: Path) -> tuple[int, float, float]:
    """Return (voxel_count, voxel_volume_mm3, total_volume_mm3) for a binary mask."""
    img = nib.load(str(mask_path))
    data = img.get_fdata()
    voxel_count = int(np.count_nonzero(data))
    zooms = img.header.get_zooms()[:3]
    voxel_volume = float(np.prod(zooms))
    return voxel_count, voxel_volume, voxel_count * voxel_volume


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--masks-dir", default="nii/masks", help="Root directory of extracted masks")
    parser.add_argument("--out", default="subcortical_volumes.xlsx", help="Output .xlsx path")
    parser.add_argument(
        "--mask",
        help=(
            "Path to a single mask .nii.gz. If given, just prints its voxel count "
            "and volume to the terminal and exits — no Excel file is written. "
            "Use this to cross-check one file against 'fslstats <mask> -V' before "
            "trusting the batch run."
        ),
    )
    args = parser.parse_args()

    if args.mask:
        mask_path = Path(args.mask)
        if not mask_path.is_file():
            print(f"Error: file not found: {mask_path}", file=sys.stderr)
            sys.exit(1)

        voxel_count, voxel_volume, total_volume = compute_volume(mask_path)
        print(f"File:             {mask_path}")
        print(f"Voxel count:      {voxel_count}")
        print(f"Voxel volume:     {voxel_volume:.6f} mm^3")
        print(f"Total volume:     {total_volume:.4f} mm^3")
        print()
        print(f"Cross-check with: fslstats {mask_path} -V")
        print("(fslstats -V prints '<voxel_count> <volume_mm3>' — both numbers should match the above)")
        return

    masks_root = Path(args.masks_dir)
    if not masks_root.is_dir():
        print(f"Error: masks directory not found: {masks_root}", file=sys.stderr)
        sys.exit(1)

    records = []
    failures = []

    subject_dirs = sorted(p for p in masks_root.iterdir() if p.is_dir())
    if not subject_dirs:
        print(f"Error: no subject subdirectories found under {masks_root}", file=sys.stderr)
        sys.exit(1)

    for subject_dir in subject_dirs:
        subject = subject_dir.name
        mask_files = sorted(subject_dir.glob(f"{subject}_*_mask.nii.gz"))

        if not mask_files:
            failures.append((subject, "<all>", "no mask files found"))
            continue

        for mask_path in mask_files:
            try:
                structure = parse_structure(mask_path, subject)
                voxel_count, voxel_volume, total_volume = compute_volume(mask_path)

                if voxel_count == 0:
                    failures.append((subject, mask_path.name, "empty mask (0 voxels)"))

                records.append(
                    {
                        "Subject": subject,
                        "Structure": structure,
                        "VoxelCount": voxel_count,
                        "VoxelVolume_mm3": voxel_volume,
                        "Volume_mm3": total_volume,
                    }
                )
            except Exception as exc:
                failures.append((subject, mask_path.name, str(exc)))

    if not records:
        print("Error: no volumes could be computed.", file=sys.stderr)
        sys.exit(1)

    long_df = pd.DataFrame.from_records(records).sort_values(["Subject", "Structure"])

    wide_df = long_df.pivot(index="Subject", columns="Structure", values="Volume_mm3")
    wide_df = wide_df.reset_index()

    with pd.ExcelWriter(args.out, engine="openpyxl") as writer:
        wide_df.to_excel(writer, sheet_name="Volumes (wide)", index=False)
        long_df.to_excel(writer, sheet_name="Volumes (long)", index=False)
        if failures:
            fail_df = pd.DataFrame(failures, columns=["Subject", "File", "Issue"])
            fail_df.to_excel(writer, sheet_name="Issues", index=False)

    print(f"Processed {len(subject_dirs)} subjects, {len(records)} structure volumes.")
    if failures:
        print(f"{len(failures)} issues flagged — see the 'Issues' sheet in {args.out}")
    print(f"Wrote: {args.out}")


if __name__ == "__main__":
    main()
