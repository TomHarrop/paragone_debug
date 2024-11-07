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


rule target:
    input:
        expand(
            Path(
                outdir, "check_and_align", "{aligner}", "attempt_{i}.log"
            ).resolve(),
            aligner=["clustalo", "mafft"],
            i=attempts,
        ),


# The error is caused by MAFFT producing an empty alignment.  It happens
# randomly, i.e. different genes fail on different attempts.  This only happens
# on petrichor, not my local computer.

# things to try:
# - run many attempts of the MAFFT command
# - clustalo instead of mafft


rule check_and_align:
    input:
        paralog_sequences=Path("data", "check_and_align").resolve(),
        external_outgroups=Path("data", "chloranthaceae.fa").resolve(),
    output:
        directory(Path(outdir, "check_and_align", "{aligner}", "attempt_{i}")),
    params:
        threads=lambda wildcards, threads: threads // pool,
        aligner=which_aligner,
    log:
        Path(
            outdir, "check_and_align", "{aligner}", "attempt_{i}.log"
        ).resolve(),
    threads: workflow.cores
    resources:
        mem_mb=int(8e3),
        time=int(30),
    container:
        paragone
    shell:
        "mkdir -p {output} && cd {output} || exit 1 ; "
        "paragone "
        "check_and_align {input.paralog_sequences} "
        "--external_outgroups_file {input.external_outgroups} "
        "--pool " + str(pool) + " "
        "--threads {params.threads} "
        "{params.aligner} "
        "&> {log} "
