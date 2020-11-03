library(tidyverse)

args <- commandArgs(trailing=TRUE)
inDir <- args[grep("-i", args)+1]
outFile <- args[grep("-o", args)+1]

# Function to parse each taxon's plumage file characters into a single row
cat("Parsing individual plumages matrices in", inDir, "\n")

taxaFiles <- list.files(inDir)

getTaxon <- function(file) {
  taxon <- strsplit(file, "\\.")[[1]][1]

  d <- read_csv(paste("Data/Plumages/", file, sep="")) %>%
    pivot_longer(-Character, names_to="Stage", values_to="Value") %>%
    unite(CharacterStage, Character, Stage, sep="_") %>%
    arrange(CharacterStage) %>%
    pivot_wider(names_from=CharacterStage, values_from=Value) %>%
    mutate(Taxon=taxon, .before=1)

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
