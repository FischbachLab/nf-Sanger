#!/usr/bin/env nextflow
nextflow.enable.dsl=1
// If the user uses the --help flag, print the help text below
params.help = false

// Function which prints help message text
def helpMessage() {
    log.info"""
    Run the Sanger assembly and annotatin pipeline for sanger reads

    Required Arguments:
      --group         MITI_assigned_group_name
      --name          QuintaraBio_sequencing_name
      --order         QuintaraBio_order_id
      --output_path   output_s3_path

    Options:
      -profile        docker      run locally


    """.stripIndent()
}

// Show help message if the user specifies the --help flag at runtime
if (params.help){
    // Invoke the function above which prints the help message
    helpMessage()
    // Exit out and do not run anything else
    exit 0
}

if (params.output_path == "null") {
	exit 1, "Missing the output path"
}

if (params.group == "null") {
	exit 1, "Missing the assigned group name"
}

if (params.name == "null") {
	exit 1, "Missing the QuintaraBio sequencing name"
}

if (params.order == "null") {
	exit 1, "Missing the QuintaraBio order id"
}

/*
 * Defines the pipeline inputs parameters (giving a default value for each for them)
 * Each of the following parameters can be specified as command line options
 */

def output_path = "${params.output_path}"
//def output_path=s3://genomics-workflow-core/Pipeline_Results//${params.output_prefix}"

//println output_path
/*
Channel
    .fromPath(params.reads1)
    .set { read1_ch }

Channel
    .fromPath(params.reads2)
    .set { read2_ch }
*/


/*
 * Run Sanger assembly Pipeline
 */
process sanger {

    //container "xianmeng/nf-hybridassembly:latest"
    container "fischbachlab/nf-sanger:latest"
    cpus 8
    memory 16.GB

    publishDir "${output_path}", mode:'copy'

    input:
    //file read1 from read1_ch

    output:
    //path "*"

    script:
    """
    export group="${params.group}"
    export NAME="${params.name}"
    export ORDER="${params.order}"
    export S3OUTPUTPATH="${output_path}/${params.group}"
    bash sanger_wrapper.sh
    """
}
