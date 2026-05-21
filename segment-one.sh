#!/usr/bin/env bash
# segment_one.sh — Segment a single MRI volume with FSL FIRST (for validation)
. common.sh

SEG_OUTPUT_DIR=nii/subcortical_seg
FIRST_LOG_DIR=logs/first

mkdir -p "$SEG_OUTPUT_DIR"
mkdir -p "$FIRST_LOG_DIR"

FIRST_STRUCTURES="L_Hipp,R_Hipp,L_Amyg,R_Amyg,L_Caud,R_Caud,L_Puta,R_Puta,L_Pall,R_Pall,L_Thal,R_Thal,L_Accu,R_Accu,BrStem"

NII_FILE="$1"

if [ -z "$NII_FILE" ]; then
    echo "Usage: $0 <path/to/volume.nii.gz>"
    exit 1
fi

if [ ! -f "$NII_FILE" ]; then
    echo "Error: file not found: $NII_FILE"
    exit 1
fi

BASENAME="$(basename "$NII_FILE" .nii.gz)"
SUBJECT_OUT_DIR="$SEG_OUTPUT_DIR/$BASENAME"
SUBJECT_OUTPUT_PREFIX="$SUBJECT_OUT_DIR/$BASENAME"
LOG_FILE="$FIRST_LOG_DIR/${BASENAME}.log"

echo "Segmenting: $NII_FILE"
echo "Output dir: $SUBJECT_OUT_DIR"
echo "Log: $LOG_FILE"

mkdir -p "$SUBJECT_OUT_DIR"

run_first_all \
    -i "$NII_FILE" \
    -o "$SUBJECT_OUTPUT_PREFIX" \
    -s "$FIRST_STRUCTURES" \
    -b \
    > "$LOG_FILE" 2>&1

if [ $? -ne 0 ]; then
    echo "FAILED — check $LOG_FILE"
    exit 1
fi

echo "Done. Output:"
ls "$SUBJECT_OUT_DIR/"*firstseg* "$SUBJECT_OUT_DIR/"*origsegs*
