date
nextflow run EBI-Metagenomics/mobilome-annotation-pipeline \
    -r 3aa408d26d987c0f721c07d4f0fed52a871de117 \
    --input samplesheet.csv \
    -c my_paths.config \
    --skip_sanntis \
    -profile docker \
    -resume
date
