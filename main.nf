#!/usr/bin/env nextflow

// https://sydney-informatics-hub.github.io/template-nf-guide/
nextflow.enable.dsl=2

// HEADER ---------------------------------------------------------------------

log.info """\
===============================================================================
nf-Download-Sumstats
===============================================================================

Created by the Computational Medicine Group | BIH @ Charité

===============================================================================
Workflow run parameters 
===============================================================================
input       : ${params.input}
outDir      : ${params.outDir}
workDir     : ${workflow.workDir}
===============================================================================

"""

// Help function
def helpMessage() {
  log.info"""
  Usage:  nextflow run main.nf 

  Required Arguments:

  <TODO>

  Optional Arguments:

  --outDir	Specify path to output directory. Default is `output/`
	
""".stripIndent()
}

// MODULES --------------------------------------------------------------------

include { DOWNLOAD_DATA } from './workflows/download_data.nf'

// WORKFLOW -------------------------------------------------------------------

workflow {
  
  // Main file containing Data IDs and necessary meta data
  def input = file(params.input)

  // Where to find all R packages
  def r_lib    = Channel.fromPath(params.local_r_library)

  // Where to find additional binaries // TODO: create environments
  def lftp_bin = Channel.fromPath(params.lftp_bin)
  
  // Download raw summary statistics from various sources
  DOWNLOAD_DATA (input, r_lib, lftp_bin)

}

// SUMMARY --------------------------------------------------------------------

workflow.onComplete {
summary = """
===============================================================================
Workflow execution summary
===============================================================================

Duration    : ${workflow.duration}
Success     : ${workflow.success}
workDir     : ${workflow.workDir}
Exit status : ${workflow.exitStatus}
outDir      : ${params.outDir}

===============================================================================
"""
println summary
}
