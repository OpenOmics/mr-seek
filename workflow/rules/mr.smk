def neale_preprocess_input(wildcards):
    if database == 'neale':
        if keyword:
            return(join(workpath, "query", "phenotype_id.csv"))
        else:
            return(outcome)

def mr_flags(wildcards):
    flags = []
    if input_format != None:
        flags.append(f"--exp_flag {input_format}")
    if database != None:
        flags.append(f"--database {database}")
    if clump == 'True':
        flags.append(f"--clump")
    return(' '.join(flags))

def twosamplemr_outcome_input(wildcards):
    if database == 'ieu':
        if keyword:
            return([join(workpath, "query", "phenotype_id.csv")])
    elif database == 'neale':
        if keyword:
            checkpoint_output = checkpoints.phenotype_query.get(**wildcards).output['phenotype_list']
            with open(checkpoint_output) as f:
                gwases = f.read().strip().split('\n')
                samples = [i.replace('.tsv.bgz', '') for i in gwases]
                return(expand(os.path.join(workpath, "gwas", "{sample}.rsid.tsv.gz"), sample=samples))
        else:
            with open(outcome) as f:
                gwases = f.read().strip().split('\n')
                samples = [i.replace('.tsv.bgz', '') for i in gwases]
                return(expand(os.path.join(workpath, "gwas", "{sample}.rsid.tsv.gz"), sample=samples))
    return(outcome)

def twosamplemr_outcome_flag(wildcards):
    return(','.join(twosamplemr_outcome_input(wildcards)))

# rule neale_download:
#     output: gwas = os.path.join(workpath, "gwas/{sample}.rsid.tsv.gz")
#     params:
#         rname = "neale_download",
#         sample = "{sample}",
#         gwas = os.path.join(workpath, "gwas/{sample}.rsid"),
#         tmpdir = tmpdir,
#         threshold = threshold,
#         population = population,
#         snp_script = os.path.join(workpath, 'workflow', 'scripts', 'gwas_snp.py'),
#         rsid_script = os.path.join(workpath, 'workflow', 'scripts', 'gwas_fill_rsid.py'),
#         threads = 16
#     shell:
#       """
#       cd {params.tmpdir}
#       wget https://pan-ukb-us-east-1.s3.amazonaws.com/sumstats_flat_files/{params.sample}.tsv.bgz &&
#       python3 {params.snp_script} -o {params.sample}.convert.tsv -i {params.sample}.tsv.bgz -t {params.threshold} -p {params.population} --filter &&
#       module load VEP/108; vep -i {params.sample}.convert.tsv -o {params.sample}.vep.tsv --offline --cache --dir_cache /fdb/VEP/108/cache --assembly GRCh37 --pick --check_existing --fork {params.threads} &&
#       python3 {params.rsid_script} -o {params.gwas} -i filter.{params.sample}.convert.tsv.gz -v {params.sample}.vep.tsv || touch {output.gwas} {workpath}/{params.sample}.error
#       """

rule neale_preprocess:
    input: phenotype_list = neale_preprocess_input
    output: gwas = temp(os.path.join(workpath, "gwas/{sample}.rsid.tsv.gz"))
    params:
        rname = "neale_preprocess",
        sample = "{sample}",
        gwas = os.path.join(workpath, "gwas/{sample}.rsid"),
        tmpdir = tmpdir,
        threshold = threshold,
        population = population,
        snp_script = os.path.join(workpath, 'workflow', 'scripts', 'gwas_snp.py'),
        rsid_script = os.path.join(workpath, 'workflow', 'scripts', 'gwas_fill_rsid.py'),
        neale_path = config["database"]["neale"],
        threads = 16
    container: config["images"]["mr-base"]
    shell:
      """
      cd {params.tmpdir}
      python3 {params.snp_script} -o "{params.sample}.convert.tsv" -i "{params.neale_path}/{params.sample}.tsv.bgz" -t {params.threshold} -p {params.population} --filter &&
      mv "filter.{params.sample}.convert.tsv.gz" "{output.gwas}" || touch "{output.gwas}" "{workpath}/{params.sample}.error"
      """

rule twosamplemr:
    input:
        exposure = exposure,
        outcome = twosamplemr_outcome_input
    output:
        single = join(workpath, "mr", "res_single.tsv"),
        res = join(workpath, "mr", "res.tsv"),
        data = join(workpath, "mr", "harmonised_dat.tsv")
    log:
        join(workpath, "mr", "twosamplemr.log")
    params:
        rname = "twosamplemr",
        outdir = join(workpath, "mr"),
        exposure = ','.join(exposure),
        outcome = twosamplemr_outcome_flag,
        pop_flag = population,
        add_flag = mr_flags,
        script = join(workpath, "workflow", "scripts", "twosamplemr.R")
    container: config["images"]["mr-base"]
    shell:
        """
        Rscript {params.script} \\
            --workdir {params.outdir} \\
            --exp "{params.exposure}" \\
            --out "{params.outcome}" \\
            --pop {params.pop_flag} \\
            {params.add_flag} \\
         > {log} 2>&1
        """

rule rds_plot:
    input:
        single = rules.twosamplemr.output.single,
        res = rules.twosamplemr.output.res,
        data = rules.twosamplemr.output.data
    output:
        rds = join(workpath, "mr", "all_plots.rds")
    log:
        join(workpath, "mr", "rds_plot.log")
    params:
        rname = "rds_plot",
        script = join(workpath, "workflow", "scripts", "codes.R")
    container: config["images"]["mr-base"]
    shell:
        """
        Rscript {params.script} --res {input.res} \\
            --data {input.data} \\
            --single {input.single} \\
            --out {output.rds} \\
            > {log} 2>&1
        """

checkpoint phenotype_query:
    input:
        query = outcome
    output:
        phenotype_list = join(workpath, "query", "phenotype_id.csv"),
        phenotype_metadata = join(workpath, "query", "phenotype_metadata.csv")
    params:
        rname = "phenotype_query",
        script = join(workpath, "workflow", "scripts", f"{database}_phenotype_query.R"),
        pop_flag = population,
        error_log = "phenotype_query.error",
        manifest = config['database_manifest'][database]
    container: config["images"]["mr-base"]
    shell:
        """
        Rscript {params.script} --query {input.query} \\
            --pop {params.pop_flag} \\
            --manifest {params.manifest} \\
            --output {output.phenotype_list} \\
            --error {params.error_log} \\
            --metadata {output.phenotype_metadata}
        """
