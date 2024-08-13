#!/usr/bin/env python3
## USAGE: python silva_blast_filter.py <blast_frmt_6> <PREFIX>
# EXAMPLE: python silva_blast_filter.py TY0000039_frmt_6.tsv  TY0000039

import pandas as pd
import sys

silva_db="/mnt/efs/databases/Silva/SILVA_138.1_SSURef_NR99.headers"
keys_db="/work/scripts/Silva_filter_key_words.txt"
accession_db="/work/scripts/Silva_filter_accession_ids.txt"
hit_counts=3

def process_blast_file_filter_keywords(silva_dict, input_file, prefix):

    fh = open(keys_db, "r")
    keywords_list = [line.rstrip() for line in fh.readlines()]
    fh.close()
    #print(keywords_list)


    limit=3
    check_string="uncultured"
    output_file=prefix + ".filtered3hits.tsv"
    outf = open(output_file, "w")


    #df = pd.read_csv(silva_db, header=None, sep='%')
    #df = (df.head(10))
    #silva_dict=df.set_index(0).T.to_dict('list')
    #print( silva_dict )
    ## setting the index of dataframe as col 1first and then Transpose the Dataframe and convert it into a dictionary with values as list
    #silva_dict = pd.read_csv(silva_db, header=None, sep='%').set_index(0).T.to_dict('list')
    #dict_items = silva_dict.items()
    #first_ten = list(dict_items)[:5]
    #print(first_ten)
    i=0
    fc=0
    with open(input_file, "r") as infile:
        #print(infile)
        #next(infile) # skip the header line.
        # example blast format_6 line
        # TY0000018	DQ456374.1.1459	86.667	1425	172	11	40	1463	49	1456	0.0	1563	1485	1459	96
        sample_id=""
        for line in infile:
            #print(i)
            line=line.rstrip()
            split_line=line.split('\t')
            sample_id=split_line[0]
            accession_id=split_line[1]
            percent_identity=split_line[2]
            qlen = int(split_line[-3])
            qcoverage = split_line[-1]
            slen = int(split_line[-2])
            # compute completeness:  (qlen/slen) * 100
            completeness = round(qlen/slen*100, 2)
            # compute query coverage: ((alignment_length - mismatch) / min(slen, qlen)) * 100
            alignment=int(split_line[3])
            mismatch=int(split_line[4])
            qcov = round((alignment - mismatch) / min(slen, qlen),4)*100

            annotation1=silva_dict.get(accession_id)
            annotation=accession_id + " " + str(annotation1)[2:-2]
            #check_string in annotation:
            res = [ a for a in keywords_list if a in annotation]
            if annotation1 is None or res: # if empty
                #print(res, annotation)
                continue
            elif i < hit_counts :
                i+=1
                print_list = [sample_id, annotation, percent_identity, qcoverage, str(completeness), str(qcov)]
                joined="\t".join(print_list)
                #print(i, sample_id, accession_id, annotation, percent_identity, qlen)
     #            ffiltered3.write(joined + "\n")

           #     print_list = [sample_id, annotation, percent_identity, qlen]
           #     joined="\t".join(print_list)
                #print(i, sample_id, accession_id, annotation, percent_identity, qlen)
                outf.write(joined + "\n")
            else:
                break

        if (i < hit_counts):
             for x in range(i, hit_counts):
                outf.write( sample_id + "\tNA\n")

    infile.close()
    outf.close()

def process_blast_file(silva_dict, input_file, prefix):

    limit=3
    check_string="uncultured"
    top3=prefix + ".top3hits.tsv"
    ftop3 = open(top3, "w")
    #filtered3=prefix + ".filtered3hits.tsv"
    #ffiltered3 = open(filtered3, "w")
    #silva_dict = pd.read_csv(silva_db, header=None, sep='%').set_index(0).T.to_dict('list')

    c=0
    with open(input_file, "r") as infile:
        #next(infile) # skip the header line.
        # example blast format_6 line
        # TY0000018     DQ456374.1.1459 86.667  1425    172     11      40      1463    49      1456    0.0     1563    1485    1459    96
        for line in infile:
            #print(i)
            line=line.rstrip()
            split_line=line.split('\t')
            sample_id=split_line[0]
            accession_id=split_line[1]
            percent_identity=split_line[2]
            qlen = split_line[-3]
            qcoverage = split_line[-1]
            annotation=silva_dict.get(accession_id)
            annotation=accession_id + " " + str(annotation)[2:-2]
            print_list = [sample_id, annotation, percent_identity, qlen, qcoverage]
            joined="\t".join(print_list)

            if  c < hit_counts and annotation != None:
                ftop3.write(joined + "\n")
                c+=1
     #       elif i < 3 and annotation != None and not check_string in annotation:
     #           i+=1
     #           print_list = [sample_id, annotation, percent_identity]
     #           joined="\t".join(print_list)
                #print(i, sample_id, accession_id, annotation, percent_identity, qlen)
     #            ffiltered3.write(joined + "\n")
     #       elif annotation != None and check_string in annotation:
     #           continue
     #       else:
     #           break
    infile.close()
    ftop3.close()
    #ffiltered3.close()

def main(blast_file, prefix):

    silva_dict = pd.read_csv(silva_db, header=None, sep='%').set_index(0).T.to_dict('list')
    #print (len(silva_dict))
    # read key filter db
    fh = open(accession_db, "r")
    accession_list = [line.rstrip() for line in fh.readlines()]
    fh.close()
    #read vlaue filter db
    fh = open(keys_db, "r")
    keys_list = [line.rstrip() for line in fh.readlines()]
    fh.close()
    #print(keys_list)
    #filter by key
    filtered_silva_dict = {k : v for k,v in filter(lambda t: t[0] not in accession_list, silva_dict.items())}

    # filter by value
    #filtered_silva_dict2={}
    #filtered_silva_dict2 = {k : v for k,v in filtered_silva_dict.items() for i in keys_list if i not in v}
    #for k,v in filtered_silva_dict.items():
    #    c=0
    #    for i in keys_list:
    #        if i in v:
    #            break
    #        else:
    #            c+=1
    #            if c==len(keys_list):
    #                filtered_silva_dict2[k]=v


    #print (len(filtered_silva_dict2))

    process_blast_file_filter_keywords(filtered_silva_dict, blast_file, prefix)
    process_blast_file(silva_dict, blast_file, prefix)


    return


if __name__ == "__main__":
    blast_file = sys.argv[1]
    prefix = sys.argv[2]
    main(blast_file, prefix)
