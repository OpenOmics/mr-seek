def phenotype_filter_input(wildcards):
    #if database == 'neale':
        if keyword:
            return(join(workpath, "query", "phenotype_id.csv"))
        else:
            return(outcome)

def neale_preprocess_input(wildcards):
    if database == 'neale':
        return(join(workpath, "query", "phenotype_id_filter.csv"))
        # if keyword:
        #     return(join(workpath, "query", "phenotype_id.csv"))
        # else:
        #     return(outcome)

def mr_flags(wildcards):
    flags = []
    if input_format != None:
        flags.append(f"--exp_flag {input_format}")
    if database != None:
        flags.append(f"--database {database}")
    if clump == 'True':
        flags.append(f"--clump")
    if threshold != None:
        flags.append(f"--pval {threshold}")
    return(' '.join(flags))

def twosamplemr_outcome_input(wildcards):
    #if database == 'ieu':
    #    if keyword:
    #        return([join(workpath, "query", "phenotype_id.csv")])
    #elif database == 'neale':
        return(join(workpath, "query", "phenotype_id_filter.csv"))
        # if keyword:
        #     checkpoint_output = checkpoints.phenotype_filter.get(**wildcards).output['phenotype_list']
        #     with open(checkpoint_output) as f:
        #         gwases = f.read().strip().split('\n')
        #         samples = [i.replace('.tsv.bgz', '') for i in gwases]
        #         return(expand(os.path.join(workpath, "gwas", "{sample}.rsid.tsv.gz"), sample=samples))
        # else:
        #     with open(outcome) as f:
        #         gwases = f.read().strip().split('\n')
        #         samples = [i.replace('.tsv.bgz', '') for i in gwases]
        #         return(expand(os.path.join(workpath, "gwas", "{sample}.rsid.tsv.gz"), sample=samples))
    #return(outcome)

def twosamplemr_outcome_flag(wildcards):
    return(','.join(twosamplemr_outcome_input(wildcards)))

def rds_plot_flags(wildcards):
    names = {'ieu': 'ieuGWAS', 'neale': 'Pan-UKBB'}
    flags = {'manifest':dict(), 'manifest_name': dict()}
    for key in config["database_manifest"].keys():
        flags['manifest'][key] = config["database_manifest"][key]
        flags['manifest_name'][key] = names[key]
    return(' '.join([f"--{flag} " + ','.join(flags[flag].values()) for flag in flags]))



rule neale_preprocess:
    #input: phenotype_list = neale_preprocess_input
    input: phenotype_list = join(workpath, "query", "phenotype_id_filter.csv")
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

rule phenotype_query:
    input:
        query = outcome
    output:
        phenotype_list = join(workpath, "query", "phenotype_id.csv"),
        phenotype_metadata = join(workpath, "query", "phenotype_metadata.tsv")
    params:
        rname = "phenotype_query",
        script = join(workpath, "workflow", "scripts", f"{database}_phenotype_query.R"),
        manifest = config['database_manifest'][database]
    container: config["images"]["mr-base"]
    shell:
        """
        Rscript {params.script} --query {input.query} \\
            --manifest {params.manifest} \\
            --output {output.phenotype_list} \\
            --metadata {output.phenotype_metadata}
        """

rule phenotype_filter:
    input:
        query = phenotype_filter_input
    output:
        phenotype_list = join(workpath, "query", "phenotype_id_filter.csv"),
        phenotype_metadata = join(workpath, "query", "phenotype_metadata_filter.tsv")
    params:
        rname = "phenotype_query",
        script = join(workpath, "workflow", "scripts", f"{database}_phenotype_filter.R"),
        pop_flag = population,
        error_log = errorlog,
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

rule twosamplemr:
    input:
        exposure = exposure,
        outcome = rules.phenotype_filter.output.phenotype_list
    output:
        single = join(workpath, "mr", "res_single.tsv"),
        res = join(workpath, "mr", "res.tsv"),
        data = join(workpath, "mr", "harmonised_dat.tsv"),
        loo = join(workpath, "mr", "res_loo.tsv"),
        heterogeneity = join(workpath, "mr", "mr_heterogeneity.tsv"),
        pleiotropy = join(workpath, "mr", "mr_pleiotropy.tsv"),
        sessionInfo = join(workpath, "mr", "twosamplemr_session.log")
    log:
        join(workpath, "mr", "twosamplemr.log")
    params:
        rname = "twosamplemr",
        outdir = join(workpath, "mr"),
        exposure = ','.join(exposure),
        outcome = twosamplemr_outcome_input,
        pop_flag = population,
        add_flag = mr_flags,
        error_log = errorlog,
        path = config["database"]["neale"],
        script = join(workpath, "workflow", "scripts", "twosamplemr.R")
    container: config["images"]["mr-base"]
    shell:
        """
        Rscript {params.script} \\
            --workdir {params.outdir} \\
            --exp "{params.exposure}" \\
            --out "{params.outcome}" \\
            --pop {params.pop_flag} \\
            --path {params.path} \\
            --error {params.error_log} \\
            {params.add_flag} \\
         > {log} 2>&1
        """

rule rds_plot:
    input:
        single = rules.twosamplemr.output.single,
        res = rules.twosamplemr.output.res,
        data = rules.twosamplemr.output.data,
        loo = rules.twosamplemr.output.loo,
        heterogeneity = rules.twosamplemr.output.heterogeneity,
        pleiotropy = rules.twosamplemr.output.pleiotropy,
        sessionInfo = rules.twosamplemr.output.sessionInfo,
        phenotype_metadata = rules.phenotype_filter.output.phenotype_metadata
    output:
        rds = join(workpath, "mr", "all_plots.rds")
    log:
        join(workpath, "mr", "rds_plot.log")
    params:
        rname = "rds_plot",
        error = errorlog,
        additional_flags = rds_plot_flags,
        script = join(workpath, "workflow", "scripts", "twosamplemr_report.R")
    container: config["images"]["mr-base"]
    shell:
        """
        Rscript {params.script} --res {input.res} \\
            --data {input.data} \\
            --single {input.single} \\
            --loo {input.loo} \\
            --heterogeneity {input.heterogeneity} \\
            --pleiotropy {input.pleiotropy} \\
            --metadata {input.phenotype_metadata} \\
            --out {output.rds} \\
            --version {input.sessionInfo} \\
            --failed {params.error} \\
            --include_data \\
            {params.additional_flags} \\
            > {log} 2>&1
        """

onsuccess:
    shell("""sleep 10; ./workflow/scripts/jobby $(grep --color=never "^Submitted .* with external jobid" ./logfiles/snakemake.log | awk '{{print $NF}}'  | sed "s/['.]//g" | sort | uniq | tr "\\n" " ")  > pipeline_job_status.tsv""")

onerror:
    shell("""sleep 10; ./workflow/scripts/jobby $(grep --color=never "^Submitted .* with external jobid" ./logfiles/snakemake.log | awk '{{print $NF}}'  | sed "s/['.]//g" | sort | uniq | tr "\\n" " ")  > pipeline_job_status.tsv""")
