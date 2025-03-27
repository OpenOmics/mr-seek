<div align="center">

  <h1 style="font-size: 250%">mr-seek 🔬</h1>

  <b><i>Mendelian randomization pipeline</i></b><br> 
  <a href="https://doi.org/10.5281/zenodo.15096585">
      <img src="https://zenodo.org/badge/DOI/10.5281/zenodo.15096585.svg" alt="DOI">
  </a>
  <a href="https://github.com/OpenOmics/mr-seek/releases">
    <img alt="GitHub release" src="https://img.shields.io/github/v/release/OpenOmics/mr-seek?color=blue&include_prereleases">
  </a>
  <a href="https://hub.docker.com/repository/docker/skchronicles/mr-seek">
    <img alt="Docker Pulls" src="https://img.shields.io/docker/pulls/skchronicles/mr-seek">
  </a><br>
  <a href="https://github.com/OpenOmics/mr-seek/actions/workflows/main.yaml">
    <img alt="tests" src="https://github.com/OpenOmics/mr-seek/workflows/tests/badge.svg">
  </a>
  <a href="https://github.com/OpenOmics/mr-seek/actions/workflows/docs.yml">
    <img alt="docs" src="https://github.com/OpenOmics/mr-seek/workflows/docs/badge.svg">
  </a>
  <a href="https://github.com/OpenOmics/mr-seek/issues">
    <img alt="GitHub issues" src="https://img.shields.io/github/issues/OpenOmics/mr-seek?color=brightgreen">
  </a>
  <a href="https://github.com/OpenOmics/mr-seek/blob/main/LICENSE">
    <img alt="GitHub license" src="https://img.shields.io/github/license/OpenOmics/mr-seek">
  </a>

  <p>
    This is the home of the pipeline, mr-seek. Its long-term goals: to perform Mendelian randomization analysis like no pipeline before!
  </p>

</div>  


## Overview
Welcome to mr-seek's documentation! This guide is the main source of documentation for users that are getting started with the [Mendelian randomization pipeline](https://github.com/OpenOmics/mr-seek/). 

The **`./mr-seek`** pipeline is composed several inter-related sub commands to setup and run the pipeline across different systems. Each of the available sub commands perform different functions: 

 * [<code>mr-seek <b>run</b></code>](usage/run.md): Run the mr-seek pipeline with your input files.
 * [<code>mr-seek <b>unlock</b></code>](usage/unlock.md): Unlocks a previous runs output directory.
 * [<code>mr-seek <b>cache</b></code>](usage/cache.md): Cache remote resources locally, coming soon!

**mr-seek** is a comprehensive mendelian randomization pipeline. It relies on technologies like [Singularity<sup>1</sup>](https://singularity.lbl.gov/) to maintain the highest-level of reproducibility. The pipeline consists of a series of data processing and quality-control steps orchestrated by [Snakemake<sup>2</sup>](https://snakemake.readthedocs.io/en/stable/), a flexible and scalable workflow management system, to submit jobs to a cluster.

The pipeline is compatible with data generated from Illumina short-read sequencing technologies. As input, it accepts a set of QTL files and outcome phenotypes and can be run locally on a compute instance or on-premise using a cluster. A user can define the method or mode of execution. The pipeline can submit jobs to a cluster using a job scheduler like SLURM (more coming soon!). A hybrid approach ensures the pipeline is accessible to all users.

Before getting started, we highly recommend reading through the [usage](usage/run.md) section of each available sub command.

For more information about issues or trouble-shooting a problem, please checkout our [FAQ](faq/questions.md) prior to [opening an issue on Github](https://github.com/OpenOmics/mr-seek/issues).

## Contribute 

This site is a living document, created for and by members like you. mr-seek is maintained by the members of NCBR and is improved by continuous feedback! We encourage you to contribute new content and make improvements to existing content via pull request to our [GitHub repository :octicons-heart-fill-24:{ .heart }](https://github.com/OpenOmics/mr-seek).

## Citation

If you use this software, please cite it as below:  

=== "BibTex"

    ```
    @software{Chen_Kuhn_OpenOmics_mr-seek_2025,
      author       = {Chen, Vicky and
                      Kuhn, Skyler and
                      Paul, Subrata and
                      Redekar, Neelam},
      title        = {OpenOmics/mr-seek},
      month        = mar,
      year         = 2025,
      publisher    = {Zenodo},
      doi          = {10.5281/zenodo.15096585},
      url          = {https://doi.org/10.5281/zenodo.15096585}
    }
    ```

=== "APA"

    ```
    Chen, V., Kuhn, S., Paul, S., & Redekar, N. (2025). OpenOmics/mr-seek. Zenodo. https://doi.org/10.5281/zenodo.15096585
    ```

For more citation style options, please visit the pipeline's [Zenodo page](https://doi.org/10.5281/zenodo.15096585).

## References
<sup>**1.**  Kurtzer GM, Sochat V, Bauer MW (2017). Singularity: Scientific containers for mobility of compute. PLoS ONE 12(5): e0177459.</sup>  
<sup>**2.**  Koster, J. and S. Rahmann (2018). "Snakemake-a scalable bioinformatics workflow engine." Bioinformatics 34(20): 3600.</sup>  
