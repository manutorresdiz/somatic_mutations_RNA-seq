#!/bin/bash
#SBATCH --job-name=majiq_build
#SBATCH -n 10
#SBATCH -t 72:00:00
#SBATCH --mem=100G

source ~/anaconda2/etc/profile.d/conda.sh
conda activate majiq_2.4


majiq build --conf metadata/majiq_config_file.txt --nproc 10 --disable-ir --mem-profile --debug -o data/majiq_files/ /mnt/isilon/thomas-tikhonenko_lab/data/index/ensembl.Homo_sapiens.GRCh38.94.gff3
