Delayed Plumage Maturation Evolution in Manakins (Aves: Pipridae)
================
Liam U. Taylor

### Plumage Characters

Wrangling stage characters into a nexus file.

``` r
# A function to convert binary characters into probability distributions,
#   so that we can map missing data (NA) to a 50/50 probability across two columns
probMap <- function(v) {
  if (is.na(v)) {
    return(0.5)
  } 
  return(v)
}

# Read in the raw data matrix and concatenate taxa names
stagesData <- read_csv(STAGES_FILE) %>%
          unite(Taxon, Genus, Species, sep="_") %>%
          mutate(S1Binary = as.numeric(Stages>0),
                 S2Binary = as.numeric(Stages>1),
                 S3Binary = as.numeric(Stages>2),
                 Coordinated_Present = map_dbl(Coordinated, probMap),
                 Coordinated_Absent = 1 - Coordinated_Present,
                 Concentrated_Present = map_dbl(Concentrated, probMap),
                 Concentrated_Absent = 1 - Concentrated_Present)
```

    ## Parsed with column specification:
    ## cols(
    ##   Genus = col_character(),
    ##   Species = col_character(),
    ##   Stages = col_double(),
    ##   Dichromatism = col_double(),
    ##   Coordinated = col_double(),
    ##   Concentrated = col_double()
    ## )

Wrangling plumage characters into a nexus file.

``` r
# A function to parse an individual plumage record into a matrix
extractPlumageFile <- function(file) {
  taxon <- strsplit(file, "\\.")[[1]][1]

  plumage <- read_csv(paste(PLUMAGE_DIR, file, sep=""),
                        col_types = cols(.default = col_character()))

  if (nrow(plumage) == 0) {
    plumage <- bind_rows(plumage, tibble(Character="Crown", S1="Absent"))
  }
  
  plumage <- plumage %>%
          pivot_longer(-Character, 
                       names_to="Stage",
                       values_to="Value") %>%
          unite(CharacterStage, Character, Stage, sep="_") %>%
          arrange(CharacterStage) %>%
          pivot_wider(names_from=CharacterStage, 
                      values_from=Value) %>%
          purrr::map(~ PLUMAGE_STATE_CODES[.]) %>%
          as.list() %>%
          as_tibble() %>%
          mutate(Taxon=taxon, .before=1)
  
  return(plumage)
}


# Construct the plumage character matrix
plumagesData <- list.files(PLUMAGE_DIR) %>%
             purrr::map_df(extractPlumageFile)

# All patches not indicated in the original plumage tables are absent
plumagesData[is.na(plumagesData)] <- 0
```

### Backbone Phylogeny

``` r
# Read the tree file
tree <- read.nexus(TREE_FILE)

# Refactor old taxon names which are common mislabeled across trees
refactorNames <- read_csv("Data/taxon_refactoring_names.csv")
```

    ## Parsed with column specification:
    ## cols(
    ##   Taxon_Old = col_character(),
    ##   Taxon_New = col_character()
    ## )

``` r
# A function to conditionally refactor a taxon 
refactorTaxon <- function(old) {
  if (old %in% refactorNames$Taxon_Old) {
    new <- refactorNames %>%
        filter(Taxon_Old == old) %>%
        pull(Taxon_New)
    return(new)
  }
  return(old)
}
refactoredTips <- map_chr(tree$tip.label, refactorTaxon)
tree$tip.label <- refactoredTips

# Determine tips which are in the tree but not the data

treeTips <- tree$tip.label

missingTips_stages <- treeTips[!(treeTips %in% stagesData$Taxon)]
missingTips_plumages <- treeTips[!(treeTips %in% plumagesData$Taxon)]

if (length(setdiff(missingTips_stages, missingTips_plumages)) != 0) {
  stop(paste("You do not have the same tip data available for stage and plumage patches\n",
             "Here are the different tips:\n",
             paste(setdiff(treeTips_stages, treeTips_plumages), collapse="  ")))
}

treePruned <- drop.tip(tree, missingTips_stages)
```

### Ancestral State Estimation: Predefinitive Plumage Stages

Mk Model Selection for Stage Evolution

