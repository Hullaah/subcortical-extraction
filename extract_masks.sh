#!/usr/bin/env bash
. common.sh

MRI_INPUT_DIR=nii/mri
PARALLEL_JOBS=3
export PARALLEL_JOBS

find "$MRI_INPUT_DIR" \
    -type f \
    -name "*.nii.gz" \
| parallel -j "$PARALLEL_JOBS" ./extract-masks-one.sh {}

echo "Mask extraction complete."
