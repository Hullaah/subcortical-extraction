# Subcortical Brain Volume Extraction Pipeline

A batch processing pipeline that extracts subcortical brain structure volumes from the OASIS cross-sectional MRI dataset (436 subjects) using FSL FIRST, producing per-subject, per-structure volume measurements for downstream statistical analysis (e.g. demented vs. non-demented classification via CDR scores).

Built during SIWES at DATICAN under Prof. Aribisala.

## What it does

Given raw OASIS `.tar.gz` archives, the pipeline:

1. **Downloads** the dataset discs from the OASIS project (`download_dataset.sh`)
2. **Converts** raw Analyze-format MRI volumes (`.img`/`.hdr`) to compressed NIfTI (`.nii.gz`) using `fslchfiletype`, in parallel (`convert_dataset.sh`)
3. **Segments** 15 subcortical structures per subject — hippocampus, amygdala, caudate, putamen, pallidum, thalamus, accumbens (left/right), and brainstem — using FSL's `run_first_all` (`segment_dataset.sh` / `segment-one.sh`)
4. **Extracts binary masks** from the corrected segmentation boundaries via `fslmaths -bin` (`extract_masks.sh` / `extract-masks-one.sh`)
5. **Computes volumes** in mm³ for every structure from the binary masks, using voxel counts and header-derived voxel dimensions via `nibabel`, and writes results to Excel (`compute_volumes.py`)

End result: 6,540 structure volumes (436 subjects × 15 structures) exported to `subcortical_volumes.xlsx`, in both wide (one row per subject) and long (one row per subject-structure pair) formats, plus a flagged-issues sheet for anomalies like empty masks or missing segmentation output.

## Design notes

- **Idempotent and resumable.** Every per-subject script checks for existing output (`DONE_SENTINEL` files, existing masks) before redoing work, so a killed or partially-failed run can just be re-run without duplicating hours of segmentation time.
- **Parallelized with GNU `parallel`**, not naive shell loops — conversion, segmentation, and mask extraction all fan out across subjects (`PARALLEL_JOBS` configurable per stage) since FSL FIRST is CPU-bound and single-subject runs are independent.
- **Scratch space isolation.** `segment-one.sh` copies each subject's volume into a `mktemp -d` working directory and cleans up via `trap ... EXIT`, so concurrent jobs never collide on shared files and no partial state survives a crash.
- **Verification path built in.** `compute_volumes.py --mask <path>` computes a single mask's volume and prints the exact `fslstats <mask> -V` command to cross-check it against — this is how a silent boundary-correction failure (a mask with 0 voxels despite `run_first_all` reporting success) was originally caught, on subject `OAS1_0065_MR1`, structure `R_Accu`.
- **Failure tracking, not failure hiding.** Both segmentation and mask extraction log per-structure failures explicitly rather than continuing silently, and `compute_volumes.py` writes an `Issues` sheet alongside the data so anomalies are visible in the same deliverable, not buried in logs.

## Requirements

- FSL (`run_first_all`, `fslmaths`, `fslchfiletype`, `fslstats`) installed and on `PATH`
- GNU `parallel`
- Python 3 with `nibabel`, `numpy`, `pandas`, `openpyxl` (see `requirements.txt`)

## Usage

```bash
./download_dataset.sh      # fetch OASIS discs
./convert_dataset.sh       # .img/.hdr -> .nii.gz
./segment_dataset.sh       # run FSL FIRST across all subjects
./extract_masks.sh         # binarize corrected segmentations
python compute_volumes.py  # -> subcortical_volumes.xlsx
```

Single-subject equivalents (`segment-one.sh`, `extract-masks-one.sh`) are available for debugging or reprocessing a specific subject without rerunning the full batch.

## Dataset

[OASIS Cross-Sectional](https://www.oasis-brains.org/) — 436 subjects aged 18–96, including individuals with early-stage Alzheimer's disease.
