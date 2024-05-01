#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include {sanger} from './modules/sanger'

// If the user uses the --help flag, print the help text below
params.help = false

// Function which prints help message text
def helpMessage() {
    log.info"""
    Run the Sanger assembly and annotatin pipeline for sanger reads

    Required Arguments:
      --input_path    s3 path to compressed Sanger sequencing files
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

workflow {

    // .fromPath(${params.input_path}/${params.name}/${params.order})
    sanger_ch = Channel
                    .fromPath(params.input_path)
                    .ifEmpty { exit 1, "Cannot find Sanger files" }
    
    sanger_ch | sanger 

}
