# <code>mr-seek <b>run</b></code>

## 1. About
The `mr-seek` executable is composed of several inter-related sub commands. Please see `mr-seek -h` for all available options.

This part of the documentation describes options and concepts for <code>mr-seek <b>run</b></code> sub command in more detail. With minimal configuration, the **`run`** sub command enables you to start running mr-seek pipeline.

Setting up the mr-seek pipeline is fast and easy! In its most basic form, <code>mr-seek <b>run</b></code> only has *three required inputs*.

## 2. Synopsis
```text
$ mr-seek run [--help] \
      [--mode {slurm,local}] [--job-name JOB_NAME] [--batch-id BATCH_ID] \
      [--tmp-dir TMP_DIR] [--silent] [--sif-cache SIF_CACHE] \
      [--singularity-cache SINGULARITY_CACHE] \
      [--dry-run] [--threads THREADS] \
      --exposure EXPOSURE \
      --outcome OUTCOME \
      --output OUTPUT
```

The synopsis for each command shows its arguments and their usage. Optional arguments are shown in square brackets.

A user **must** provide a list of exposure and outcome to analyze via `--exposure`  and `--outcome` arguments and an output directory to store results via `--output` argument.

Use you can always use the `-h` option for information on a specific command.

### 2.1 Required arguments

Each of the following arguments are required. Failure to provide a required argument will result in a non-zero exit-code.

  `--exposure EXPOSURE [EXPOSURE ...]`  
> **Input exposure QTL or phenotype list.**  
> *type: file*  
>
> The file should be either a list of exposures available in a database or exposure file to read and process. If a QTL file is provided then an additional flag should be used to define the format it is. Currently support is only available for one file at a time.
>
> ***Example:*** `--exposure eQTL.csv`

---  
`--outcome OUTCOME [OUTCOME ...]`  
> **Input outcome QTL or phenotype list.**  
> *type: file*  
>
> The file should be either a list of outcomes available in a database or exposure file to read and process. Currently support is only available for one file at a time. An additional flag should be used to specify which database to extract the entries from.
>
> ***Example:*** `--outcome outcome.csv`

---  
  `--output OUTPUT`
> **Path to an output directory.**   
> *type: path*
>   
> This location is where the pipeline will create all of its output files, also known as the pipeline's working directory. If the provided output directory does not exist, it will be created automatically.
>
> ***Example:*** `--output /data/$USER/mr-seek_out`

### 2.2 Analysis options

Each of the following arguments are optional, and do not need to be provided.

`--input_qtl {eqtl, mqtl, pqtl}`
> **Type of QTL file provided**   
> *type: string*
>   
> When the exposure file is a quantitative trait locus file to process, this flag should be used to define the type of QTL file it is. Currently only pqtl format is supported. Work is still being done to support eqtl and mqtl files in the future. Valid options are eqtl, mqtl, or pqtl.
>
> ***Example:*** `--input_qtl pqtl`

---
`--pop {AFR, AMR, EAS, EUR}`
> **Super-population to use**   
> *type: string*
>   
> Super-population to use when extracting data from Neale (PAN-UK BioBank) or when clumping data. Currently only populations shared with the 1000 Genomes project is supported. Valid options for this are: AFR, AMR, EAS, EUR. If this option is not provided it will default to EUR.
>
> ***Example:*** `--pop EUR`

