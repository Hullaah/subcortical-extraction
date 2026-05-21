#!/usr/bin/env bash
. common.sh

MRI_INPUT_DIR=nii/mri
SEG_OUTPUT_DIR=nii/subcortical_seg
FIRST_LOG_DIR=logs/first
PARALLEL_JOBS=3 

mkdir -p "$SEG_OUTPUT_DIR"
mkdir -p "$FIRST_LOG_DIR"

FIRST_STRUCTURES="L_Hipp,R_Hipp,L_Amyg,R_Amyg,L_Caud,R_Caud,L_Puta,R_Puta,L_Pall,R_Pall,L_Thal,R_Thal,L_Accu,R_Accu,BrStem"

export SEG_OUTPUT_DIR FIRST_LOG_DIR FIRST_STRUCTURES

segment_subject() {
    NII_FILE="$1"
    BASENAME="$(basename "$NII_FILE" .nii.gz)"
    SUBJECT_OUT_DIR="$SEG_OUTPUT_DIR/$BASENAME"
    SUBJECT_OUTPUT_PREFIX="$SUBJECT_OUT_DIR/$BASENAME"
    LOG_FILE="$FIRST_LOG_DIR/${BASENAME}.log"

    if [ -f "${SUBJECT_OUTPUT_PREFIX}_all_fast_firstseg.nii.gz" ]; then
        echo "Skipping $BASENAME — already segmented"
        return 0
    fi

    mkdir -p "$SUBJECT_OUT_DIR"
    echo "Segmenting $BASENAME"

    run_first_all \
        -i "$NII_FILE" \
        -o "$SUBJECT_OUTPUT_PREFIX" \
        -s "$FIRST_STRUCTURES" \
        -b \
        > "$LOG_FILE" 2>&1

    if [ $? -ne 0 ]; then
        echo "WARNING: failed $BASENAME — see $LOG_FILE"
    else
        echo "Done: $BASENAME"
    fi
}

export -f segment_subject

find "$MRI_INPUT_DIR" \
    -type f \
    -name "*.nii.gz" \
| parallel -j "$PARALLEL_JOBS" segment_subject {}

echo "Subcortical segmentation complete."
