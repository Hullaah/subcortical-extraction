#!/usr/bin/env bash

. common.sh

MRI_OUTPUT_DIR=nii/mri
SEG_OUTPUT_DIR=nii/seg

mkdir -p "$MRI_OUTPUT_DIR"
mkdir -p "$SEG_OUTPUT_DIR"

EXTRACT_DIR="$(mktemp -d)"

echo "Extract directory: $EXTRACT_DIR"

for SUFFIX in "${SUFFIXES[@]}";
do
    FOLDER_NAME="$PREFIX$SUFFIX"

    mkdir -p "$EXTRACT_DIR/$FOLDER_NAME"

    echo "Extracting $DOWNLOAD_DIR/$FOLDER_NAME.tar.gz into $EXTRACT_DIR/$FOLDER_NAME"

    tar \
        --skip-old-files \
        -C "$EXTRACT_DIR/$FOLDER_NAME" \
        -xzf "$DOWNLOAD_DIR/$FOLDER_NAME.tar.gz" \
        --strip-components=1

    echo "Converting MRI volumes from $FOLDER_NAME"

    find "$EXTRACT_DIR/$FOLDER_NAME" \
        -type f \
        -name "*masked_gfc.img" \
        ! -name "*fseg*" \
    | while read -r IMG_FILE
    do
        BASENAME="$(basename "$IMG_FILE" .img)"

        OUTPUT_FILE="$MRI_OUTPUT_DIR/$BASENAME"

        echo "Converting $IMG_FILE -> $OUTPUT_FILE.nii.gz"

        fslchfiletype NIFTI_GZ \
            "$IMG_FILE" \
            "$OUTPUT_FILE"
    done

    echo "Converting segmentation volumes from $FOLDER_NAME"

    find "$EXTRACT_DIR/$FOLDER_NAME" \
        -type f \
        -name "*fseg.img" \
    | while read -r IMG_FILE
    do
        BASENAME="$(basename "$IMG_FILE" .img)"

        OUTPUT_FILE="$SEG_OUTPUT_DIR/$BASENAME"

        echo "Converting $IMG_FILE -> $OUTPUT_FILE.nii.gz"

        fslchfiletype NIFTI_GZ \
            "$IMG_FILE" \
            "$OUTPUT_FILE"
    done

    echo "Deleting directory $EXTRACT_DIR/$FOLDER_NAME"

    rm -rf "${EXTRACT_DIR:?}/$FOLDER_NAME"
done

echo "Dataset conversion complete."
