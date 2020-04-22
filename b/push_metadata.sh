#!/usr/bin/env bash

############
# Preamble #
############

# Note that this script uses the csv2md utility, which is most easily installed into a conda env
#conda install -c anaconda pip
#pip install csv2md

# remove any existing data descriptions and metadata from the end of the readme
sed -i '/<!--- begin data and metadata descriptions - do not edit this comment -->/q' ~/ddl/covid/metadata.md

###########
# PC Data #
###########

# initialize section for PC in the metadata list
echo "## Population Census " >> ~/ddl/covid/metadata.md
echo "### Dataset-level Metadata  " >> ~/ddl/covid/metadata.md

# pull dataset-level PC hospitals metadata fromm google sheet and ensure unix linebreaks
wget -O /scratch/lunt/md_tmp.csv "https://docs.google.com/spreadsheets/d/e/2PACX-1vTpGgFszhHhMlzh-ePv3tRj5Arpv7uyicPPDgkCS7-Ms3nE6OvofQWBFuOxOWBPtELzSmBFttxvLc20/pub?gid=1661733111&single=true&output=csv"
dos2unix /scratch/lunt/md_tmp.csv

# parse this into a metadata markdown table, and append to the readme
csv2md /scratch/lunt/md_tmp.csv >> ~/ddl/covid/metadata.md

# same steps for variable-level metadata
echo "### Variable-level Metadata  " >> ~/ddl/covid/metadata.md
wget -O /scratch/lunt/md_tmp.csv "https://docs.google.com/spreadsheets/d/e/2PACX-1vTpGgFszhHhMlzh-ePv3tRj5Arpv7uyicPPDgkCS7-Ms3nE6OvofQWBFuOxOWBPtELzSmBFttxvLc20/pub?gid=1900447643&single=true&output=csv"
dos2unix /scratch/lunt/md_tmp.csv
csv2md /scratch/lunt/md_tmp.csv >> ~/ddl/covid/metadata.md


#############
# DLHS Data #
#############

# initialize section for PC in the metadata list
echo "## DLHS " >> ~/ddl/covid/metadata.md
echo "### Dataset-level Metadata  " >> ~/ddl/covid/metadata.md

# dataset-level metadata
wget -O /scratch/lunt/md_tmp.csv "https://docs.google.com/spreadsheets/d/e/2PACX-1vR8pkaS86ZlwcSe0ljKyL6wR_YOGE380JrHgAhG5Z66Oq1WtD4xtsJCsdCt-yAv8Qw0X74twBeIQ9of/pub?gid=1661733111&single=true&output=csv"
dos2unix /scratch/lunt/md_tmp.csv

# parse this into a metadata markdown table, and append to the readme
csv2md /scratch/lunt/md_tmp.csv >> ~/ddl/covid/metadata.md

# variable-level metadata
echo "### Variable-level Metadata  " >> ~/ddl/covid/metadata.md
wget -O /scratch/lunt/md_tmp.csv "https://docs.google.com/spreadsheets/d/e/2PACX-1vR8pkaS86ZlwcSe0ljKyL6wR_YOGE380JrHgAhG5Z66Oq1WtD4xtsJCsdCt-yAv8Qw0X74twBeIQ9of/pub?gid=1900447643&single=true&output=csv"
dos2unix /scratch/lunt/md_tmp.csv
csv2md /scratch/lunt/md_tmp.csv >> ~/ddl/covid/metadata.md
