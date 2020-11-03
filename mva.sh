#!/bin/bash

### * SET * ##################################################################
DIRECTORY=/home/lut2/project/EEB654/finalproject
ENVIRONMENT=pipridae

PLUMAGE_DIR=${DIRECTORY}/Data/Plumages
FULL_PLUMAGE_DATA=${DIRECTORY}/Data/plumage_all
TREES_FILE=${DIRECTORY}/Data/pipridae_trees.nex
REV_FILE=${DIRECTORY}/Scripts/mcmc_ase_mk.Rev
### * SET * ##################################################################

# Conda environment includes are R scripts
module load miniconda
source activate $ENVIRONMENT

Rscript Scripts/wrangle_plumages.r --args -i $PLUMAGE_DIR -o $FULL_PLUMAGE_DATA

sed -i "s/Xenopipo_flavicapilla/Chloropipo_flavicapilla/g" $TREES_FILE

# Load RevBayes directly from the cluster
module load revbayes

# Run preliminary RevBayes reconstruction
rb --file $REV_FILE

# Wrangle and plot RevBayes output
Rscript Scripts/wrangle_output.r
