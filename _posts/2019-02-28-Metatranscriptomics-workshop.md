---
layout: post
title: Metatranscriptomics workshop & development
modified: 2019-02-28
authors: N. Tessa Pierce, Taylor Reiter
tags: cicese, workshop, metatranscriptomics
comments: true
---
by N. Tessa Pierce and Taylor Reiter

In early November, we ran a workshop at CICESE, the Center for Scientific Research and Higher Education, in Ensenada, Baja California. This was the lab's second time at CICESE: last year, Phil Brooks, Harriet Alexander, and Titus taught a Metagenomics workshop.

As we had some requests for metatranscriptomics, and a number of researchers at CICESE work on ocean data, we thought it would be neat build some new training materials and databases using TARA Oceans metatranscriptome samples, from stations in the Eastern Pacific not too far from baja California. The TARA oceans expedition (2009-2013) generated amplicon, metagenome, and metatranscriptome data for a number of different size fractions from two depths at over 210 stations all across the globe. These datasets are all linked to environmental sampling data taken at each station. We chose TARA Stations 135, 136, and 137 in the eastern Pacific, and selected metatranscriptome samples in the 5-20µm size fraction, as they had good replication across these sites. These mRNAseq libraries were generated using polyA selection, so they should contain mostly eukaryotic transcriptome sequence. These data (from all TARA stations) were recently analyzed in [Carradec et al., 2018](https://www.nature.com/articles/s41467-017-02342-1).

As with any of our workshops, we have no illusions about teaching  all of bioinformatics in two days, but instead try to take attendees about 80% of the way through a set of analyses, and equip them with a set of good troubleshooting practices. The workshop starts with tools that will be useful in a variety of different sequence analyses (read quality control, assembly, etc), and then adds some domain-specific lessons. Resources for this workshop can be found [here!](https://ngs-docs.github.io/2018-cicese-metatranscriptomics/).

We had a few issues getting all the students running on CICESE's cluster, but in the end, it may have helped break the ice and get everyone talking to us and each other, as we had some great group interaction and questions throughout the workshop.

For the few domain-specific analyses we could show, we thought it'd be neat to do some k-mer based taxonomic classification using sourmash. We hadn't yet done sourmash taxonomic classification with eukaryotes, so we had to generate some new databases. First, we built a GenBank eukaryotic database using `rna_from_genomic` files available for some genomes. These should be applicable to many sequencing projects, but since the ocean is relatively undersampled in genbank, we also generated a database from the Marine Microbial Eukaryotic Transcriptome Sequencing Project (MMETSP) transcriptomes [recently reassembled](https://www.biorxiv.org/content/early/2018/05/17/323576). We've made these databases available on [OSF](https://osf.io/a46zr/) in the sourmash_databases folder.

After making sourmash signatures of an assembly (generated from 5-20µm size fraction at station 135) we unfortunately found no matches to the genbank database. However, we did find 12 matches to the MMETSP database, covering ~5% of the assembly. Although it was rewarding to those few matches, this was a good reminder that many things currently being sequenced don't have close taxonomic relatives in publicly available databases.


A second analysis we did was adapted from the [Carradec et al. 2018](https://www.nature.com/articles/s41467-017-02342-1) paper. Because sourmash gather only taxonomically classified 5% of the sample, we wanted to get a better estimate of the number of transcriptomes that were present. Carradec et al. did this by aligning reads to known sequences of single-copy orthologs and estimating the number of sequences present using these alignments. In the spirit of this analysis, we assembled one sample using MEGAHIT and annotated the open reading frames using dammit (which uses Transdecoder). Using the ORFs predicted from our assembly, we searched for amino acid sequences that matched the HMM profile for the single copy ortholog RpsG. From the sequences we identified, we (arbitrarily) clustered at 97% using CD-HIT. After clustering, we found 82 sequences for RpsG in our assembly. This was more than the number of species we were able to identify using sourmash gather! Even still, we probably missed a substantial number of transcriptomes -- only 40% of our reads mapped back to the assembly, meaning the majority of reads did not assemble. Because we were working with ORFs predicted from the assembly, we would not capture any single copy ortholog unassembled in the reads. Although we only did this lesson with one HMM profile, we compiled the list of orthologs used by Caradec et al at the bottom of the lesson.


Even though the topic was ostensibly _Metatranscriptomics_, our main goal is always to give atendees some command-line experience and get them comfortable with the challenges of running bioinformatic analyses. I hope we accomplished this goal, because we had a great time with a very engaged group of people. Our host Asuncion organized some fabulous evenings for us and made sure everything ran as smoothly as possible and got us over the hiccups that come with having a whole workshop running on a single institutional cluster (shout out to Sylvia for all of her help)!


This was our first metatranscriptomics workshop, and we would be happy to hear critiques and suggestions that may help us improve and refine these materials in the years to come. Materials [here](https://ngs-docs.github.io/2018-cicese-metatranscriptomics/).
