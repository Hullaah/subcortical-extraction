#!/usr/bin/env bash

PREFIX=oasis_cross-sectional_disc
SUFFIXES=({1..12}.tar.gz)
DOWNLOAD_DIR="downloads"
EXTRACT_DIR="oasis"

echo mkdir "$DOWNLOAD_DIR"
mkdir "$DOWNLOAD_DIR"
echo mkdir "$EXTRACT_DIR"
mkdir "$EXTRACT_DIR"

for SUFFIX in "${SUFFIXES[@]}";
do
    DATASET_LINK="https://download.nrg.wustl.edu/data/$PREFIX$SUFFIX"
    if [ ! -f "$DOWNLOAD_DIR/$PREFIX$SUFFIX" ]
    then
        echo curl --output-dir "$DOWNLOAD_DIR"  -O "$DATASET_LINK"
        curl -fsSL --output-dir "$DOWNLOAD_DIR"  -O "$DATASET_LINK"
    fi
    echo tar --skip-old-files -C "$EXTRACT_DIR" -xzvf "$DOWNLOAD_DIR/$PREFIX$SUFFIX"
    tar --skip-old-files -C "$EXTRACT_DIR" -xzvf "$DOWNLOAD_DIR/$PREFIX$SUFFIX"
done
