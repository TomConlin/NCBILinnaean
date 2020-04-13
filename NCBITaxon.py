"""
    Important disclaimer.
    This is not a Taxonomy!
    it is a simplified reflection of the NCBITaxon Database
    which also:  IS NOT A TAXONOMY.

    Model
    - Taxon class has subclasses of kingdom, phylym, class...species
    - ncbi-txids are instances of these Taxon subclasses
    - there is a proper superset-subset relation between all Taxon subclasses
    - hence between instance chains of ncbi-txids.

    The relation between lineage rank types "a part_of b" (partonomy)
    exists inedpendent of the data but is not useful to capture.
    ex: knowing genus is more general than species implies nothing
    if their material instances are not related by being on the same path.



"""

# import gzip
# import logging
# import requests
import re
import yaml
import rdflib

# the GenBank divisions are a high level & arbitrary partition the tree
# e.g. a child in one division may require a parent in another division.
# Think I will abandon them ... yep

# read the Linage Rank translation table yaml file
LTT = {}

tx_dec = []

with open('translationtable/NCBITaxon.yaml') as fh:
    LTT = yaml.safe_load(fh)
    # experiment with the order of the first column
    fh.seek(0, 0)
    for line in fh:
        if re.match(r"'[a-z ]*':", line) is not None:
            tx_dec.append(line.split(":")[0].strip("'"))

# they should not squat on 'root'
# it is a CS term in a domain with plants
# LTT['NCBIroot'] = 'root'

tx_inc = tx_dec[::-1]
# for t in tx_inc]:
#    print(t)

# fetch  ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz
# into data/ (if it has been updated)

node_parent = {}
node_rank = {}
node_label = {}

# extract node, names,
with open('data/names.dmp', 'r') as fh:
    for line in fh:
        try:
            (tax_id,        # the id of node associated with this name
             name_txt,      # name itself
             unique_name,   # the unique variant of this name if name not unique
             name_class,    # (synonym, common name, scientific name, ...)
             nl
             ) = line.split('\t|')
        except ValueError as ve:
            print(ve)
            print(line)
            exit(-1)

        if name_class == '\tscientific name':
            node_label[int(tax_id)] = name_txt.strip('\t')

# extract node
with open('data/nodes.dmp', 'r') as fh:
    for line in fh:
        (tax_id,                # node id in GenBank taxonomy database
         parent_tax_id,         # parent node id in GenBank taxonomy database
         rank,                  # rank of this node (kingdom, phylum, ...)
         embl_code,             # locus-name prefix; not unique
         division_id,           # see division.dmp file
         inherited_div_flag,    # 1 if node inherits division from parent
         genetic_code_id,       # see gencode.dmp file
         inherited_GC_flag,     # 1 if node inherits genetic code from parent
         mitochondrialgenetic_code_id,  # see gencode.dmp file
         inherited_MGC_flag,    # 1 if node inherits mitochondrial gencode from parent
         GenBank_hidden_flag,   # 1 if name is suppressed in GenBank entry lineage
         hidden_subtree_root_flag,  # 1 if this subtree has no sequence data yet
         comments,              # free-text comments and citations
         nl
         ) = line.split('\t|')

        # limit to taxa with sequence in GenBank?
        if hidden_subtree_root_flag != '\t1':
            # load hash maps {txid: -> whatever}
            tax_id = int(tax_id)
            node_parent[tax_id] = int(parent_tax_id.strip('\t'))
            node_rank[tax_id] = rank.strip('\t')

# if need be; chase pointers,
# remapping rank to nearest ranked ancestor
# note: the root (1)  points to itself
node_ancestor_rank = {}
for txid in node_parent:
    if node_rank[txid] != "no rank" and txid != 1:
        tpid = txid
    else:
        tpid = node_parent[txid]
        while node_rank[tpid] == "no rank" and tpid != 1:
            tpid = node_parent[tpid]
    if txid > 1:
        node_ancestor_rank[txid] = node_rank[tpid]
    else:
        node_ancestor_rank[1] = "NCBIroot"




g = rdflib.Graph()

# output prefixs and extablish Taxon as a class
# @prefix owl: <http://www.w3.org/2002/07/owl#> .

OBO = rdflib.Namespace('http://purl.obolibrary.org/obo/')
WIKI = rdflib.Namespace('https://en.wikipedia.org/wiki/')
dcterms = rdflib.Namespace('http://purl.org/dc/terms/')

g.bind('OBO', OBO)
g.bind('dcterms', dcterms)
g.bind('WIKI', WIKI)

#######################################################
# TBox (terminology)
# concepts as subclass of Taxon
# let concepts know their children (opposite direction of ABox)

Taxon = WIKI.Taxon
g.add([Taxon, rdflib.RDF.type, rdflib.RDFS.Class])
g.add([
    Taxon, rdflib.RDFS.comment,
    rdflib.Literal("Not a taxonomy. see: NCBI Taxon Database")])
g.add([Taxon, rdflib.RDFS.label, rdflib.Literal("Taxon")])
g.add([
    Taxon, rdflib.RDFS.subClassOf,
    rdflib.URIRef('http://www.w3.org/2002/07/owl#Thing')])

for i in range(len(tx_inc)-1):
    tx = rdflib.URIRef("https://en.wikipedia.org/wiki/" + LTT[tx_inc[i]])
    g.add([tx, rdflib.RDF.type, Taxon])
    # has_part
    g.add([
        tx, dcterms.hasPart,
        rdflib.URIRef("https://en.wikipedia.org/wiki/" + LTT[tx_inc[i+1]])])
    g.add([tx, rdflib.RDFS.label, rdflib.Literal(tx_inc[i])])

# and the last one too
tx = rdflib.URIRef("https://en.wikipedia.org/wiki/" + LTT[tx_dec[len(tx_dec)-1]])
g.add([tx, rdflib.RDF.type, Taxon])
g.add([tx, rdflib.RDFS.label, rdflib.Literal(txid)])

# output "ranked" nodes
#
# Perhaps filtering at the Scigraph level any nodes which are
# not at least on the path of a cousin of an extant Monarch species.

# base case
g.add([OBO.NCBITaxon_1, rdflib.RDF.type, Taxon])
g.add([OBO.NCBITaxon_1, rdflib.RDFS.label, rdflib.Literal('NCBIroot')])
# g.add([OBO.NCBITaxon_1, ,'https://www.ncbi.nlm.nih.gov/taxonomy'])

# first step
# connect 'cellular organisms' to root
g.add([OBO.NCBITaxon_131567, rdflib.RDF.type, Taxon])
g.add([OBO.NCBITaxon_131567, rdflib.RDFS.subClassOf, OBO.NCBITaxon_1])
g.add([
    OBO.NCBITaxon_131567, rdflib.RDFS.label,
    rdflib.Literal('cellular organisms')])

for n in node_parent:
    if node_rank[n] != "no rank" and n > 1:  # avoid top loop
        # ABox (Actual) taxon instances
        tx = OBO["NCBITaxon_" + str(n)]
        # instance_of
        g.add([tx, rdflib.RDF.type, WIKI[LTT[node_ancestor_rank[n]]]])

        # part_of
        g.add([
            tx, rdflib.RDFS.subClassOf,
            OBO["NCBITaxon_" + str(node_parent[n])]])

        # some 'scientific names' contain single & double quotes --blecch
        g.add([
            tx, rdflib.RDFS.label,
            rdflib.Literal(node_label[n].replace('"', '\\"').strip("'"))])


################################################################

g.serialize(destination='/dev/stdout', format='turtle')
