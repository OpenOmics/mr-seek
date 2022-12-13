def mr_flags(wildcards):
    flags = []
    if input_format != None:
        flags.append(f"--exp_flag {input_format}")
    if database != None:
        flags.append(f"--database {database}")
    if clump == 'True':
        flags.append(f"--clump")
    return(' '.join(flags))

def mr_outcome_input(wildcards):
    if database == 'neale':
        with open(outcome) as f:
            gwases = f.read().strip().split('\n')
            samples = [i.replace('.tsv.bgz', '') for i in gwases]
            return(expand(os.path.join(workpath, "gwas", "{sample}.rsid.tsv.gz"), sample=samples))
    else:
        return(outcome)

def mr_outcome_flag(wildcards):
    if database == 'neale':
        with open(outcome) as f:
            gwases = f.read().strip().split('\n')
            samples = [i.replace('.tsv.bgz', '') for i in gwases]
            return(','.join(expand(os.path.join(workpath, "gwas", "{sample}.rsid.tsv.gz"), sample=samples)))
    else:
        return(outcome)

rule neale_download:
    output: gwas = os.path.join(workpath, "gwas/{sample}.rsid.tsv.gz")
    params:
        rname = "neale_download",
        sample = "{sample}",
        gwas = os.path.join(workpath, "gwas/{sample}.rsid"),
        tmpdir = tmpdir,
        threshold = threshold,
        population = population,
        snp_script = os.path.join(workpath, 'workflow', 'scripts', 'gwas_snp.py'),
        rsid_script = os.path.join(workpath, 'workflow', 'scripts', 'gwas_fill_rsid.py'),
        threads = 16
    shell:
      """
      cd {params.tmpdir}
      wget https://pan-ukb-us-east-1.s3.amazonaws.com/sumstats_flat_files/{params.sample}.tsv.bgz
      python3 {params.snp_script} -o {params.sample}.convert.tsv -i {params.sample}.tsv.bgz -t {params.threshold} -p {params.population} --filter
      module load VEP/108; vep -i {params.sample}.convert.tsv -o {params.sample}.vep.tsv --offline --cache --dir_cache /fdb/VEP/108/cache --assembly GRCh37 --pick --check_existing --fork {params.threads}
      python3 {params.rsid_script} -o {params.gwas} -i filter.{params.sample}.convert.tsv.gz -v {params.sample}.vep.tsv
      """

rule twosamplemr:
    input:
        exposure = exposure,
        outcome = mr_outcome_input
    output:
        rds = join(workpath, "mr", "res_single.csv")
    log:
        join(workpath, "mr", "twosamplemr.log")
    params:
        rname = "twosamplemr",
        outdir = join(workpath, "mr"),
        exposure = exposure,
        outcome = mr_outcome_flag,
        pop_flag = population,
        add_flag = mr_flags,
        script = join(workpath, "workflow", "scripts", "twosamplemr.R")
    envmodules: config["tools"]["r4"]
    shell:
        """
        Rscript {params.script} \\
            --workdir {params.outdir} \\
            --exp {input.exposure} \\
            --out {params.outcome} \\
            --pop {params.pop_flag} \\
            {params.add_flag} \\
         > {log} 2>&1
        """
