---
layout: post
title: Using snakemake `--profile` for default settings and cluster execution
modified: 2020-04-20
---

There are a number of parameters I always want to run for snakemake, and writing them on the command line every time can be tedious. For example, I nearly always want snakemake to "keep going" (`--keep-going`) with independent jobs, even if a single one fails. I nearly always use dedicated conda environments for each rule, so I'd like `--use-conda` to be the default execution.

Luckily, that's where `--profile` comes in! You can now set up a snakemake profile with these bits of information. If you use a job scheduler, you can also set default partition, cpu, and memory resources to submit to the scheduler. 

## Building your profile

### **For jobs executed without a job scheduler**

If you don't use a job scheduler (or you sometimes run jobs directly, e.g. on an interactive session) you can build your own profile like so:

```
mkdir -p ~/.config/snakemake/default
touch ~/.config/snakemake/default/config.yaml
```

Then, open the config.yaml file using your favorite text editor, and add settings you like. Here's my `default` profile config:
```
# non-slurm profile defaults
restart-times: 3
local-cores: 1
latency-wait: 60
use-conda: True
jobs: 1
keep-going: True
rerun-incomplete: True
shadow-prefix: /scratch/ntpierce
printshellcmds: True
```

If you don't want to set up another profile for a job scheduler, skip to the run section below :).

### **For job schedulers**

Snakemake profiles for a number of job schedulers (e.g. slurm, pbs) can be found [here](https://github.com/Snakemake-Profiles). I followed the instructions to set up a SLURM profile for our `farm` hpc at uc davis, so I'll walk through set up for that.

Make sure `cookiecutter` is available. For me, that requires `conda activate snakemake`.
```
mkdir -p ~/.config/snakemake
cd ~/.config/snakemake
cookiecutter https://github.com/Snakemake-Profiles/slurm.git
```

Follow the setup prompts. If you don't know what to write, leave it blank - you can always edit the information later (this is what I did).

Go find your profile. Mine is at `~/.config/snakemake/slurm`. You should see the following files in your profile folder:
```
config.yaml
slurm-jobscript.sh
slurm-status.py
slurm-submit.py
slurm_utils.py
```

The main settings are in `config.yaml` For slurm, that currently looks like this:

```
restart-times: 3
jobscript: "slurm-jobscript.sh"
cluster: "slurm-submit.py"
cluster-status: "slurm-status.py"
max-jobs-per-second: 1
max-status-checks-per-second: 10
local-cores: 1
latency-wait: 60
```

Now, add or modify anything you need to. I added the following:

```
# snakemake settings I like
use-conda: True
jobs: 10
keep-going: True
rerun-incomplete: True
shadow-prefix: /scratch/ntpierce
printshellcmds: True
```

**NOTE:** For now, I actually commented out the the `slurm-status.py` line, as `sacct` isn't enabled on our system, and the output was very verbose.


**Setting default resource utilization**

Using your favorite text editor, open a new file (mine is: `~/.config/snakemake/slurm/cluster_config.yml`)

Write in your desired default resources. For me, this file contains:
```
__default__:
    account: ctbrowngrp # your hpc account
    partition: bml # the partition you use
    mail-user: ntpierce@ucdavis.edu # your email (optional!)
    time: 360 # default time (minutes)
    nodes: 1
    ntasks: 1
    mem: 14GB # default memory
```

snakemake will apply anything in `__default__` to all rules, unless they specifically override the parameters. 

Now edit the `slurm-submit.py` file so the `CLUSTER_CONFIG` variable points to the file you just wrote. For me:

```
CLUSTER_CONFIG = "/home/ntpierce/.config/snakemake/slurm/cluster_config.yml"
```

## Run snakemake using your profile

To execute using a profile, use:

```
snakemake --profile slurm
```
or

```
snakemake --profile default
```

Voila! No need to keep writing `--keep-going` on the command line anymore!

## Setting Rule-specific Resource Utilization

I don't always want to execute my rules with the default resources. Sometimes I'd like to allocate additional time or memory, or scale back the memory (my default is rather high).

You can do this for _all_ jobs in a snakefile by setting different default resources (`--default-resources`) at the command line. However, I prefer to set job-specific resources, and you can do that _within_ the rules themselves, using the following parameters:

```
threads: 1
resources:
    mem_mb=4000, #4GB
    runtime=60 #minutes
```

These resources are used to specify the cpu, memory and runtime allocated via SLURM. Here's what they look like in the context of a rule.

```
rule seqtk_fasta_to_fastq:
    input: "sample_{rep}.fasta.gz"
    output: "{refname}_{rep}.fq.gz"
    threads: 1
    resources:
      mem_mb=1000,
      runtime=10
    conda: "envs/seqtk-env.yml"
    shell:
        """
        seqtk seq -F 'I' {input} | gzip -9 > {output}
        """
```
This rule converts a fasta file to a fastq file by providing dummy quality values. It's being run on a single thread, given 1GB memory and 10 minutes to run.

### Advanced Resource Specification

You can also set the resources based on the number of `attempts` for running a specific command. 

Example from the documentation:
```
rule:
    input:    ...
    output:   ...
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 100
    shell:
        "..."
```
Here, if you have the `restart-times` set to 3, then the rule will run with 100mb of memory on its first attempt, 200mb on second attempt, and 300mb on third attempt.

For more information, see the [resources documentation](https://snakemake.readthedocs.io/en/stable/snakefiles/rules.html#resources)!

## What's Missing?

It would be nice to have a default profile that is used without specifying `--profile` (thanks for this idea, Titus!)

When I was writing rule-specific `--cluster-config` files, I could set the rulename and slurm output files a little more intelligently, using snakemake rulenames and wildcards. 

For example, here was my config for a rule called `polyA_trim`:
```
polyA_trim:
    partition: bmm
    time: 2:00:00 # time limit for each job
    nodes: 1
    cpus_per_task: 10
    mem: 5GB
    chdir: /home/ntpierce/2020-pep/orthopep_out
    stderr: "logs/cutadapt/slurm-%j.stderr"
    stdout: "logs/cutadapt/slurm-%j.stdout"
    jobname: "{rule}.w{wildcards}"
```

Luckily, it looks like a solution for this is in progress [here](https://github.com/Snakemake-Profiles/slurm/issues/40)!


Thanks to @johanneskoester for kindly answering my questions on resources and to everyone working on snakemake & snakemake profiles!
