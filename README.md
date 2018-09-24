

### Towards a simplified NCBI Taxon tree
Basically interested in; given a taxon:

 - what is its scientific name.
 - what is its (_approximate_) Rank.
 - what are its phylogenetic ancestors/decedents
 - what are its nearby neighbors (_cousins_)

Linnaean Rank [Kingdom, Phylum ... etc ]
is a older, corse concept rendered obsolete
with modern molecular phylogenetic trees.
Traditional Rank does however have the redeeming quality
that many people still know it, which makes it useful
as a structure to assist navigation.

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

Reading in, translating to turtle, then writing out as a plain python
stream took 15-20 seconds, but it did not afford a easy way to write out
independent subtrees e.g. just  eukaryotes or just bacteria.

### Second implementation

For better of worse we use python `RDFLIB` for other `dipper` ingests and so
it is the first thing to try. Loading this into a rdflib graph as a buffer
takes 5 minutes and writing out as turtle takes another 10 minutes.

This is without attempting any additional processing.

Calling a built in RDFLIB function such as `graph.connected()`
takes more hours to return than I have have patience for
(I think I let it run over night)
and does not bode well for using it with similar tasks at this scale.

## Third implementation

Sqlite3/Postgres have common table expressions (CTE)
which enable recursive SQL queries and I used them as a Jena SDB work-alike
in a previous project.

Loading it all in indexing asking a bunch of questions
and writing out the superphylum covering human's 10,000
closest relatives takes a few seconds in sql.

see `load_sqlite.sql`