``` r
# Organize vector of stage data
stagesVector <- map_dbl(treePruned$tip.label,
                        ~ filter(stagesData, Taxon==.)$Stages[1])
names(stagesVector) <- treePruned$tip.label


# First, we test rates models

# MODEL 1: Equal-rates unordered
fit_ER <- fitMk(tree=treePruned, x=stagesVector, model="ER")

# MODEL 2: Equal symmetric ordered
mat_eq_sym_ordered <- matrix(c(0,1,0,0,
                               1,0,1,0,
                               0,1,0,1,
                               0,0,1,0),4,4,byrow=TRUE)
fit_eq_sym_ordered <- fitMk(tree=treePruned, x=stagesVector, model=mat_eq_sym_ordered)

# MODEL 3: Equal asymmetric ordered
mat_eq_asym_ordered <- matrix(c(0,1,0,0,
                                2,0,1,0,
                                0,2,0,1,
                                0,0,2,0),4,4,byrow=TRUE)

fit_eq_asym_ordered <- fitMk(tree=treePruned, x=stagesVector, model=mat_eq_asym_ordered)
  
# MODEL 4: Unequal symmetric ordered
mat_un_sym_ordered <- matrix(c(0,1,0,0,
                               1,0,2,0,
                               0,2,0,3,
                               0,0,3,0),4,4,byrow=TRUE)

fit_un_sym_ordered <- fitMk(tree=treePruned, x=stagesVector, model=mat_un_sym_ordered)


# MODEL 5: Unequal asymmetric ordered
mat_un_asym_ordered <- matrix(c(0,1,0,0,
                                2,0,3,0,
                                0,4,0,5,
                                0,0,6,0),4,4,byrow=TRUE)

fit_un_asym_ordered <- fitMk(tree=treePruned, x=stagesVector, model=mat_un_asym_ordered)

# MODEL 6: All rates different
fit_ARD <- fitMk(tree=treePruned, x=stagesVector, model=)



AICs <- setNames(sapply(list(fit_ER,fit_eq_sym_ordered,fit_eq_asym_ordered,
                             fit_un_sym_ordered,fit_un_asym_ordered,fit_ARD),AIC),
                 c("ER","eq_sym_ordered","eq_asym_ordered",
                   "un_sym_ordered","un_asym_ordered","ARD"))
```

Ancestral State Simulation for Stages

``` r
maps <- make.simmap(tree=treePruned,
                    x=stagesVector,
                    model=mat_eq_sym_ordered,
                    nsim=100)
```

    ## make.simmap is sampling character histories conditioned on
    ## the transition matrix
    ## 
    ## Q =
    ##             0           1           2           3
    ## 0 -0.03321366  0.03321366  0.00000000  0.00000000
    ## 1  0.03321366 -0.06642732  0.03321366  0.00000000
    ## 2  0.00000000  0.03321366 -0.06642732  0.03321366
    ## 3  0.00000000  0.00000000  0.03321366 -0.03321366
    ## (estimated using likelihood);
    ## and (mean) root node prior probabilities
    ## pi =
    ##    0    1    2    3 
    ## 0.25 0.25 0.25 0.25

    ## Done.

``` r
summaries <- summary(maps)

colors <- c("0"="black", 
            "1"="green", 
            "2"="red",
            "3"="blue")

{ 
  plot(summaries, colors=colors)
  trash <- sapply(maps, markChanges, sapply(colors, make.transparent,0.05))
}
```

![](README_files/figure-gfm/ace%20-%20stage%20-%20simulation-1.png)<!-- -->
Correlated evolution

``` r
# First, convert stages to binary characters -- presence of each stage
stage1Binary <- map_dbl(treePruned$tip.label,
                        ~ filter(stagesData, Taxon==.)$S1Binary) 
names(stage1Binary) <- treePruned$tip.label

stage2Binary <- map_dbl(treePruned$tip.label,
                        ~ filter(stagesData, Taxon==.)$S2Binary) 
names(stage2Binary) <- treePruned$tip.label

stage3Binary <- map_dbl(treePruned$tip.label,
                        ~ filter(stagesData, Taxon==.)$S3Binary) 
names(stage3Binary) <- treePruned$tip.label

# Now get a matrix of concentrated lek trait coding
concentrated <- map_df(treePruned$tip.label,
                       ~ filter(stagesData, Taxon==.) %>% select(Concentrated_Present, Concentrated_Absent)) %>%
             as.matrix()
names(concentrated) <- treePruned$tip.label


# And a named matrix of coordinated display trait coding
coordinated <- map_df(treePruned$tip.label,
                      ~ filter(stagesData, Taxon==.) %>% select(Coordinated_Present, Coordinated_Absent)) %>%
            as.matrix()
names(coordinated) <- treePruned$tip.label
  
# A function to extract key results from the fitPagel discrete correlation test
tidyFitPagel <- function(x, y, model) {
  results <- fitPagel(tree=treePruned,
                      x=x,
                      y=y,
                      method="fitMk",
                      model=model)
  ret <- tibble(model=model, p=results$P,
                AIC_ind=results$independent.AIC, AIC_dep=results$dependent.AIC) %>%
      mutate(dAIC = AIC_dep - AIC_ind)
  return(ret)
}

corrs_S1_Concentrated <- map_df(c("ER", "SYM","ARD"), ~ tidyFitPagel(stage1Binary, concentrated, .)) %>%
                      mutate(Social="Concentrated", .before=1) %>%
                      mutate(Stage="S1", .before=2)

corrs_S2_Concentrated <- map_df(c("ER", "SYM","ARD"), ~ tidyFitPagel(stage2Binary, concentrated, .)) %>%
                      mutate(Social="Concentrated", .before=1) %>%
                      mutate(Stage="S2", .before=2)

corrs_S3_Concentrated <- map_df(c("ER", "SYM","ARD"), ~ tidyFitPagel(stage3Binary, concentrated, .)) %>%
                      mutate(Social="Concentrated", .before=1) %>%
                      mutate(Stage="S3", .before=2)
```

    ## Warning in log(comp[1:M + N]): NaNs produced
    
    ## Warning in log(comp[1:M + N]): NaNs produced

