#!/bin/bash
 

export HTSLIB_LIBRARY_DIR=$CONDA_PREFIX/lib
export HTSLIB_INCLUDE_DIR=$CONDA_PREFIX/include

pip install git+https://manutorres@bitbucket.org/biociphers/majiq_academic.git

majiq -v > metadata/majiq_version.txt


#pip install git+https://bitbucket.org/biociphers/majiq_academic.git