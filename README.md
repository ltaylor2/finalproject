# Phylogenetic Biology - EEB 654 - Final Project

# Working commit - 2020-11-22

# Ontogenetic Phylogenetics, and the Evolution of Delayed Plumage Maturation in Manakins

### Plumage Characters

### Backbone Phylogeny

### Ancestral State Reconstruction
I used [RevBayes](https://revbayes.github.io/) to perform a symmetric unordered ancestral state construction across all of the independent plumage characters. This analysis uses the very simple Mk model (Lewis 2001) with the three states for all plumage characters. The corresponding rate matrix ($Q$) is thus a symmetric 3x3 transition matrix governed by a single parameter ($\mu$).

The code for this preliminary RevBayes analysis is available in ```Scripts/mcmc_ase_mk.Rev```. For a simple start to the analysis, I ran two independent chains of 500,000 iterations each with a thinning of 500 and a burn-in of 25%.

We can quickly check that this analysis is clicking together by viewing posterior distributions and some preliminary character estimations. First, I can see that the single model parameter ($\mu$) is already mixing nicely within and across chains:
![Trace for ($\mu$) parameter](Figures/trace_mu.png)

And I can view the density distribution across the whole posterior:
![Density plot for ($\mu$) parameter](Figures/dens_mu.png)

Finally, I can start to view ancestral state estimations. Here is the same Ilicurini tree annotated with the states of "Crown" plumage patch (S1-S2-S3 at each node). White dots indicate a character state of 0, and Red dots indicate a state of 1.
![Ancestral state reconstruction for the "Crown" plumage patch](Figures/anc_crown_tree.png)

Kinda neat!

## References
Alberch, P., S. J. Gould, G. F. Oster, and D. B. Wake. 1979. Size and shape in ontogeny and phylogeny. Paleobiology:296–317.

Anciães, M., A. Nemésio, and F. Sebaio. 2005. A case of plumage aberration in the Pin-tailed Manakin. Cotinga 23:39–43.

Aramuni, F. V. 2019. Custo individual, ontogenia e visita de fêmeas como moduladores da exibição de corte de machos em *Corapipo gutturalis* (Aves: Pipridae). Thesis for the Instituto Nacional de Pesquisas da Amazônia.

Cárdenas‐Posada, G., C. D. Cadena, J. G. Blake, and B. A. Loiselle. 2018. Display behaviour, social organization and vocal repertoire of Blue-backed Manakin Chiroxiphia pareola napensis in northwest Amazonia. Ibis 160:269–282.

Doucet, S. M., D. B. McDonald, M. S. Foster, and R. P. Clay. 2007. Plumage development and molt in Long-tailed Manakins (*Chiroxiphia linearis*): variation according to sex and age. The Auk 124:29–43.

DuVal, E. H. 2005. Age-based plumage changes in the lance-tailed manakin: a two-year delay in plumage maturation. The Condor 107:915–920.

Foster, M. S. 1987. Delayed maturation, neoteny, and social system differences in two manakins of the genus *Chiroxiphia*. Evolution 41:547–558.

Gaiotti, M. G. 2016. *Antilophia bokermanni* (Aves: Pipridae): Parâmetros reprodutivos, sistema de acasalamento social e genético e o papel da seleção sexual. Thesis for the Universidade de Brasília.

Gould, S. J. 1977. Ontogeny and phylogeny. Harvard University Press.

Hellmayr, C. E. 1929. A contribution to the ornithology of northeastern Brazil. Field Museum of Natural History 12.

Jetz, W., G. H. Thomas, J. B. Joy, K. Hartmann, and A. O. Mooers. 2012. The global diversity of birds in space and time. Nature 491:444–448.

Lewis P.O. 2001. A Likelihood Approach to Estimating Phylogeny from Discrete Morphological Character Data. Systematic Biology.

Mallet-Rodrigues, F., and R. Dutra. 2012. Acquisition of definitive adult plumage in male Blue Manakins *Chiroxiphia caudata*. Cotinga 34.

Marini, M. Â., and R. B. Cavalcanti. 1992. Mating System of the Helmeted Manakin (*Antilophia galeata*) in Central Brazil. The Auk 109:911–913.

Prum, R. O. 1986. The displays of the White-throated Manakin *Corapipo gutturalis* in Suriname. Ibis 128:91–102.

Prum, R. O., and J. Dyck. 2003. A hierarchical model of plumage: morphology, development, and evolution. Journal of Experimental Zoology Part B: Molecular and Developmental Evolution 298:73–90.

Rosselli, L. 1994. The annual cycle of the White-ruffed Manakin *Corapipo leucorrhoa*, a tropical frugivorous altitudinal migrant, and its food plants. Bird Conservation International 4:143–160.