---
`--database {ieu, neale}`
> **Database to use**   
> *type: string*
>   
> Database to extract phenotypes from when a list of phenotypes are provided. The ieu option would extract data for the IEU GWAS database made available through the R package [ieugwasr](https://mrcieu.github.io/ieugwasr/). The neale option would use the [PAN-UK Biobank](https://pan.ukbb.broadinstitute.org) data hosted on Biowulf. The PAN-UK Biobank data will be processed prior to analysis.
>
> ***Example:*** `--database neale`

---
`--outcome_pval_threshold THRESHOLD`
> **P-Value threshold to filter PAN-UK Biobank SNPs**   
> *type: float*
>   
> Float value that will be used as a p-value threshold to filter the PAN-UK Biobank SNPs. If no threshold is provided then no filter would be used. 
>
> ***Example:*** `--outcome_pval_threshold 0.01`

---
`--clump`
> **Perform clumping on harmonised data**   
> *type: boolean flag*
>   
> Perform clumping on the data. Clumping will be run with the super-population available in the 1000 genomes reference panel.
>
> ***Example:*** `--clump`

### 2.3 Orchestration options

Each of the following arguments are optional, and do not need to be provided.

  `--dry-run`            
> **Dry run the pipeline.**  
> *type: boolean flag*
>
> Displays what steps in the pipeline remain or will be run. Does not execute anything!
>
> ***Example:*** `--dry-run`

---  
  `--silent`            
> **Silence standard output.**  
> *type: boolean flag*
>
> Reduces the amount of information directed to standard output when submitting master job to the job scheduler. Only the job id of the master job is returned.
>
> ***Example:*** `--silent`

---  
  `--mode {slurm,local}`  
> **Execution Method.**  
> *type: string*  
> *default: slurm*
>
> Execution Method. Defines the mode or method of execution. Vaild mode options include: slurm or local.
>
> ***slurm***    
> The slurm execution method will submit jobs to the [SLURM workload manager](https://slurm.schedmd.com/). It is recommended running mr-seek in this mode as execution will be significantly faster in a distributed environment. This is the default mode of execution.
>
> ***local***  
> Local executions will run serially on compute instance. This is useful for testing, debugging, or when a user does not have access to a high performance computing environment. If this option is not provided, it will default to a local execution mode.
>
> ***Example:*** `--mode slurm`

---  
  `--job-name JOB_NAME`  
> **Set the name of the pipeline's master job.**  
> *type: string*
> *default: pl:mr-seek*
>
> When submitting the pipeline to a job scheduler, like SLURM, this option always you to set the name of the pipeline's master job. By default, the name of the pipeline's master job is set to "pl:mr-seek".
>
> ***Example:*** `--job-name pl_id-42`

---  
  `--singularity-cache SINGULARITY_CACHE`  
> **Overrides the $SINGULARITY_CACHEDIR environment variable.**  
> *type: path*  
> *default: `--output OUTPUT/.singularity`*
>
> Singularity will cache image layers pulled from remote registries. This ultimately speeds up the process of pull an image from DockerHub if an image layer already exists in the singularity cache directory. By default, the cache is set to the value provided to the `--output` argument. Please note that this cache cannot be shared across users. Singularity strictly enforces you own the cache directory and will return a non-zero exit code if you do not own the cache directory! See the `--sif-cache` option to create a shareable resource.
>
> ***Example:*** `--singularity-cache /data/$USER/.singularity`

---  
  `--sif-cache SIF_CACHE`
> **Path where a local cache of SIFs are stored.**  
> *type: path*  
>
> Uses a local cache of SIFs on the filesystem. This SIF cache can be shared across users if permissions are set correctly. If a SIF does not exist in the SIF cache, the image will be pulled from Dockerhub and a warning message will be displayed. The `mr-seek cache` subcommand can be used to create a local SIF cache. Please see `mr-seek cache` for more information. This command is extremely useful for avoiding DockerHub pull rate limits. It also remove any potential errors that could occur due to network issues or DockerHub being temporarily unavailable. We recommend running mr-seek with this option when ever possible.
>
> ***Example:*** `--singularity-cache /data/$USER/SIFs`

---  
  `--threads THREADS`   
> **Max number of threads for each process.**  
> *type: int*  
> *default: 2*
>
> Max number of threads for each process. This option is more applicable when running the pipeline with `--mode local`.  It is recommended setting this vaule to the maximum number of CPUs available on the host machine.
>
> ***Example:*** `--threads 12`


---  
  `--tmp-dir TMP_DIR`   
> **Path to temporary directory.**  
> *type: path*  
> *default: `/lscratch/$SLURM_JOBID`*
>
> Path on the file system for writing temporary output files. By default, the temporary directory is set to '/lscratch/$SLURM_JOBID' for backwards compatibility with the NIH's Biowulf cluster; however, if you are running the pipeline on another cluster, this option will need to be specified. Ideally, this path should point to a dedicated location on the filesystem for writing tmp files. On many systems, this location is set to somewhere in /scratch. If you need to inject a variable into this string that should NOT be expanded, please quote this options value in single quotes.
>
> ***Example:*** `--tmp-dir /scratch/$USER/`

### 2.4 Miscellaneous options  
Each of the following arguments are optional, and do not need to be provided.

  `-h, --help`            
> **Display Help.**  
> *type: boolean flag*
>
> Shows command's synopsis, help message, and an example command
>
> ***Example:*** `--help`

## 3. Example
```bash
# Step 1.) Grab an interactive node,
# do not run on head node!
srun -N 1 -n 1 --time=1:00:00 --mem=8gb  --cpus-per-task=2 --pty bash
module purge
module load singularity snakemake

# Step 2A.) Dry-run the pipeline
./mr-seek run --exposure .tests/pqtl.csv \
                  --outcome .tests/ieu_10.csv \
                  --output /data/$USER/output \
                  --database ieu \
                  --mode slurm \
                  --dry-run

# Step 2B.) Run the mr-seek pipeline
# The slurm mode will submit jobs to
# the cluster. It is recommended running
# the pipeline in this mode.
./mr-seek run --exposure .tests/pqtl.csv \
                  --outcome .tests/ieu_10.csv \
                  --output /data/$USER/output \
                  --database ieu \
                  --mode slurm
```
