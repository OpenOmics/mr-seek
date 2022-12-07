from gwas_convert import *
import gzip, os, argparse

rsid_index = 12

def main(raw_args=None):
    parser = argparse.ArgumentParser(description="""Take GWAS data and fill in RSID calls based on VEP output, filling SNPs with missing RSID with chromosome, position, reference, and alternate allele information""")
    parser.add_argument("-o", "--output", metavar="output.tsv.bgz",
        action = "store", type=str, required=True,
        help="Output file name, generated file with be a tab separated gzipped file (file suffix is automatically appended)")
    parser.add_argument("-i", "--input", metavar="gwas.tsv.bgz",
        action = "store", type=str, required=True,
        help="Input GWAS file")
    parser.add_argument("-v", "--vep", metavar="vepfile",
        action = "store", type=str, required=True,
        help="Path to the file containing the VEP results")
    args = parser.parse_args(raw_args)

    #with open(os.path.join(args.vep, f"{current}.tsv"), 'r') as h:
    with open(args.vep, 'r') as h:
        snp_rsid = dict()
        for hline in h:
            if hline[0] == "#":
                continue
            tabs = hline.strip().split('\t')
            snp_rsid[tabs[0]] = tabs[rsid_index]

    with gzip.open(args.input,'rt') as f:
        col_headers = {'chr': 'chr', 'pos': 'pos', 'ref': 'ref', 'alt': 'alt'}
        header = next(f)
        current = ""
        with gzip.open(f"{args.output}.tsv.gz",'wt') as g:
            g.write(header.strip() + '\trsid\n')
            for line in f:
                #print(line)
                snp = convert_neale_variation(header, line)
                if current != snp.split('_')[0]:
                    current = snp.split('_')[0]
                    #g = open(os.path.join(args.output, f"{vals['chr']}.tsv"), 'r')
                if snp in snp_rsid:
                    rsid = snp_rsid[snp]
                    if rsid == '-':
                    	rsid = snp
                else:
                    rsid = snp
                g.write(f"{line.strip()}\t{rsid}\n")

if __name__ == '__main__':
    main()
#for (i in names(pred.sciencedisc@metadata$de.genes)) {
#    lapply(names(pred.sciencedisc@metadata$de.genes[[i]]), function(x) write.table(pred.sciencedisc@metadata$de.genes[[i]][[x]], paste0(i, '_', x, '.txt'), quote=FALSE, row.names=FALSE, col.names=FALSE))
#    }
