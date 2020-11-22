library(tidyverse)
library(treeio)
library(ggtree)

args <- commandArgs(trailing=TRUE)
treeFile <- args[grep("--tree", args)+1]
dataFile <- args[grep("--plumages", args)+1]

theme_lt <- theme_bw() +
          theme(axis.title=element_text(size=10),
               axis.text=element_text(size=8),
               legend.title=element_text(size=10),
               legend.text=element_text(size=8),
               panel.grid=element_blank())

phylogeny <- read.nexus(treeFile)

plumages <- read_csv(dataFile)
characters <- colnames(plumages[,-1])

traces <- read_tsv("Output/ase_mk.log") %>%
       mutate(Replicate_ID=as.character(Replicate_ID)) %>%
       filter(Iteration >= max(Iteration)*0.25)

# Raw input tree
plot_raw_tree <- ggtree(phylogeny) +
              geom_tiplab(size=2) +
              xlim(0, 45)

ggsave(plot_raw_tree,
       file="Figures/raw_tree.png",
       width=3, height=5, unit="in")


# Trace plot
plot_trace_mu <- ggplot(traces) +
              geom_line(aes(x=Iteration, y=mu_plumage, colour=Replicate_ID), alpha=0.85) +
              scale_colour_manual(values=c("gray", "black")) +
              xlab("Iteration") +
              ylab(expression(mu)) +
              guides(colour=FALSE) +
              theme_lt +
              theme(axis.title.y=element_text(angle=0, vjust=0.5, hjust=0))

ggsave(plot_trace_mu,
       file="Figures/trace_mu.png",
       width=3, height=3, unit="in")

# Density plot
plot_dens_mu <- ggplot(traces) +
             geom_density(aes(x=mu_plumage), colour="black", fill="gray", alpha=0.85) +
             xlab(expression(mu)) +
             ylab("Density") +
             theme_lt

ggsave(plot_dens_mu,
       file="Figures/dens_mu.png",
       width=3, height=3, unit="in")

# Let's just take a look at the ancestral states of the plumage characters on the Crown in all four stages
#   (Note, here I'm talking about the CROWN FEATHERS on a bird, not the Crown taxa on a tree!)
#  TODO how can we track ALL states directly RB, instead of just the one per tree?
crownChars <- grepl("Crown", characters)

states <- read_tsv("Output/ase_mk.states.txt", col_types = cols(.default = col_character())) %>%
       mutate(Iteration=as.numeric(Iteration)) %>%
       filter(Iteration >= max(Iteration)*0.25)


# These functions allow us to go from the full ancestral state reconstruction matrix,
#   which contains ASE info for all nodes (one per col) at each rep (one per row)
# To a tidier representation of our chosen states (here crown)
#   for each character (one per col) for each rep of a node (one per row)
parseCrownRep <- function(r) {
  row <- states[r,3:ncol(states)]

  values <- map_df(1:ncol(row), ~ parseCrownChars(row[.]))

  if (r %% 100 == 0) {
    cat("Parsed the State of Crown Plumage through rep", r, "\n")
  }

  return(values)
}

parseCrownChars <- function(s) {
  index <- strsplit(colnames(s), "_")[[1]][2]
  chars <- strsplit(pull(s), ",")[[1]][crownChars]

  values <- tibble(index=as.numeric(index),
                   Character=characters[crownChars],
                   State=chars)
  return(values)
}

crownStates <- map_df(1:nrow(states), parseCrownRep)

# Now we can pull one value from the distribution (the mode)
#   for each state at each nodeacross all reps,
# This summary dataframe is widened for easy plotting with tree data
crownSummaries <- crownStates %>%
               group_by(index, Character, State) %>%
               tally() %>%
               group_by(index, Character) %>%
               filter(n==max(n)) %>%
               select(-n) %>%
               ungroup() %>%
               pivot_wider(names_from=Character, values_from=State)

# Read in the ancestral tree written in RevBayes to make sure the nodes all correspond
# Replace those with the plumage crown summaries
# As far as I can tell, this will CONFIRM that the nodes are in the right order
rbTree <- read.beast("Output/ase_mk.tree")
rbTree@data <- rbTree@data %>%
            left_join(crownSummaries, by="index")

# Plot tree with ancestral reconstructions neatly arranged for each node, including tips
plot_tree_anc <- ggtree(rbTree) +
              geom_nodelab(aes(label="  ", fill=Crown_S1), colour="black", geom="label", label.padding=unit(.1, "lines"), nudge_x=-.9, size=1) +
              geom_nodelab(aes(label="  ", fill=Crown_S2), colour="black", geom="label", label.padding=unit(.1, "lines"), nudge_x=-.3, size=1) +
              geom_nodelab(aes(label="  ", fill=Crown_S3), colour="black", geom="label", label.padding=unit(.1, "lines"), nudge_x=.3, size=1) +
              geom_tiplab(aes(label="  ", fill=Crown_S1), colour="black", geom="label", label.padding=unit(.1, "lines"), hjust=-.5, size=1) +
              geom_tiplab(aes(label="  ", fill=Crown_S2), colour="black", geom="label", label.padding=unit(.1, "lines"), hjust=-1.5, size=1) +
              geom_tiplab(aes(label="  ", fill=Crown_S3), colour="black", geom="label", label.padding=unit(.1, "lines"), hjust=-2.5, size=1) +
              scale_fill_manual(values=c("0"="white",
                                         "1"="red")) +
              guides(fill=FALSE) +
              xlim(-4, 30) +
              theme(legend.position=c(.1, .8))

ggsave(plot_tree_anc,
       file="Figures/anc_crown_tree.png",
       width=3, height=5, unit="in")
