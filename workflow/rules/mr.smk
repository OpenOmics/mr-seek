def exposure_flag(wildcards):
    return('')

rule neale_download:
    output: gwas = os.path.join(workpath, "gwas/{sample}.rsid.tsv.gz")
    params:
        rname = "neale_download",
        sample = "{sample}",
        gwas = os.path.join(workpath, "gwas/{sample}.rsid"),
        tmpdir = tmpdir,
        threshold = threshold,
        threads = 16
    shell:
      """
      cd {params.tmpdir}
      wget https://pan-ukb-us-east-1.s3.amazonaws.com/sumstats_flat_files/{params.sample}.tsv.bgz
      python3 /data/chenv3/NATAN/project/NHLBI-54/baseline/workflow/scripts/gwas_snp.py -o {params.sample}.convert.tsv -i {params.sample}.tsv.bgz -t {params.threshold} -p EUR --filter
      module load VEP/108; vep -i {params.sample}.convert.tsv -o {params.sample}.vep.tsv --offline --cache --dir_cache /fdb/VEP/108/cache --assembly GRCh37 --pick --check_existing --fork {params.threads}
      python3 /data/chenv3/NATAN/project/NHLBI-54/baseline/workflow/scripts/gwas_fill_rsid.py -o {params.gwas} -i filter.{params.sample}.convert.tsv.gz -v {params.sample}.vep.tsv
      """

rule twosamplemr:
    input:
        exposure = exposure,
        outcome = outcome
    output:
        rds = join(workpath, "mr", "res_single.csv")
    log:
        join(workpath, "mr", "twosamplemr.log")
    params:
        rname = "twosamplemr",
        outdir = join(workpath, "mr"),
        exposure = exposure,
        outcome = outcome,
        flag = exposure_flag,
        script = join("workflow", "scripts", "twosamplemr.R")
    envmodules: config["tools"]["r4"]
    shell:
        """
        R --no-save --args \\
            {params.outdir} \\
            {input.exposure} \\
            {input.outcome} \\
            {params.flag} \\
        < {params.script} > {log}
        """
