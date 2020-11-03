library(tidyverse)
library(treeio)
library(ggtree)

theme_lt <- theme_bw() +
		 		 theme(axis.title=element_text(size=10),
			         axis.text=element_text(size=8),
			         legend.title=element_text(size=10),
			         legend.text=element_text(size=8),
			         panel.grid=element_blank())

phylogeny <- read.nexus("Data/pipridae_trees.nex")[1]

plumages <- read_csv("Data/plumage_all.csv")
characters <- colnames(plumages[,-1])

traces <- read_tsv("Output/ase_mk.log") %>%
       mutate(Replicate_ID=as.character(Replicate_ID)) %>%
       filter(Iteration >= max(Iteration)*0.25)

states <- read_tsv("Output/ase_mk.states.txt", col_types = cols(.default = col_character())) %>%
       mutate(Iteration=as.numeric(Iteration)) %>%
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

# Let's just take a look at the ancestral states of the Crown characters in all four stages
crownChars <- grep("Crown_", characters)

for (node in 3:ncol(states))
