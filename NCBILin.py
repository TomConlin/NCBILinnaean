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
    exists inedpendent of the data but is not super useful to capture.
    ex: knowing genus is more general than species implies very little
    if their material instances are not related by being on the same path.

"""

# import gzip
# import logging
# import requests
import re
import yaml
import sqlite3


# (if it has been updated) fetch several hundred Meg into data/
# ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz

# read the Linage Rank translation table yaml file
LTT = {}
rank_order = {}
node_parent = {}
node_rank = {}
node_label = {}

con = sqlite3.connect(":memory:")
con.isolation_level = None
cur = con.cursor()

with open('translationtable/NCBITaxon.yaml') as fh:
    # they should not squat on 'root'
    # it is a CS term in a domain with plants
    LTT = yaml.safe_load(fh)
    # capture the order of the taxon rank labels
    # to make the classes they represent comparable
    key_num = 0
    fh.seek(0, 0)
    for line in fh:
        if re.match(r"'[a-z ]*':", line) is not None:
            rank_order[LTT[(line.split(":")[0].strip("'"))]] = int(pow(2, key_num))
            key_num = key_num + 1

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
        # when we are asked to include other names, start here

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

        # limit to taxa with sequence in GenBank?  ...not that there are any w/o seq...
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
    rnk_id = txid
    while node_rank[rnk_id] == "no rank" and rnk_id > 1:
        rnk_id = node_parent[rnk_id]

    if rnk_id == 1:
        node_ancestor_rank[txid] = "root"
    else:
        node_ancestor_rank[txid] = node_rank[rnk_id]

cur.execute("""
CREATE TABLE IF NOT EXISTS taxon_node(
    tn_node INTEGER NOT NULL PRIMARY KEY,
    tn_parent iNTEGER NOT NULL,
    tn_rank VARCHAR(50) NOT NULL,
    tn_label VARCHAR(100) NOT NULL
);
""")

table = [
    [txid,
    node_parent[txid],
    LTT[node_ancestor_rank[txid]],
    node_label[txid]]
    for txid in node_parent
]

cur.executemany("insert into taxon_node values(?,?,?,?);", table)

cur.execute("CREATE INDEX tn_parent_idx ON taxon_node(tn_parent);")
cur.execute("CREATE INDEX tn_label_idx ON taxon_node(tn_label);")

cur.execute("""
CREATE TABLE rank_order(
    ro_rank VARCHAR(30) NOT NULL PRIMARY KEY,
    ro_order INTEGER NOT NULL
);
""")

cur.executemany("insert into rank_order values(?,?);",
    [(k, rank_order[k]) for k in rank_order])

cur.execute("VACUUM FULL;")
# cur.execute("ANALYSE;")

# for row in cur.execute("select * from rank_order order by 2;"):
#    print(row)
#for row in cur.execute("select * from taxon_node limit 5;"):
#   print(row)
#print()
#for row in cur.execute("select * from rank_order limit 5;"):
#   print(row)
#################################################################
kingdom_of_man_query = """
WITH RECURSIVE subtree(parent_id, child_id, child_order) AS (
    SELECT tn_parent, tn_node, ro_order
      FROM taxon_node
        JOIN rank_order ON ro_rank == tn_rank
       WHERE tn_parent == 33511
     UNION
     SELECT tn_parent, tn_node, ro_order
      FROM taxon_node
        JOIN rank_order ON ro_rank == tn_rank
        JOIN subtree ON tn_parent == child_id
    )
SELECT DISTINCT parent_id, child_id, tn_label, tn_rank, child_order
    FROM subtree, taxon_node
     WHERE tn_node == child_id
    ORDER BY child_order
    limit 100
;
"""

for row in cur.execute(kingdom_of_man_query):
    print(row)

#
# dump all as TSV
#with open('out/taxon_node_name.tab', 'wt') as fh:
#   for txid in node_parent:
#        fh.write('\t'.join((
#            str(txid),
#           str(node_parent[txid]),
#            LTT[node_ancestor_rank[txid]],
#            node_label[txid])) + '\n')
