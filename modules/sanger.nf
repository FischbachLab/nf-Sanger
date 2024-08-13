/*
 * Run Sanger assembly Pipeline
 */
process sanger {
    tag "${params.group}"
    
    //container 'fischbachlab/nf-sanger:latest'
    container "${params.container}"
    cpus 8
    memory 16.GB
    
    //publishDir "${output_path}", mode:'copy'

    input:
    path reads 

    output:
    //path "*"     

    script:
    """
    export S3INPUTPATH="${params.input_path}"
    export group="${params.group}"
    export NAME="${params.name}"
    export ORDER="${params.order}"
    export S3OUTPUTPATH="${params.output_path}/${params.group}"

    bash sanger_wrapper_isolateR.sh

    """
}
