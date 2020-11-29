library(tidyverse)

# Get all characters from plumage coding
# Characters have coding <PATCH>-<COLORATION>_<STAGE>
chars <- read_csv("Data/plumage_all.csv") %>%
      select(-Taxon) %>%
      colnames()

# Extract all unique stage characters
# (e.g., S1, S2, S3. These characters have no "_" separator)
stages <- chars[!grepl("_", chars)] %>%
       sort()

# Extract all base characters
# (with "_" stage separator but lacking "-" coloration separator)
notStages <- chars[grepl("_", chars)]

bases <- notStages[!grepl("-", notStages)] %>%
      sort()

# Extract all coloration characters
# (with "_" stage separator and "-" coloration separator)
colorations <- notStages[grepl("-", notStages)] %>%
            sort()

# Now we build the dependency matrix.
# We first build the matrix with no dependencies
#   and temporarily mark different character types
dependencies <- tibble(CHAR_STATEMENT=c(stages, bases, colorations),
                       STATE_0="abstent",
                       STATE_1="present",
                       TEMP_CHAR_TYPE=c(rep("stage", times=length(stages)),
                                        rep("base", times=length(bases)),
                                        rep("coloration", times=length(colorations)))) %>%
             rowid_to_column() %>%
             mutate(ID=paste("C", rowid, sep=""), .before=1) %>%
             select(-rowid)

# At this point I am looking at PARAMO and see that it is limited.
# Because these might be "false dependencies" I am considering,
# I am going to try just normal ACE and see what happens...
