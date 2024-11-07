#!/usr/bin/env python3

from pathlib import Path

paragone = "docker://quay.io/biocontainers/paragone:1.1.2--py39h9ee0642_0"

outdir = Path("test-output")


attempts = [str(x).zfill(4) for x in range(1, 2001)]


wildcard_constraints:
    attempt="|".join(attempts),


rule target:
    input:
        expand(
            Path(outdir, "mafft_check", "5733.{i}.log"),
            i=attempts,
        ),


# The error is caused by MAFFT producing an empty alignment.  It happens
# randomly, i.e. different genes fail on different attempts.  This only happens
# on petrichor, not my local computer.

# things to try:
# - run many attempts of the MAFFT command
# - clustalo instead of mafft

# This is the error! It sometimes fails on the cluster with
# "tr: read error: No data available"


rule mafft_check:
    input:
        Path(
            "data",
            "mafft_check",
            "01_input_paralog_fasta_with_sanitised_filenames/5733.fasta",
        ),
    output:
        Path(outdir, "mafft_check", "5733.{attempt}.fasta"),
    log:
        Path(outdir, "mafft_check", "5733.{attempt}.log"),
    shadow:
        "minimal"
    threads: 2
    resources:
        mem_mb=int(4e3),
        time=int(3),
    container:
        paragone
    shell:
        "mafft "
        "--auto "
        "--thread 2 "
        "{input} "
        "> {output} "
        "2> {log}"