``` r
corrs_Concentrated <- bind_rows(corrs_S1_Concentrated, corrs_S2_Concentrated, corrs_S3_Concentrated)


corrs_S1_Coordinated <- map_df(c("ER", "SYM","ARD"), ~ tidyFitPagel(stage1Binary, coordinated, .)) %>%
                     mutate(Social="Coordinated", .before=1) %>%
                     mutate(Stage="S1", .before=2)

corrs_S2_Coordinated <- map_df(c("ER", "SYM","ARD"), ~ tidyFitPagel(stage2Binary, coordinated, .)) %>%
                     mutate(Social="Coordinated", .before=1) %>%
                     mutate(Stage="S2", .before=2)

corrs_S3_Coordinated <- map_df(c("ER", "SYM","ARD"), ~ tidyFitPagel(stage3Binary, coordinated, .)) %>%
                     mutate(Social="Coordinated", .before=1) %>%
                     mutate(Stage="S3", .before=2)

corrs_Coordinated <- bind_rows(corrs_S1_Coordinated, corrs_S2_Coordinated, corrs_S3_Coordinated)

corrs <- bind_rows(corrs_Concentrated, corrs_Coordinated)
```

### Ancestral State Estimation: Predefinitve Plumage Patches

Produce simmaps

Plot simmaps

## References

Alberch, P., S. J. Gould, G. F. Oster, and D. B. Wake. 1979. Size and
shape in ontogeny and phylogeny. Paleobiology:296–317.

Anciães, M., A. Nemésio, and F. Sebaio. 2005. A case of plumage
aberration in the Pin-tailed Manakin. Cotinga 23:39–43.

Aramuni, F. V. 2019. Custo individual, ontogenia e visita de fêmeas como
moduladores da exibição de corte de machos em *Corapipo gutturalis*
(Aves: Pipridae). Thesis for the Instituto Nacional de Pesquisas da
Amazônia.

Cárdenas‐Posada, G., C. D. Cadena, J. G. Blake, and B. A. Loiselle.
2018. Display behaviour, social organization and vocal repertoire of
Blue-backed Manakin Chiroxiphia pareola napensis in northwest Amazonia.
Ibis 160:269–282.

Doucet, S. M., D. B. McDonald, M. S. Foster, and R. P. Clay. 2007.
Plumage development and molt in Long-tailed Manakins (*Chiroxiphia
linearis*): variation according to sex and age. The Auk 124:29–43.

DuVal, E. H. 2005. Age-based plumage changes in the lance-tailed
manakin: a two-year delay in plumage maturation. The Condor 107:915–920.

Foster, M. S. 1987. Delayed maturation, neoteny, and social system
differences in two manakins of the genus *Chiroxiphia*. Evolution
41:547–558.

Gaiotti, M. G. 2016. *Antilophia bokermanni* (Aves: Pipridae):
Parâmetros reprodutivos, sistema de acasalamento social e genético e o
papel da seleção sexual. Thesis for the Universidade de Brasília.

Gould, S. J. 1977. Ontogeny and phylogeny. Harvard University Press.

Hellmayr, C. E. 1929. A contribution to the ornithology of northeastern
Brazil. Field Museum of Natural History 12.

Jetz, W., G. H. Thomas, J. B. Joy, K. Hartmann, and A. O. Mooers. 2012.
The global diversity of birds in space and time. Nature 491:444–448.

Lewis P.O. 2001. A Likelihood Approach to Estimating Phylogeny from
Discrete Morphological Character Data. Systematic Biology.

Mallet-Rodrigues, F., and R. Dutra. 2012. Acquisition of definitive
adult plumage in male Blue Manakins *Chiroxiphia caudata*. Cotinga 34.

Marini, M. Â., and R. B. Cavalcanti. 1992. Mating System of the Helmeted
Manakin (*Antilophia galeata*) in Central Brazil. The Auk 109:911–913.

Prum, R. O. 1986. The displays of the White-throated Manakin *Corapipo
gutturalis* in Suriname. Ibis 128:91–102.

Prum, R. O., and J. Dyck. 2003. A hierarchical model of plumage:
morphology, development, and evolution. Journal of Experimental Zoology
Part B: Molecular and Developmental Evolution 298:73–90.

Rosselli, L. 1994. The annual cycle of the White-ruffed Manakin
*Corapipo leucorrhoa*, a tropical frugivorous altitudinal migrant, and
its food plants. Bird Conservation International 4:143–160.
