#!/usr/bin/env bash
# extract-masks-one.sh — Extract binary masks for a single subject
. common.sh

SEG_OUTPUT_DIR=nii/subcortical_seg
MASK_OUTPUT_DIR=nii/masks

NII_FILE="$1"

if [ -z "$NII_FILE" ]; then
    echo "Usage: $0 <path/to/original/volume.nii.gz>"
    exit 1
fi

if [ ! -f "$NII_FILE" ]; then
    echo "Error: file not found: $NII_FILE"
    exit 1
fi

BASENAME="$(basename "$NII_FILE" .nii.gz)"
SUBJECT_OUT_DIR="$SEG_OUTPUT_DIR/$BASENAME"
SUBJECT_MASK_DIR="$MASK_OUTPUT_DIR/$BASENAME"

if [ ! -d "$SUBJECT_OUT_DIR" ]; then
    echo "Error: no segmentation output found for $BASENAME"
    echo "Expected directory: $SUBJECT_OUT_DIR"
    echo "Run segment-one.sh first."
    exit 1
fi

mkdir -p "$SUBJECT_MASK_DIR"

echo "Extracting masks for: $BASENAME"
echo "Mask output dir: $SUBJECT_MASK_DIR"
echo ""

FAILED=()

while read -r CORR_FILE; do
    CORR_BASENAME="$(basename "$CORR_FILE" .nii.gz)"
    WITHOUT_PREFIX="${CORR_BASENAME#${BASENAME}_}"
    STRUCTURE="${WITHOUT_PREFIX%%-*}"

    MASK_OUT="$SUBJECT_MASK_DIR/${BASENAME}_${STRUCTURE}_mask.nii.gz"

    if [ -f "$MASK_OUT" ]; then
        echo "Skipping $STRUCTURE — mask already exists"
        continue
    fi

    echo "Generating mask: $STRUCTURE..."

    fslmaths "$CORR_FILE" -bin "$MASK_OUT"

    if [ $? -ne 0 ]; then
        echo "  FAILED"
        FAILED+=("$STRUCTURE")
    else
        echo "  Done -> $MASK_OUT"
    fi

done < <(find "$SUBJECT_OUT_DIR" -type f -name "*_corr.nii.gz")

echo ""
if [ ${#FAILED[@]} -eq 0 ]; then
    echo "All masks extracted successfully."
    echo ""
    echo "Output files:"
    ls "$SUBJECT_MASK_DIR/"
else
    echo "Completed with failures: ${FAILED[*]}"
    exit 1
fi
