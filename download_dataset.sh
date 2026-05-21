#!/usr/bin/env bash
. common.sh
echo "Download directory: $DOWNLOAD_DIR"
mkdir  -p "$DOWNLOAD_DIR"

for SUFFIX in "${SUFFIXES[@]}";
do
    FOLDER_NAME="$PREFIX$SUFFIX"
    DATASET_LINK="https://download.nrg.wustl.edu/data/$FOLDER_NAME.tar.gz"
    if [ ! -f "$DOWNLOAD_DIR/$FOLDER_NAME.tar.gz" ]
    then
        echo curl -fsSL --output-dir "$DOWNLOAD_DIR"  -O "$DATASET_LINK"
        curl -fsSL --output-dir "$DOWNLOAD_DIR"  -O "$DATASET_LINK"
    fi
done
