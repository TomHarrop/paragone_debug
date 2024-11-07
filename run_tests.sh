#!/bin/bash

#SBATCH --job-name=pg_tests
#SBATCH --time=7-00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8g
#SBATCH --output=sm.slurm.out
#SBATCH --error=sm.slurm.err
#SBATCH --partition=io

# Dependencies
module load apptainer/1.1.5-suid

# clobber broken apptainer config from module
export APPTAINER_BINDPATH=""

# Application specific commands:
export TMPDIR="${JOBDIR}"

printf "JOBDIR: %s\n" "${JOBDIR}"
printf "LOCALDIR: %s\n" "${LOCALDIR}"
printf "MEMDIR: %s\n" "${MEMDIR}"
printf "TMPDIR: %s\n" "${TMPDIR}"


snakemake \
    --profile petrichor_tmp \
    --retries 0 \
    --keep-going \
    --keep-incomplete \
    --ignore-incomplete \
    --cores 64 \
    --local-cores 1 \
    -s final_alignments_1.1.3.smk

exit 0

snakemake \
    --profile petrichor_tmp \
    --retries 0 \
    --keep-going \
    --keep-incomplete \
    --ignore-incomplete \
    --cores 64 \
    --local-cores 1 \
    -s align_selected_and_tree.smk

snakemake \
    --profile petrichor_tmp \
    --retries 0 \
    --keep-going \
    --keep-incomplete \
    --ignore-incomplete \
    --cores 64 \
    --local-cores 1 \
    -s check_and_align.smk

snakemake \
    --profile petrichor_tmp \
    --retries 0 \
    --keep-going \
    --keep-incomplete \
    --ignore-incomplete \
    --cores 64 \
    --local-cores 1 \
    -s final_alignments.smk

snakemake \
    --profile petrichor_tmp \
    --retries 0 \
    --keep-going \
    --keep-incomplete \
    --ignore-incomplete \
    --cores 2 \
    --local-cores 1 \
    -s check_mafft.smk
