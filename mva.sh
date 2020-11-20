#!/bin/bash

### * SET * ##################################################################
DIRECTORY=/home/lut2/project/EEB654/finalproject
ENVIRONMENT=pipridae

PLUMAGE_DIR=${DIRECTORY}/Data/Plumages
FULL_PLUMAGE_DATA=${DIRECTORY}/Data/plumage_all
TREE_FILE=${DIRECTORY}/Data/pipridae_jetz_10k_consensus.nex

REV_FILE=${DIRECTORY}/Scripts/mcmc_ase_mk.Rev

REV_ITERATIONS=500000
REV_THINNING=500
REV_CHAINS=2
BURN_IN=0.25
### * SET * ##################################################################



##############################################################################
### Logistics
##############################################################################
module load miniconda
source activate $ENVIRONMENT

##############################################################################
### Input Data
##############################################################################

echo -e "\n START INPUT DATA FORMAT \n"

# Refactor one genus change from the Jetz tree
sed -i "s/Xenopipo_flavicapilla/Chloropipo_flavicapilla/g" $TREE_FILE

# Wrangle the individual plumage datasets
Rscript Scripts/wrangle_plumages.r --args -i $PLUMAGE_DIR \
                                          -o $FULL_PLUMAGE_DATA

echo -e "\n END INPUT DATA FORMAT \n"

##############################################################################
### RevBayes
##############################################################################
# Load RevBayes directly from the cluster
module load revbayes

echo -e "\n START REVBAYES \n"

RB_COMMAND="PLUMAGE_DATA=\"${FULL_PLUMAGE_DATA}.nex\";
            TREE_FILE=\"${TREE_FILE}\";
            THINNING=${REV_THINNING};
            ITERATIONS=${REV_ITERATIONS};
            CHAINS=${REV_CHAINS};
            BURNIN=${BURN_IN};
            source(\"${REV_FILE}\");"
echo $RB_COMMAND | rb

echo "\n END REVBAYES \n"

##############################################################################
### Output and Plots
##############################################################################
echo -e "\n START OUTPUT AND PLOTS \n"

Rscript Scripts/wrangle_output.r --args --trees $TREES_FILE \
                                        --plumages ${FULL_PLUMAGE_DATA}.csv
echo -e "\n END OUTPUT AND PLOTS \n"
