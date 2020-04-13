
.print "\nFind children of #7711 Chordata\n"
.timer on
.once data/human_phylum.tab
WITH RECURSIVE subtree(node_id) AS
    (SELECT tax_id FROM nodes WHERE tax_id == 7711
	 UNION
	 SELECT tax_id FROM nodes JOIN subtree ON parent_tax_id == node_id
    )
SELECT distinct
		parent_tax_id, node_id, name_txt, nodes.rank, rank_hi, rank_lo
	FROM subtree  
     join nodes on node_id == nodes.tax_id
     join names on node_id == names.tax_id
     join taxon_ranks on node_id == taxon_ranks.tax_id
	 order by rank_hi
    -- limit 100
;
.timer off
