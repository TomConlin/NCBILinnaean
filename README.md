

### Towards a simplified NCBI Taxon tree
Basically interested in; given a taxon:

 - what is its scientific name.
 - what is its (_approximate_) Rank.
 - what are its phylogenetic ancestors/decedents
 - what are its nearby neighbors
    - [_grandmothers, aunts, mother, sisters, daughters, cousins, neices_]

Furthermore instead of including everything (over a million taxon),
limit to a subtree along the human ancestor path,
choosing a branch point covering our 10k or so closest relatives.

Also want some bacteria, but they are far too many
so choose 10k or so which  are within a few hops of
the most commonly studied (reference) species.


Linnaean Rank [Kingdom, Phylum ... etc ]
is a older, corse concept rendered obsolete
with modern molecular phylogenetic trees.
Traditional Rank does however have the redeeming quality that many people still know it,
which makes it useful as a structure to assist navigation.

One of main use cases for Rank is to know if the taxon
is for leaf node (e.g. Species) or a more general collection
as we may want to consider them differently.

NCBI Taxon has many (non-leaf) taxon associated with
the single designation of __"no rank"__.
In this dataset I have promoted all such taxon to the Linnaean Rank
of their nearest ranked ancestor.

### Zeroth implementation
See the readme in the `research/` directory

### First implementation

Reading in, translating to turtle, then writing out
as a plain python stream took 15-20 seconds,
but it does not afford a easy way to write out independent subtrees
e.g. just  eukaryotes or just bacteria.

### Second implementation

For better of worse we use python `RDFLIB` for other `dipper` ingests and so
it is the first thing to try.
Loading this into a rdflib graph as a simple buffer takes 5 minutes
and writing out as turtle takes another 10 minutes.

This is 15 minutes without attempting any additional processing.

Calling a built in RDFLIB function such as `graph.connected()`
takes more hours to return than I have have patience for
(I think I let it run over night)
and does not bode well for using it with similar tasks at this scale.

### Third implementation (2018)

Sqlite3/Postgres have common table expressions (CTE) which enable recursive SQL queries
and I used them as a Jena SDB work-alike in a previous project.

Loading it all in on the command line, indexing,
asking a bunch of questions and writing out the superphylum
covering human's 10,000 closest relatives takes a few seconds in sql.
A few more seconds for a similar sized set for bacteria.

see `load_sqlite.sql` for how I am filtering for ~ 10k eukaryotes
based on decendents along Human's ancestoral path.

and  `README.ncbi_ref_genome` for how I am choosing ~12k bacteria
which are based on close proxmity to NCBI's reference genomes.

tr -d '\t' < names.dmp  > names.unl
tr -d '\t' < nodes.dmp  > nodes.unl
###################################################################

### Fourth implementation (2020)

Revisiting due to a desire to include virus.
Note: THere a fair amount of change in the data from the previous version.

Goals: 
    - minimize changes to their `.dmp` format prior to loading
    - include citations, genetic code,  files 
    - generate a more useful representation of "no rank" inernal nodes (interval based)
    - increase number of taxon to propagate. (not sure how far)
    
 



