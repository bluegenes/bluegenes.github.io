---
tags: snakemake, illo, dib-lab
---

Tips and Tricks for running snakemake on our hpc (farm)
===

These are notes for a virtual in-lab learning opportunity (vILLO) in the lab for data-intensive biology at UC Davis (08/24/2020). The main goal is to pass along tips and tricks for running snakemake on our `farm` cluster, including using `conda` for installation and submitting jobs via the `slurm` job scheduler. Many of these notes will translate to other clusters, but some may not, YMMV.

Current snakemake version: 5.22

---

## Setup

Before we begin:
- [Set up farm](https://dib-lab.github.io/2020-NSURP/01.using-farm/) 
- [Install and configure conda](https://dib-lab.github.io/2020-NSURP/02.conda/)
- Log in to farm!

### Install or upgrade snakemake

Snakemake comes installed on `farm`. Why do we need to reinstall?

Run`snakemake --version`. What do you see?

![](https://i.imgur.com/8iHzjhd.png =300x)

The current version of snakemake is `5.22.1`, and a number of functionalities have been added, even since earlier `5.x` versions. If you're using a snakefile that takes advantage of newer features, running with an older version of snakemake won't work!


I now use Luiz's method: create a `environment.yml` file for each project, and add a small blurb in the README with instructions for creating the project environment from it. Here are some examples:
https://github.com/luizirber/2020-cami/blob/master/environment.yml
https://github.com/luizirber/2020-cami#setup

Copy the following into a file called `environment.yml`
```
name: snakemake-demo
channels:
  - conda-forge
  - bioconda
  - defaults
dependencies:
  - python=3.8
  - snakemake-minimal=5.22.0
  - pandas>=1.1.1
```

Now create an environment using that file

```
conda env create --file environment.yml
```

Finally, activate that environment:

```
conda activate snakemake-demo
```


> **Conda environments** 
> Different software packages often have different "dependencies": other software packages that are required for installation. In many cases, you'll need software with dependencies that conflict -- e.g. one program requires python version 3, while the other requires python 2. To avoid conflicts, we install software into "environments" that are isolated from one another - so that the software installed in one environment does not impact the software installed in another environment.

### Get the 2020-ggg-201b-rnaseq workflow

Download the 2020-ggg-201b-rnaseq workflow
```
git clone https://github.com/ngs-docs/2020-ggg-201b-rnaseq
```
You can `ls` the directory to see that there is indeed a `Snakefile` in there. We won't look at it just yet.

#### A quick reminder: Anatomy of a Snakemake Rule

Here's one of the shortest rules in the Snakefile. It only has two "directives": `output`, and `shell`.

![](https://i.imgur.com/hK61KfW.png)

> the rule name, `download_trimmomatic_adapter_file` is arbitrary, and used to help you keep track of what the step is doing
> 
> the `output: TruSeq2-SE.fa` tell snakemake what output file(s) to expect as a result of running this rule step
> 
> the `shell` directive runs shell commands (that we could manually run at the command line).


Other rules require a bit more information:

```
rule quality_trim:
    input: 
        reads="rnaseq/raw_data/{sample}.fq.gz",
        adapters="TruSeq2-SE.fa",
    output: "rnaseq/quality/{sample}.qc.fq.gz"
    shell:
        """
        trimmomatic SE {input.reads} {output} \
        ILLUMINACLIP:{input.adapters}:2:0:15 \
        LEADING:2 TRAILING:2 SLIDINGWINDOW:4:2 MINLEN:25    
        """
```

> This rule also contains an `input:` directive, which specifies the files needed for this step. In this case, since the `adapters` file is created in the rule above, snakemake will know to run that rule before running this one.

Snakemake will evaluate all rule inputs and outputs prior to running a workflow, and output a `directed acyclic graph`, or `DAG` of the workflow. The DAG for this workflow looks like this:

![](https://i.imgur.com/CnWEirc.png)


## Running snakemake using an interactive session

When running long snakemake jobs, we want to be able to log in and out of farm at will, without worrying about accidentally killing our snakemake session. To enable this, we use a terminal multiplexer such as `tmux` or `screen` to run our snakemake job.

### Open a work session using your favorite terminal multiplexer 
e.g. `tmux`, `screen`, `byobu`


#### Create a new `tmux` session:
```
tmux new -s snakes
```
>Note: *If you already created a session and want to re-join it, use `tmux attach` instead.*


### Get access to a compute node

When we log on to our `farm` computing system, we start out on a `login` node, which is basically a computer with very few resources. These login nodes are shared among all users on `farm`. 

If we run any computing on these login nodes, logging into and navigating `farm` will slow down for everyone else! Instead, the moment that we want to do anything substantial, we want to ask `farm` for a more capable computer. `Farm` uses  the `SLURM` "job scheduler" to make sure everyone gets access to the computational resources that they need.

We can use the following command to get access to a computer that will fit our needs:

```
srun -p bmm -J snaketesting -t 5:00:00 --mem=10G --pty bash
```
> -  `srun` uses the computer's job scheduler `SLURM` to allocate you a computer
> - `-p` specifies the job queue we want to use, and is specific to our `farm` accounts.
> - `-J snaketesting` is the "job name" assigned to this session. It can be modified to give your session a more descriptive name, e.g. `-J download-data`
> - `-t` denotes that we want the computer for that amount of time (in this case, 5 hours).
> - `--mem` specifies the amount of memory we'd like the computer to have. Here we've asked for 10 Gigabytes (10G). 
> - `--pty bash` specified that we want the linux shell to be the `bash` shell, which is the standard shell we've been working with so far

Note that your directories (the files you see) will be the same for both the login node and the computer you get access to. So any files you create while in an `srun` session will still be there for you when you log out.

### Activate your snakemake conda environment

Once you're in an `srun` session, you're on a new computer and will need to activate (or re-activate) your conda environment to get access to the software.

```
conda activate snakemake
```

### Dry Run Snakemake

Now we can run snakemake!

First, let's use the `dryrun` function `-n` to just see what would be run.

```
cd ~/2020-ggg-201b-rnaseq
snakemake -j 1 -n
```

### Installing Programs with Conda

The rules in this snakefile require a few rnaseq programs. We can now create a conda environment to run them with.


#### Option A. Manual Installation: Create the environment on the command line

This is the way many of us are used to creating conda environments. First, we create (and name) a conda environment, then install the software we need, and then activate it.

```
conda create -n ggg-rna
conda activate ggg-rna
conda install fastqc=0.11.9 \
      trimmomatic=0.39 \
      multiqc=1.8 \
      salmon=1.1.0 \
```
> If you have [mamba](https://github.com/TheSnakePit/mamba) installed, you can use `mamba install` instead


#### Option B. Manual Installation Creating the environment via a conda environment file
Alternatively, we could create the exact same environment using the `conda` environment file.
    
If you open `rnaseq-env.yaml`, you should see this:

![](https://i.imgur.com/8pEyjtN.png =250x)

> `channels` tells conda which online repositories ("channels") to search. Note that we set these channels as defaults when we set up our conda installations on `farm`, which is why we didn't need to specify them in the manual installation above (1A). Keeping the channels in the environment file is good practice and helps ensure the environment will install on other computing systems as well, including those where `conda-forge` and `bioconda` have not been added to the conda installation configuration.
> 
> `dependencies` is where you specify each program. Versions are optional but recommended for reproducibility.


We could create and install the environment like this:

```
conda env create -n ggg-rna --file rnaseq-env.yaml
```

> Note: To automatically name the environment (and not need to use `-n ggg-rna` in this command), you can add `name: ggg-rna` to the top of the environment file.


Now we should be able to activate the environment and execute the snakefile:
```
conda activate ggg-rna
snakemake -j 1
```
> What happens if you leave out the `-j 1`?

#### Option C. Automated Installation: Let Snakemake Manage Conda Installs for you

We can instead let snakemake manage our conda installs for us. To do this, we need to specify the conda environment file required for each rule.

Open the `Snakefile` using `less` or your favorite text viewer.

Looking at one of the early rules, we see:

![](https://i.imgur.com/j6Gt2ya.png)

> `conda: rnaseq-env.yaml` tells snakemake to install this environment and activate it prior to running this rule. After the rule finishes running, snakemake will automatically deactivate the environment.
> `params` is another directive we haven't seen yet. Here, we need to pass `fastqc` a directory for output files, rather than the names of the output files themselves. The easiest way to do that is to make an `outdir` variable, and pass it to the shell command. 

Since this conda environment directive is already added to all the rules where it is needed, we can go ahead and run snakemake by adding `--use-conda` to our snakemake invocation

Make sure you're in your `snakemake` environment. You can run `snakemake --version` to ensure you're using the right version.
```
conda activate snakemake
snakemake -j 1 --use-conda
```
> `--use-conda` let's snakemake manage conda environments for you. 
>
> Snakemake installs conda environments into a `.snakemake/conda` folder sitting in the directory where you're running your workflow. So if you do an `ls -a` now, you should see a new `.snakemake` folder that was created.
> 
> Note that snakemake "names" environments with series of numbers. You can list the environments associated with a snakefile by running `snakemake --list-conda-envs`. If you want to see *all* your conda environments (including those you manually installed), run `conda info --envs`. 
 
## Setting up Snakemake Profiles

There are a number of parameters I always want to run for snakemake, and writing them on the command line every time can be tedious. For example, I nearly always use dedicated conda environments for each rule, so I’d like `--use-conda` to be the default execution. 

We can set up a snakemake profile to personalize some default settings. This is handy, but the real benefit comes for submitting jobs via the job scheduler, as profiles also enable us to set default partition, cpu, and memory resources to submit to the scheduler.

### For jobs executed without a job scheduler

Let's set up a default profile first, for jobs we'll run via the `srun` interactive session, as we've just been doing.


First, let's make the directory and file for these
```
mkdir -p ~/.config/snakemake/default
touch ~/.config/snakemake/default/config.yaml
cd ~/.config/snakemake/default
```

Then, open the config.yaml file using your favorite text editor, and add settings you like. Here's a `default` profile config with most of the settings I like:
```
# non-slurm profile defaults
restart-times: 3
local-cores: 1
latency-wait: 60
use-conda: True
jobs: 1
keep-going: True
rerun-incomplete: True
printshellcmds: True
```

> All of these turn on options you could specify to snakemake at the command line. See all snakemake options using `snakemake --help`.
> 
>Note that `--use-conda` will activate environments when they are provided with the `conda: ` directive 
and execute all other rules normally (without using conda).

### **For job schedulers**

Snakemake profiles for a number of job schedulers (e.g. slurm, pbs) can be found [here](https://github.com/Snakemake-Profiles). BUT, Camille modified the base slurm profile to handle a few `farm` quirks, so let's start from her version instead.

Make sure you're in your snakemake env (`conda activate snakemake`) or otherwise have snakemake available.

```
mkdir -p ~/.config/snakemake
cd ~/.config/snakemake
git clone https://github.com/camillescott/ucd-farm-slurm-profile.git
cd ucd-farm-slurm-profile
```

You'll see a few files in this directory. One of the key files is the `cluster_config.yml` which allows you to set default resources for snakemake jobs.

First, let's edit things to fit our accounts and current workflow.
```
__default__:
    account: ctbrowngrp
    partition: bmm
    mail-type: FAIL,TIME_LIMIT
    mail-user: YOUREMAIL@ucdavis.edu (optional)
    time: 60
    mem: 4000
    nodes: 1
    ntasks-per-node: 1
    job-name: '{rule}.{wildcards}'
    chdir: '/home/ntpierce/2020-ggg-201b-rnaseq'
    logdir: '/home/ntpierce/2020-ggg-201b-rnaseq/' 
```
> Snakemake will apply anything in `__default__` to all rules, unless the rule specifically overrides the parameters.
> You **can** keep this file in a single location, but I like having the ability to set the job name and logging diretories independently for each project. So I keep a copy of this file in each repository (bonus - you can keep it in the github repo associated with the project for reproducibility).

Let's copy this file over to our `ggg-rnaseq` directory
```
cp cluster_config.yml ~/2020-ggg-201b-rnaseq
```

That file was important for specifying cluster settings, but the base snakemake profile is actually within the `slurm_farm` folder. Copy this folder out to the directory above so that snakemake can find it within the `config` directory. Then let's change into the profile folder.

```
cp slurm_farm ../
cd ../slurm_farm
```

 You should see the following files:

```
config.yaml
slurm-jobscript.sh
slurm-status.py
slurm-submit.py
slurm_utils.py
```
> `slurm-jobscript.sh`, `slurm-status.py`, `slurm-submit.py`, and `slurm_utils.py` help snakemake interface with slurm. I've had no need to mess with these files, after incorporating the changes that Camille made to the original `cookiecutter` profile to accommodate farm-specific settings.


The `config.yaml` is the control switch - it sets where to look for these cluster scripts and enables you to set custom defaults, as we did for the `default` profile. For the `slurm_farm` profile, that currently looks like this:

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

You can add or modify this file according to your preference. For example, I find these settings handy for most things I do:

```
use-conda: True
jobs: 10
keep-going: True
rerun-incomplete: True
printshellcmds: True
```

When you're happy with it, save and close the file. 

Now let's go back to the ggg-rnaseq folder to try to run snakemake.

```
cd ~/2020-ggg-201b-rnaseq
```

## Run snakemake using your profile

We made two different profiles - one with added defaults we may want to use during interactive sessions, and one with settings for letting snakemake submit cluster jobs for us (via slurm sbatch). Let's try some dryruns using these profiles.

Using the default profile:
```
snakemake --profile default -n
```

Using slurm_farm:

```
snakemake --profile slurm_farm --cluster-config cluster_config.yml -n
```

### An aside: running only _part_ of a snakemake workflow

You don't need to run *all* of a snakemake workflow at once. There are many ways to run partial workflows, but the `--until` option is one of the handiest.

Running snakemake with `--until RULENAME` will fully evaluate the DAG (meaning you get access to all your wildcards), but will only run rules needed for (and including) the specifed rule. 

You can alternatively specify rule names as "targets" or output filenames as "targets" -- for more, read about all the snakemake command line options [here](https://snakemake.readthedocs.io/en/stable/executing/cli.html)

## How not to be a jerk: setting maximum resource utilization

With the slurm_farm profile, snakemake can submit many jobs across the cluster for us.
But, there are many of us on the same cluster allocation - it's important to be mindful of our shared resources.

### What resources are available?

_this info is slightly modified from our [farm_notes](https://github.com/dib-lab/farm-notes)_

Users in `ctbrowngrp` collectively share resources. Currently, this group has priority access to 1 TB of ram and 96 CPUs on
one machine, and 256 GB RAM and up to 64 CPUs on another two machines. The big mem machine is accessed using the big mem partition, `bm*`,
while the smaller-memory machines are accessed on `high2`/`med2`/`low2`.

As of February 2020, there are 31 researches who share these resources.To manage and share these resources equitably, we have created a set of rules for resource usage. When submitting jobs, please follow these rules:

**`bmh`/`high2`**:
- These resources are guaranteed to be immediately available to use. But, that means they will suspend other people's jobs if there's no free resources available. As suspended jobs are frustrating and ultimately mean that jobs take _longer_, we want to avoid them. 
- **submission limits: ONLY use this queue for:** 
    - small-ish interactive testing 
    - single-core snakemake jobs that submit other jobs. 
    - if needed: one job that uses a reasonable amount of resources of “things that I really need to not get bumped.” Things that fall into this category might be very long running jobs that would otherwise always be interupted on `bmm`/`med2` or `bml`/`low2` (e.g. > 5 days), or single jobs that need to be completed in time for a grant or presentation. If your single job on `bmh`/`high2` will exceed 1/3 of the groups resources for either RAM or CPU, please notify the group prior to submitting this job. 

**`bmm`/`med2`**
- good default setting: you'd like these jobs to start running quickly, but don't want to suspend (bump) other people's jobs.
- **submission limits:** To keep this a good default, don’t submit jobs for more than 1/3 of resources at once. This counts for cpu (96 total, so max 32) and RAM (1TB total, so max 333 GB).

**`bml`/`low2`**
- this is a GREAT queue to submit jobs, especially if they run quickly (and thus are unlikely to get interrupted, or there are *a lot* of them)
- **submission limits:** NONE. free for all! Go hog wild! Submit to your hearts content!

Note that the `bmm`/`bml` and `med2`/`low2` queues have access to the full cluster, not just our machines; so if farm is not being highly utilized you may be able to run *more* jobs **_faster_** on those nodes than on `bmh`/`high2`

There are two main settings to think about - the number of jobs you're submitting, and the total memory allocation. We've come up with some rules for cluster usage.

### Setting limits for Snakemake


**Set resource limitations**

The `--resources` option can be passed to snakemake to limit the total number of resources you allow snakemake to submit jobs for. This can be modified in your `config.yaml` as part of your profile, or passed in at the command line. 

Command line:
```
snakemake --profile slurm_farm --cluster_config cluster_config.yml --resources mem_mb=340000 cpu=30 -n
```
Or, line to add to profile `config.yaml`:
```
resources: [cpus=30, mem_mb=340000]
```
> I haven't done this yet, but one way to handle these limits would be add these to the slurm_farm profile, and then make a second slurm_farm profile (named, for example, `farm_bml`) that excludes these limits. Then, when executing snakemake, choose the appropriate profile for the limits you'd like to run.


**Number of jobs**

You can also modify the maximum number of jobs to submit at once. Unless you're submitting to `low2/bml`, you'll want this to be <30 for single-core jobs, and fewer for multithreaded jobs.


### Check on the status of your jobs


Once snakemake submits jobs for you, you can use `squeue` look at the status of your jobs.

Check your jobs: `squeue -u ntpierce`
Show job info for a job: `scontrol show -d job 22061006`

If you want to look at the range of jobs running on our account (e.g. to see currently-available resources),run: `squeue -A ctbrowngrp`

## Canceling Jobs as needed

Once you've submitted jobs, if you press `Ctrl-C` to cancel your snakemake workflow, you may find that the submitted jobs are not also canceled. In this case, you'll need to cancel them manually.


scancel a specific job: `scancel 22061006`
scancel all of your jobs on a partition: `scancel --partition bml`

## Setting Rule-Specific Resource Utilization

I often want to allocate memory and runtime for specific jobs, rather than for all jobs in a workflow. For example, I know that computing signatures with sourmash requires less than 1G of memory, while running a `sourmash gather` command might need 5-10G.

You can set resources _within_ the rules themselves, using the following parameters:

```
threads: 1
resources:
    mem_mb=4000, #4GB
    runtime=60 #minutes
```

These resources are used to specify the cpu, memory and runtime allocated via SLURM. Here's what they look like in the context of a rule.

```
rule quality_trim:
    input: 
        reads="rnaseq/raw_data/{sample}.fq.gz",
        adapters="TruSeq2-SE.fa",
    output: "rnaseq/quality/{sample}.qc.fq.gz"
    threads: 1
    resources:
        mem_mb=1000,
        runtime=10
    shell:
        """
        trimmomatic SE {input.reads} {output} \
        ILLUMINACLIP:{input.adapters}:2:0:15 \
        LEADING:2 TRAILING:2 SLIDINGWINDOW:4:2 MINLEN:25    
        """
```

### Allocating additional resources on subsequent submission attempts

You can also set the resources based on the number of `attempts` for running a specific rule. Snakemake will resubmit failed jobs according to your `restart-times` settings (we set this to 3 in our profile).

```
rule:
    input:    ...
    output:   ...
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 1000
    shell:
        "..."
```
Here, if you have the `restart-times` set to 3, then the rule will run with 1000mb (1 Gb) of memory on its first attempt, 2000mb/2Gb on second attempt, and 3000mb/3Gb on third attempt, and 4000mv/4Gb on the final attempt ("third restart time").

For more information, see the [resources documentation](https://snakemake.readthedocs.io/en/stable/snakefiles/rules.html#resources)!


## Logging and Benchmarking

Snakemake has some handy utilities for logging and benchmarking the memory and time used by each job.

Add the files to your rule specification like so:
```
rule:
    input:    ...
    output:   ...
    log: "logs/rulename.log"
    benchmark: "benchmarks/rulename.benchmark"
    shell:
        "..."
```
Snakemake will automatically write to the benchmark file, but we need to tell snakemake how to use the log file.

To write the `stdout` to the log, add `> {log}` to the end of your shell command
To write the `stderr` to the log file, add `2> {log}`

Here's what writing `stdout` to log looks like for our earlier rule:

```
rule quality_trim:
    input: 
        reads="rnaseq/raw_data/{sample}.fq.gz",
        adapters="TruSeq2-SE.fa",
    output: "rnaseq/quality/{sample}.qc.fq.gz"
    threads: 1
    resources:
        mem_mb=1000,
        runtime=10
    log: "logs/{sample}.quality_trim.log"
    benchmark: "benchmarks/{sample}.quality_trim.benchmark"
    shell:
        """
        trimmomatic SE {input.reads} {output} \
        ILLUMINACLIP:{input.adapters}:2:0:15 \
        LEADING:2 TRAILING:2 SLIDINGWINDOW:4:2 MINLEN:25 > {log}
        """
```
> Note that we need to include the `{sample}` wildcard in the log and benchmark files, because a unique file must be created for each run of this rule.

### Reading Benchmark Files

_ran out of time to write this out fully. Check out this stack overflow:_ https://stackoverflow.com/questions/46813371/meaning-of-the-benchmark-variables-in-snakemake

## Keeping Track of your Run Commands

- I use a `run_snakes.sh` script with the shell commands that can be executed with `source run_snakes.sh`. Open to better ideas!
- Using this file for running large snakefiles in batches with `--batch`
  eg. this:
   
```
for i in $(seq 1 10)
 do
  snakemake  --profile slurm_farm --cluster-config cluster_config.yml --batch all=$i/10 --jobs 20
 done
```
> This for loop runs the Snakemake workflow in 10 batches

## Other helpful notes


### Exiting tmux (when finished)

- Exit tmux by `Ctrl-b`, `d`
- Reattach to your tmux session with `tmux attach`
    - If you have multiple sessions, do `tmux ls` to see all open session names, and the attach to the right one with `tmux attach -t <NAME>`

### Exiting srun (when finished)

- Exit an srun session with `exit`. `srun` sessions will close automatically at their time limit.

### Additional Snakemake Conda options

There are more options for using conda with snakemake. See all the conda-related options by running:
```
snakemake --help | grep conda
```

Here are Snakemake `5.21.0`'s conda options:
```
  --use-conda           If defined in the rule, run job in a conda
                        environment. If this flag is not set, the conda
  --list-conda-envs     List all conda environments and their location on
  --conda-prefix DIR    Specify a directory in which the 'conda' and 'conda-
                        store conda environments and their archives,
                        directory. If supplied, the `--use-conda` flag must
  --conda-cleanup-envs  Cleanup unused conda environments. (default: False)
  --conda-cleanup-pkgs [{tarballs,cache}]
                        Cleanup conda packages after creating environments. In
  --conda-create-envs-only
                        If specified, only creates the job-specific conda
                        environments then exits. The `--use-conda` flag must
  --conda-frontend {conda,mamba}
                        Choose the conda frontend for installing environments.
                        (default: conda)
                        can be combined with --use-conda and --use-
```

## Add aliases for commonly-used commands

These are in my `.bashrc`
```
alias qu="squeue -u ntpierce"
alias gq="squeue -A ctbrowngrp"
alias jobinfo="scontrol show -d job "
```

## Using cluster local tempdir

When you have jobs that do a lot of reading/writing of files, it can sometimes help to have them write to the local computer they're running on, rather that the connected system. Snakemake enables this with the `shadow` directive, which "shadows", or links your working directory over to the "shadow directory" you specify, allows the output to be directly written there, and then copies the output over to your desired output directory. More info in the docs [here](https://snakemake.readthedocs.io/en/stable/snakefiles/rules.html#shadow-rules)

To use this,

1. Make sure you have a directory on `/scratch`
```
mkdir -p /scratch/USERNAME
```

3. add the `shadow` directive to your rule (I usually use `shadow: minimal`)

```
rule:
    input:    ...
    output:   ...
    shadow: shallow
    shell:
        "..."
```

3. add `--shadow-prefix /scratch/USERNAME` (your directory) to the snakemake command line invocation


## What is a command prompt, anyway?


When you log in to `farm`, your prompt should look something like this:

![](https://i.imgur.com/UnviWMB.png  =300x)

> `(base)` indicates that you're in your `base` conda environment
> `ntpierce` is my username (yours will be different)
> `@farm` indicates that you're logged in to farm
> `~` indicates I am currently in my home (`~`) directory
> `$` is the terminal prompt, after which you can type

You can set workflow default resources for _all_ jobs in a snakefile via the `cluster_config.yml` file or at the command line (`--default-resources`).
