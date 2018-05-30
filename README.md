

### Towards a simplfied NCBI Taxon tree
Basicly intrested in; given a taxon:
 
 - what is its scientific name.
 - what is its (_approximate_) Rank.
 - what are its phylogenetic ancestors/decendents
 - what are its nearby neighbors (_cousins_)

Lineage Rank [Kingdom, Phylum ... etc ]
is a older, corse concept rendered obsolete
with modern molecular phylogenetic trees.
Traditional Rank does however have the redeaming quality
that many people still know it, which makes it useful
as a structure to assist navigation.

One of main use cases for Rank is to know if the taxon
is for leaf node (e.g. Species) or a more general collection
as we may want to consider them differently.

NCBI Taxon has many (non-leaf) taxon associated with  
the single designation of __"no rank"__.   
In this dataset I have promoted all such taxon to the Lineage Rank
of their nearest ranked anccestor.

### Zeroth implementation
Just poke around in the research directory

### First implementation

Reading in, translating to turtle, then writing out as a plain python
stream took 15-20 seconds, but it did not afford a easy way to write out
independent subtrees e.g. just eucaryotes or just bacteria.

### Second implementation

For better of worse we use `RDFLIB` for other `dipper` ingests and so
it is the first thing to try. Loading this into a rdflib graph as a buffer
takes 5 minutes and writing out as turtle takes another 10 minutes.  

This is without attempting any addtional processing.

Using the builtin RDFLIB functions such as `g.connected()`
takes more hours than I have have paitence for and does not bode well.
