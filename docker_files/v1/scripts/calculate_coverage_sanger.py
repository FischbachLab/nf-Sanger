#!/usr/bin/env python3
## USAGE: python calculate_coverage.py <JSON_FILE> <PREFIX>
# EXAMPLE: python calculate_coverage.py TY0000039.json TY0000039

## OUTPUTS:
# <PREFIX>.msa_aln.tsv = visualize how each primer aligns
# <PREFIX>.per_base_cov.npz = 1-D numpy array of per base coverage for the final sequence
# <PREFIX>.cov_stats.csv = coverage summary file

import numpy as np
import json
import pandas as pd
import sys


def parse_json(json_file):
    json_file_handle = open(json_file)
    aln_json = json.load(json_file_handle)
    concensus = aln_json["gappedConsensus"]
    seq_len = len(concensus)
    msa_json = aln_json["msa"]

    return concensus, seq_len, msa_json


def view_msa(msa_json):
    # Parse the JSON file to extract the MSA portion
    # align the sequences based on the info in the JSON

    df = pd.DataFrame.from_dict(msa_json)

    df["msa"] = df.apply(
        lambda row: pad_seq(row["align"], row["leadingGaps"], row["trailingGaps"]),
        axis=1,
    )
    return df


def pad_seq(seq, leadingGaps, trailingGaps):
    # for each row pad the align column with '.' based on number of leading and trailing gaps
    # (TRY) if forward is false, switch the leading and trailing gaps.
    # (May have to rev comp the seq, but check this first) --> NOPE!
    ## TESTED: No special treatment needed. Use seq block as is. Woohoo!

    lead = "." * int(leadingGaps)
    trail = "." * int(trailingGaps)

    return f"{lead}{seq}{trail}"


def convert_seq_to_bool(seq, concensus):
    ## Convert anything that is ATGCU to 1, everythign else to 0.
    valid_nuc = {"A", "T", "G", "C", "U"}
    bool_array = list()
    for index, nucl in enumerate(concensus):
        if (not nucl in valid_nuc) or (not seq[index] in valid_nuc):
            bool_array.append(0)
        elif seq[index] == nucl:
            bool_array.append(1)
        else:
            bool_array.append(0)

    return np.array(bool_array)


def get_coverage(df, concensus, rows, cols, prefix):
    ## Convert anything that is ATGC to 1, everythign else to 0.
    ## Add each column to create a 1d array
    ## take average and SD of the entire array
    msa_arr = np.zeros((rows, cols))

    for index, row in enumerate(df.itertuples(index=False)):
        bool_msa = convert_seq_to_bool(row.msa, concensus)
        msa_arr[index] = np.array(bool_msa)

    # collapse to per base coverage - 1d array
    per_base_cov = np.sum(msa_arr, axis=0)
    np.savez(f"{prefix}.per_base_cov.npz", per_base_cov)

    return {
        "sample": prefix,
        "length": cols,
        "num_primer_reads": rows,
        "mean_coverage": round(np.mean(per_base_cov), 3),
        "median_coverage": np.median(per_base_cov),
        "sd_coverage": round(np.std(per_base_cov), 3),
        "var_coverage": round(np.var(per_base_cov), 3),
        "per_base_cov": per_base_cov,
    }


def main(json_file, prefix):
    # json_file = "TY0000018.json"
    # prefix = "TY0000018"
    consensus, seq_len, msa_json = parse_json(json_file)
    msa_df = view_msa(msa_json)
    num_primers, _ = msa_df.shape

    cov_dict = get_coverage(msa_df, consensus, num_primers, seq_len, prefix)
    per_base_cov = "".join(([str(int(i)) for i in list(cov_dict.pop("per_base_cov"))]))
    pd.DataFrame.from_dict([cov_dict]).to_csv(f"{prefix}.cov_stats.csv", index=False)

    # Add concensus and save alignment
    aln_df = (
        msa_df[["traceFileName", "msa"]]
        .append(
            [
                {"traceFileName": "gappedConcensus", "msa": consensus},
                {"traceFileName": "per_base_coverage", "msa": per_base_cov},
            ],
            ignore_index=True,
        )
        .copy()
    )
    aln_df.to_csv(f"{prefix}.msa_aln.tsv", index=False, sep="\t")

    return


if __name__ == "__main__":
    json_file = sys.argv[1]
    prefix = sys.argv[2]
    main(json_file, prefix)
