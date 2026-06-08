#!/usr/bin/env bash
. common.sh

SEG_OUTPUT_DIR=nii/subcortical_seg
FIRST_LOG_DIR=logs/first

FIRST_STRUCTURES=(
    L_Hipp R_Hipp
    L_Amyg R_Amyg
    L_Caud R_Caud
    L_Puta R_Puta
    L_Pall R_Pall
    L_Thal R_Thal
    L_Accu R_Accu
    BrStem
)

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
LOG_DIR="$FIRST_LOG_DIR/$BASENAME"

mkdir -p "$SUBJECT_OUT_DIR"
mkdir -p "$LOG_DIR"

echo "Segmenting: $NII_FILE"
echo "Output dir: $SUBJECT_OUT_DIR"
echo "Logs dir:   $LOG_DIR"
echo ""

FAILED=()

for STRUCTURE in "${FIRST_STRUCTURES[@]}"; do
    OUTPUT_PREFIX="$SUBJECT_OUT_DIR/${BASENAME}_${STRUCTURE}"
    LOG_FILE="$LOG_DIR/${STRUCTURE}.log"
    DONE_SENTINEL="${OUTPUT_PREFIX}-${STRUCTURE}_corr.nii.gz"

    if [ -f "$DONE_SENTINEL" ]; then
        echo "Skipping $STRUCTURE — already done"
        continue
    fi

    echo "Segmenting $STRUCTURE..."

    run_first_all \
        -i "$NII_FILE" \
        -o "$OUTPUT_PREFIX" \
        -s "$STRUCTURE" \
        -b \
        > "$LOG_FILE" 2>&1

    if [ $? -ne 0 ]; then
        echo "  FAILED — see $LOG_FILE"
        FAILED+=("$STRUCTURE")
    else
        echo "  Done"
    fi
done

echo ""
if [ ${#FAILED[@]} -eq 0 ]; then
    echo "All structures segmented successfully."
    echo ""
    echo "Output files:"
    ls "$SUBJECT_OUT_DIR/"*_corr.nii.gz
else
    echo "Completed with failures: ${FAILED[*]}"
    echo "Check logs in $LOG_DIR/"
    exit 1
fi
