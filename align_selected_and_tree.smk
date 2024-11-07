#!/usr/bin/env python3

from pathlib import Path


def which_aligner(wildcards):
    if wildcards.aligner == "clustalo":
        return "--use_clustal"
    elif wildcards.aligner == "mafft":
        return ""
    else:
        raise ValueError(f"wtf {wildcards}")


paragone = "docker://quay.io/biocontainers/paragone:1.1.2--py39h9ee0642_0"

outdir = Path("test-output")
pool = 5

attempts = [str(x).zfill(2) for x in range(1, 11)]


wildcard_constraints:
    attempt="|".join(attempts),


# ISSUE 1.
# What causes the fail on the boronia dataset


rule target:
    input:
        expand(
            Path(
                outdir, "align_selected_and_tree", "{aligner}", "attempt_{i}"
            ).resolve(),
            aligner=["clustalo", "mafft"],
            i=attempts,
        ),


rule align_selected_and_tree:
    input:
        Path(
            "data",
            "boronia",
            "paragone",
        ).resolve(),
    output:
        outdir=directory(
            Path(
                outdir, "align_selected_and_tree", "{aligner}", "attempt_{i}"
            )
        ),
    params:
        threads=lambda wildcards, threads: threads // pool,
        aligner=which_aligner,
    log:
        Path(
            outdir, "align_selected_and_tree", "{aligner}", "attempt_{i}.log"
        ).resolve(),
    threads: workflow.cores
    resources:
        mem_mb=int(16e3),
        time=int(120),
    container:
        paragone
    shell:
        "mkdir -p {output} && cd {output} || exit 1 ; "
        "find {input} -maxdepth 1 -mindepth 1 -type d "
        "-exec ln -s {{}} ${{PWD}}/ \; ; "
        "paragone "
        "align_selected_and_tree 04_alignments_trimmed_cleaned "
        "--use_fasttree "
        "--pool " + str(pool) + " "
        "--threads {params.threads} "
        "{params.aligner} "
        "&> {log} "
