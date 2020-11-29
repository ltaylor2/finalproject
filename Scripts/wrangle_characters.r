library(tidyverse)
library(ape)

args <- commandArgs(trailing=TRUE)
treeName <- args[grep("--tree", args)+1]

stageFile <- "Data/stages_all.csv"
inDir <- "Data/Plumages"
outFile <- "Data/plumages_all"
treeName <- "Data/pipridae_jetz_10k_consensus"

# Prepare the nexus file for stages


# Function to parse each taxon's plumage file characters into a single row
cat("Parsing individual plumages matrices in", inDir, "\n")

taxaFiles <- list.files(inDir)

# # A quick pass through all the files to get the maximum stage
# # TODO how can I fill in the array most efficiently?
# numStages <- function(file) {
#   data <- read_csv(paste("Data/Plumages/", file, sep=""))
#   return(ncol(data) - 1)
# }
#
# maxStages <- map_dbl(taxaFiles, numStages) %>%
#           max()

getTaxon <- function(file) {
  taxon <- strsplit(file, "\\.")[[1]][1]

  d <- read_csv(paste("Data/Plumages/", file, sep=""))

  if (nrow(d) == 0) {
    d <- tibble(Character="Crown", S1=0)
  }

  # We want to extract the stages themselves as characters
  # and stick them onto the matrix of the rest of the characters
  # at the end
  stageCharacters <- d %>%
                  select(-Character) %>%
                  colnames()

  stageMatrix <- tibble()

  for (stage in stageCharacters) {
    stageMatrix <- bind_rows(stageMatrix,
                             tibble(Stage=stage, Value=1))
  }
  stageMatrix <- stageMatrix %>%
              pivot_wider(names_from=Stage, values_from=Value)

  d <- d %>%
    pivot_longer(-Character, names_to="Stage", values_to="Value") %>%
    unite(CharacterStage, Character, Stage, sep="_") %>%
    arrange(CharacterStage) %>%
    pivot_wider(names_from=CharacterStage, values_from=Value) %>%
    mutate(Taxon=taxon, .before=1) %>%
    bind_cols(stageMatrix)

  return(d)
}

# Combine all plumage characters across each taxa.
# Any plumage matches missing for a given taxon or stage is
#   fittingly marked 0
plumages <- map_df(taxaFiles, getTaxon)
plumages[is.na(plumages)] <- 0

# Write csv matrix file
write_csv(plumages, paste(outFile, ".csv", sep=""))

cat("Wrote plumage matrix to ", outFile, ".csv\n", sep="")

# Prepare Nexus file for RevBayes input

ntaxa <- nrow(plumages)
ncharacters <- plumages %>%
            select(-Taxon) %>%
            ncol()

sink(paste(outFile, ".nex",sep=""))
cat("#NEXUS\n")
cat("Begin TAXA;\n")
cat("\tDimensions NTAX=", ntaxa, ";\n", sep="")
cat("\tTaxLabels ", paste(plumages$Taxon, collapse=" "), ";\n", sep="")
cat("End;\n")

cat("Begin CHARACTERS;\n")
cat("\tDimensions NCHAR=", ncharacters, ";\n", sep="")
cat("\tFormat DataType=Standard Symbols=\"0 1 2\";\n", sep="")
cat("\tCharLabels ", paste(colnames(plumages)[-1], collapse=" "), ";\n", sep="")
cat("\tMatrix", sep="")

for (r in 1:nrow(plumages)) {
  taxon <- plumages$Taxon[r]
  characters <- paste(plumages[r, -1], collapse="")
  cat("\n\t\t", taxon, " ", characters)
}
cat(";\n")
cat("End;")
sink()

cat("Wrote plumage .nex file to ", outFile, ".nex\n", sep="")

# Prune the available tree based on available data
# TODO predictions for missing tips?
keepTaxa <- plumages$Taxon

fullTree <- read.nexus(paste(treeName, ".nex", sep=""))
missingTips <- fullTree$tip.label[!(fullTree$tip.label %in% keepTaxa)]

prunedTree <- drop.tip(fullTree, missingTips)

write.nexus(prunedTree, file=paste(treeName, "_PRUNED.nex", sep=""))

cat("Pruned input tree based on available taxa\n")
