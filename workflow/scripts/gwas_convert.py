def gwas_convert(ref, alt, pos):
    length = len(ref) - len(alt)
    if ref == '-':
        length = length - 1
    if len(alt) > len(ref):
        length = -1
        if ref == alt[:len(ref)]:
            pos = str(int(pos)+len(ref))
            alt = alt[len(ref):]
            ref = '-'
    return({'ref': ref, 'alt': alt, 'start': pos, 'stop': str(int(pos)+length)})

def read_neale_format(headerline, line):
    col_headers = {'chr': 'chr', 'pos': 'pos', 'ref': 'ref', 'alt': 'alt'}
    headerline = headerline.strip().split('\t')
    indexes = {i: headerline.index(i) for i in col_headers}
    values = line.strip().split('\t')
    vals = {i: values[indexes[i]] for i in indexes}
    return(vals)

def format_variation(vals):
    return(f"{vals['chr']}_{vals['start']}_{vals['ref']}/{vals['alt']}")

def convert_neale_variation(headerline, line):
    vals = read_neale_format(headerline, line)
    new_vals = gwas_convert(vals['ref'], vals['alt'], vals['pos'])
    new_vals['chr'] = vals['chr']
    return(format_variation(new_vals))
