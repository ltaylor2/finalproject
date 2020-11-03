library(tidyverse)

taxaFiles <- list.files("Data/Plumages")

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

plumages <- map_df(taxaFiles, getTaxon)
plumages[is.na(plumages)] <- 0

write_csv(plumages, "Data/plumageMatrix.csv")
