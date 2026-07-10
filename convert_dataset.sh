#!/usr/bin/env bash

. common.sh

MRI_OUTPUT_DIR=nii/mri
PARALLEL_JOBS=4

mkdir -p "$MRI_OUTPUT_DIR"

EXTRACT_DIR="$(mktemp -d)"
echo "Extract directory: $EXTRACT_DIR"

export DOWNLOAD_DIR PREFIX MRI_OUTPUT_DIR EXTRACT_DIR

process_folder() {
    local SUFFIX="$1"
    local FOLDER_NAME="$PREFIX$SUFFIX"

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
        ! -name "*to_std_sub*" \
    | while read -r IMG_FILE
    do
        BASENAME="$(basename "$IMG_FILE" .img)"
        OUTPUT_FILE="$MRI_OUTPUT_DIR/$BASENAME"

        echo "Converting $IMG_FILE -> $OUTPUT_FILE.nii.gz"

        fslchfiletype NIFTI_GZ \
            "$IMG_FILE" \
            "$OUTPUT_FILE"
    done

    echo "Deleting directory $EXTRACT_DIR/$FOLDER_NAME"
    rm -rf "${EXTRACT_DIR:?}/$FOLDER_NAME"
}
export -f process_folder

printf '%s\n' "${SUFFIXES[@]}" | parallel -j "$PARALLEL_JOBS" process_folder {}

echo "Dataset conversion complete."
