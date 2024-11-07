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

outdir = Path("test-output", "")
pool = 5

attempts = [str(x).zfill(2) for x in range(1, 11)]


wildcard_constraints:
    attempt="|".join(attempts),


rule target:
    input:
        expand(
            Path(
                outdir, "final_alignments", "{aligner}", "attempt_{i}.log"
            ).resolve(),
            aligner=["clustalo", "mafft"],
            i=attempts,
        ),


# This fails every time on the cluster but passes locally
rule final_alignments:
    input:
        Path(
            "data",
            "random_fail",
        ).resolve(),
    output:
        outdir=directory(
            Path(outdir, "final_alignments", "{aligner}", "attempt_{i}")
        ),
    params:
        threads=lambda wildcards, threads: threads // pool,
        aligner=which_aligner,
    log:
        Path(
            outdir, "final_alignments", "{aligner}", "attempt_{i}.log"
        ).resolve(),
    threads: workflow.cores
    resources:
        mem_mb=int(8e3),
        time=int(30),
    container:
        paragone
    shell:
        "mkdir -p {output.outdir} && cd {output} || exit 1 ; "
        "find {input} -maxdepth 1 -mindepth 1 -type d "
        "-exec ln -s {{}} ${{PWD}}/ \; ; "
        "paragone final_alignments "
        "--mo --rt --mi "
        "--pool " + str(pool) + " "
        "--threads {params.threads} "
        "--keep_intermediate_files "
        "{params.aligner} "
        "&> {log} "
