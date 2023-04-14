#!/bin/sh

majiq -v

majiq build --conf metadata/majiq_config_file.txt --nproc 8 --disable-ir --simplify 0.01 -o data/majiq_files/ /mnt/isilon/thomas-tikhonenko_lab/data/index/gencode.v37.annotation.gff3 --junc-files-only