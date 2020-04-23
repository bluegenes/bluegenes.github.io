---
layout: post
title: On Snakemake and wrappers for workflows
date: 2018-06-19
comments: true
---

A few months ago, Titus wrote about the dib-lab's [slow creep into the world of snakemake for workflow applications](http://ivory.idyll.org/blog/2018-workflows-applications.html). Thanks to some good examples and a lot of osmosis from the folks already using snakemake in the lab, I finally jumped in and now am re-implementing an updated version of our Eel Pond protocol for RNAseq as a snakemake workflow. 

As someone who once implemented an automated workflow by co-writing a custom task manager (see: unaware bioinformatics novice), I have really come to appreciate the power and flexibility of snakemake, especially with bioconda software management. Snakemake functions by allowing the user to write a "rule" for running a command or piece of software that contains all information for execution, including inputs, outputs, parameters, cpu, etc. In addition, snakemake natively provides conda integration to allow each rule to deploy individual conda environments to run the commands and software. In practice, this means if a software package has a conda recipe, we can quickly integrate that package into any workflow without considering installation and dependency issues. This is a huge step towards simplifying workflows, and is especially important for folks without extensive experience troubleshooting installations. Plus, the [snakemake documentation](https://snakemake.readthedocs.io/en/stable/) is wonderful and there are some good example workflows and [tutorials](http://snakemake.readthedocs.io/en/latest/tutorial/basics.html)!

Snakemake also provides integration with singularity, and suggests a solution for fully containerizing workflows: use singularity to define the operating system (ideally a container with miniconda installed), and then use conda to manage software and deploy individual conda virtual environments for running a workflow within that container. 

On top of these handy software management tools, there is a small but growing repository of snakemake "wrappers" for commonly-used programs. These wrappers allow the user to specify the program's command-line arguments as inputs and parameters within the snakemake rule, rather than writing out the full required shell command to run that program. They are ideally written to require only mandatory arguments and provide an "extra" parameter, which can be used to pass any number of optional arguments or additional flags to the program's command line.

This salmon index wrapper is one of the most straightforward:

```index_wrapper
from snakemake.shell import shell

log = snakemake.log_fmt_shell(stdout=True, stderr=True)
extra = snakemake.params.get("extra", "")

shell("salmon index -t {snakemake.input} -i {snakemake.output} "
      " --threads {snakemake.threads} {extra} {log}" )
```

and it can be run via the following Snakefile:

```salmon_index
    rule salmon_index:
    input:
        "assembly/transcriptome.fasta"
    output:
        "salmon/transcriptome_index"
    log:
        "logs/salmon/transcriptome_index.log"
    threads: 2
    params:
        # optional parameters
        extra=""
    wrapper:
        "0.25.0/bio/salmon/index"

```

Slightly more complex wrappers might take in multiple inputs, check for paired or single end reads, and ensure that the user is not violating any special rules required by the program. For example, the [Trinity](https://snakemake-wrappers.readthedocs.io/en/stable/wrappers/trinity.html) wrapper attempts to infer the required `seqtype` format from the input filenames and requires that the user have 'trinity' in the output folder name, in accordance with Trinity documentation. For some additional examples, see the [salmon quant](https://bitbucket.org/snakemake/snakemake-wrappers/src/master/bio/salmon/quant/quant-reads/wrapper.py) or [star](https://snakemake-wrappers.readthedocs.io/en/stable/wrappers/star/align.html) wrappers.


At first glance, wrappers simplify and standardize the process of writing a snakemake rule for each program. However, their real strength lies in providing versioning to enable reproducibility. By specifying a wrapper version tag or commit (which itself specifies a version of the software), updates to the wrapper or the software do not automatically propagate into workflows. The snakemake-wrappers repository is under active open development, and wrappers themselves are fairly formulaic and lend
themselves well to community-driven development. In the past couple weeks, I've contributed several, and my  labmate Lisa (@monsterbashseq) has taken up the mantle to provide a wrapper the [sourmash compute function](https://bitbucket.org/snakemake/snakemake-wrappers/src/master/bio/sourmash/compute/wrapper.py). Check out the [snakemake wrapper documentation](https://snakemake-wrappers.readthedocs.io/en/stable/) for more, including instructions on how to contribute.


While leveraging wrappers in snakemake workflows is incredibly powerful, we will be adding one more component for the eel pond protocol: a command-line interface. Titus wrote an example of a command-line interface for snakemake workflows at [2018-snakemake-cli](https://github.com/ctb/2018-snakemake-cli), and implemented one for spacegraphcats. The goal of this cli is to simplify running the snakemake workflows by handling the location of snakefiles and input of parameters and configuration. [Kind of like adding this bow](https://media.giphy.com/media/SwuIih96gsCpW/giphy.gif).

For many protocols, people are interested in running (or re-running) certain portions of the workflows to test parameters. With something like an RNA-Seq assembly, advanced users may wish to modify read pre-processing and check results, without running a transcriptome assembly each time they try different parameters. In addition, as new programs come into favor, users may want to select different packages for each step. This flexibility is something I hope to implement in the command-line interface for our Eel Pond workflow. 

One way to do this is to keep the rule for each program as its own file, so that it can be included or excluded in the workflow based on user-specified options. Snakemake works by starting with the final workflow targets, and building the job tree based on the rules that need to be run to build those final targets. In order to dynamically include or exclude different rules, each rule that might be an end point to the pipeline should be accompanied by a python function that can be used to calculate the files produced by that rule. These functions can be imported into the Snakefile and passed to snakemake's `rule all` when needed. Snakemake then can build the modified dependency graph to produce all required output!

I am still pretty new to snakemake and am figuring out the best way to implement these ideas and pass targets between rules that require many files (e.g. all illumina read data files) and a single file (e.g. the transcriptome assembly for annotation). However, I am excited that snakemake is enabling us to write flexible, versionable, extensible workflows that handle all installations under the hood!


tessa

ps. For the curious, here's the (in progress) [eel pond update](https://github.com/dib-lab/eelpond). In addition to working on the remaining rules, the commenting mess within the Snakefile will be replaced with functions to include certain rules based on cli input. If you think I should link eel pond in the text above, I would want to get that implemented before posting.
