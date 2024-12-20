# nf-download-sumstats

## Introduction

This is a Nextflow Pipeline to streamline downloading of GWAS summary
statistics to then be processed using the
[`nf-munge-sumstats`](https://github.com/comp-med/nf-munge-sumstats) pipeline
to format into a harmonized format
([GWAS-VCF](https://github.com/MRCIEU/gwas-vcf-specification)) and  and lift
them into both the GRCh37 and GRCh38 genome build. 

The pipeline covers the following steps:

1. Work with local files or download summary statistics from openGWAS, GWAS
   Catalog or an arbitrary link

### Input Table

The pipeline requires a single input table in `CSV` format that is to be
specified in the `input_table` parameter in `nextflow.config`.

Create the input table with the following columns.

```r
library(data.table)
input_table <- data.table(
    phenotype_id = NA_character_,
    data_source = NA_character_,
    data_id = NA_character_,
    data_link = NA_character_,
    data_location = NA_character_
)
```

Make sure that the table contains exactly these columns and that the contents
conform to the following:

* All entries in `phenotype_id` must be unique, since this will be the name of
  the output directory for the formatted summary statistics
* `data_source` must be one of `gwas_catalog`, `open_gwas`, `other` or `local`
  and based on this, contain a valid entry in one of the remaining column:
    * When `open_gwas`: Contain openGWAS study accession (e.g. `ieu-b-5118`) in `data_id`
    * When `gwas_catalog`: Contain a GWAS Catalog study accession (e.g.
      `GCST90204201`) in `data_id` with full summary statistics available from
      their FTP servers
    * When `other`: Contain a download link that can be directly accessed via
      `wget` in `other`
    * When `local`: Contain an absolute & valid directory path to the 
      corresponding file in `data_location`

Currently, there are no check in place if the inputs are incorrect and the
pipeline will simply fail if any single input is faulty!

```r
# Make sure `phenotype_id` is unique!
stopifnot(
    "`phenotype_id` must be unique!" = !any(
        duplicated(input_table$phenotype_id)
    )
)

# Make sure `data_source` contains valid entries! 
stopifnot(
    "Unexpected entry in `data_source`!" = all(
        unique(input_table$data_source) %in% c(
            "gwas_catalog", 
            "open_gwas",
            "other",
            "local"
        )
    )
)
```

### Software

Currently, the pipeline does not automatically set up all required software and
R packages so make sure you have the following software dependencies set up and
configured in `nextflow.config`.

* External binaries
    * [`lftp`](https://lftp.yar.ru/)
* R packages: 
    * From GitHub: [gwascatftp](https://github.com/comp-med/gwascatftp), [MungeSumstats](https://github.com/Al-Murphy/MungeSumstats)
    * From CRAN: `data.table`, `fs`

## Gettings Started

Create an input  table with the source for each phenotype, save it and provide
the path to the input table in the `input_table` parameter.

```
library(data.table)
input_table <- data.table(
    phenotype_id = c("atrial_fibrillation", "body_mass_index"),
    data_source = c("gwas_catalog", "body_mass_index"),
    data_id = c("GCST90204201", "ieu-b-5118"),
    data_link = NA_character_,
    data_location = NA_character_
)
fwrite(input_table, "</PATH/TO/>input_table.csv", sep = ",")
```

Make sure to add all the required parameters and path to the input table in
`nextflow.config`.  Afterwards, you can run the pipeline.

First, see if the the pipeline executes by starting a dry-run.

```bash
# When running the pipeline locally, e.g. on your laptop
nextflow run main.nf -stub-run 

# When on a HPC with SLURM, use the `cluster` profile
nextflow run main.nf -stub-run -profile cluster
```

If that finished successfully, run the actual pipeline.

```bash
# Again, when on an HPC with SLURM, add the `-profile cluster` flag
nextflow run main.nf -profile cluster
```

### Output

By default, all output will be saved in the `./output` directory in the
pipeline's base directory. Raw summary statistic files can be found in the
`./raw` subdirectory as symbolic links into the respective working directory.
Files for each phenotype will be saved in subdirectories named after each line
in `phenotype_id` of `params.input_table`.

```bash
output/
└── raw
    ├── phentype_1
    │   └── raw_sumstat_file.gz -> </SYMLINK/TO/WORK/DIR>/raw_sumstat_file.gz
    ├── phenotype_2
    │   └── raw_sumstat_file.vcf.gz -> </SYMLINK/TO/WORK/DIR>/raw_sumstat_file.vcf.gz
[...]
```
