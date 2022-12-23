import os, gzip, argparse, math

def threshold_import(x):
    if x == 'None':
        return 'None'
    try:
        x = float(x)
    except ValueError:
        raise argparse.ArgumentTypeError("%r not a floating-point literal" % (x,))
    return x

def main(raw_args=None):
    parser = argparse.ArgumentParser(description="""Take GWAS data and extract the SNPS in preparation for RSID calls. If a threshold is included then SNPs will be filtered by threshold""")
    parser.add_argument("-o", "--output", metavar="output",
        action = "store", type=str, required=True,
        help="Output file name")
    parser.add_argument("-i", "--input", metavar="gwas.tsv.bgz",
        action = "store", type=str, required=True,
        help="Input GWAS files")
    parser.add_argument("-t", "--threshold", metavar="0.01",
        action = "store", type=threshold_import, default=None,
        help="P-Value threshold to filter the SNPs by"),
    parser.add_argument("-p", "--population", metavar="EUR",
        action = "store", type=str, choices=["AFR", "AMR", "CSA", "EAS", "EUR", "MID"],
        default="EUR")
    parser.add_argument("--filter",
        action = "store_true", required = False,
        default = False)
    args = parser.parse_args(raw_args)

    col_headers = {'chr': 'chr', 'pos': 'pos', 'ref': 'ref', 'alt': 'alt', 'pval': f"pval_{args.population}"}



    with gzip.open(args.input,'rt') as f:
        header = next(f)
        if args.filter:
            h = gzip.open(os.path.join(os.path.dirname(args.output), f"filter.{os.path.splitext(os.path.basename(args.output))[0]}.tsv.gz"), 'wt')
            h.write(header)
        header = header.strip().split('\t')
        indexes = {i: header.index(col_headers[i]) for i in col_headers}
        current = ""
        gheader = 'chr\tstart\tend\tallele\tstrand'
        with open(args.output, 'w') as g:
            for line in f:
                values = line.strip().split('\t')
                vals = {i: values[indexes[i]] for i in indexes}
                if args.threshold != "None":
                    if vals['pval'] == "NA":
                        continue
                    if float(vals['pval']) > math.log(args.threshold):
                        continue
                if args.filter:
                    h.write(line)
                length = len(vals['ref']) - len(vals['alt'])
                if vals['ref'] == '-':
                    length = length - 1
                if len(vals['alt']) > len(vals['ref']):
                    length = -1
                    if vals['ref'] == vals['alt'][:len(vals['ref'])]:
                        vals['pos'] = str(int(vals['pos'])+len(vals['ref']))
                        vals['alt'] = vals['alt'][len(vals['ref']):]
                        vals['ref'] = '-'
                g.write(f"{vals['chr']}\t{vals['pos']}\t{str(int(vals['pos'])+length)}\t{vals['ref']}/{vals['alt']}\t+\n")

if __name__ == '__main__':
    main()
