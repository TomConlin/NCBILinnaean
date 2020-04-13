--


-- drop table taxon_node;

create table taxon_node(
	tn_node integer not null primary key,
	tn_parent integer not null,
	tn_rank varchar(30) not null,
	tn_label varchar(80) not null
);

.mode tabs
.print "load taxons"
.timer on
.import out/taxon_node.tab taxon_node
create index tn_parent_idx on taxon_node(tn_parent);
create index tn_label_idx on taxon_node(tn_label);
.timer off

create table rank_order(
	ro_order integer NOT NULL unique,
	ro_rank varchar(30) not null unique
);
.import translationtable/rank_order.tab rank_order
-- no index or keys; just a small cv table

VACUUM FULL;
--ANALYSE;

.print "howmany taxon loaded?\n"
select  count(*) as tn_cnt from taxon_node;

.print "\nHow many by ~Linnaean~ rank?\n"
.timer on
select tn_rank, count(*) howmany
 from taxon_node
	join rank_order on ro_rank == tn_rank
 group by  tn_rank order by ro_order
;
.timer off
-----------------------------------

.print "What are the top level root(s)?\n"

 select '-- ' || tn_node, tn_label from taxon_node where tn_parent == 1;
-- 1	root
-- 10239	Viruses
-- 12884	Viroids
-- 12908	unclassified sequences
-- 28384	other sequences
-- 131567	cellular organisms

.print
.print "What are the starting points under 'cellular organisms'?\n"
select  '-- ' || tn_node, tn_label from taxon_node where tn_parent == 131567;
-- 2	Bacteria
-- 2157	Archaea
-- 2759	Eukaryota

.print
.print "What are the starting points under 'Eukaryotas'?\n"
select tn_node, tn_label from taxon_node where tn_parent == 2759;
-- 2763	Rhodophyta
-- 2830	Haptophyceae
-- 3027	Cryptophyta
-- 5719	Parabasalia
-- 5752	Heterolobosea
-- 33090	Viridiplantae
-- 33154	Opisthokonta
-- 33630	Alveolata
-- 33634	Stramenopiles
-- 33682	Euglenozoa
-- 38254	Glaucocystophyceae
-- 42452	unclassified eukaryotes
-- 61964	environmental samples
-- 66288	Oxymonadida
-- 136087	Malawimonadidae
-- 193537	Centroheliozoa
-- 207245	Fornicata
-- 339960	Katablepharidophyta
-- 543769	Rhizaria
-- 554296	Apusozoa
-- 554915	Amoebozoa
-- 556282	Jakobida
-- 1401294	Breviatea

.print
.print "What are the sizes of the subtrees rooted under 'Eukaryotas'?\n"

WITH RECURSIVE anchors(parent_id, child_id, cnt) AS
	(select tn_parent, tn_node, 0
	  from taxon_node where tn_parent in (
		select tn_node from taxon_node where tn_parent == 2759)
	union all
	select parent_id, tn_node, 1
	from taxon_node join anchors on tn_parent  == child_id
	)
select '-- ' || parent_id, tn_label, sum(cnt)
 from anchors join taxon_node on parent_id == tn_node
 group by 1,2 order by 3 desc;

-- 33154	Opisthokonta	810017   	# animals and fungi
-- 33090	Viridiplantae	198937		# green algae
-- 33630	Alveolata	16588        	# single-celled eukaryotes
-- 33634	Stramenopiles	11173		# unicellular flagellates
-- 2763 	Rhodophyta	7669			# red algae
-- 554915	Amoebozoa	3092			# Amoeba
-- 543769	Rhizaria	3008			# unicellular eukaryotes
-- 33682	Euglenozoa	1840			# flagellate excavates (no mitocondera)
-- 2830 	Haptophyceae	600
-- 5719 	Parabasalia	556
-- 5752 	Heterolobosea	522
-- 3027 	Cryptophyta	348
-- 42452	unclassified eukaryotes	278
-- 61964	environmental samples	250
-- 207245	Fornicata	157
-- 193537	Centroheliozoa	69
-- 554296	Apusozoa	61
-- 66288	Oxymonadida	58
-- 38254	Glaucocystophyceae	25
-- 556282	Jakobida	22
-- 339960	Katablepharidophyta	15
-- 136087	Malawimonadidae	4
-- 1401294	Breviatea	4



.print
.print "What are the starting points under 'Opisthokonta'?\n"


WITH RECURSIVE anchors(parent_id, child_id, cnt) AS
	(select tn_parent, tn_node, 0
	  from taxon_node where tn_parent in (
		select tn_node from taxon_node where tn_parent == 33154)
	union all
	select parent_id, tn_node, 1
	from taxon_node join anchors on tn_parent  == child_id
	)
select '-- ' || parent_id, tn_label, sum(cnt)
 from anchors join taxon_node on parent_id == tn_node
 group by 1,2 order by 3 desc;

-- 33208	Metazoa	658717
-- 4751	Fungi	150885
-- 42461	Opisthokonta incertae sedis	225			#
-- 28009	Choanoflagellida	118					# closest living relatives of the animals
-- 1001604	Nucleariidae and Fonticula group	32  # nigh fungi
-- 1498967	Aphelidea	10							# sister to true fungi
-- 2006544	unclassified Opisthokonta	0
-- 610163	environmental samples	0


.print
.print "What are the starting points under 'Metazoa'?\n"
WITH RECURSIVE anchors(parent_id, child_id, cnt) AS
	(select tn_parent, tn_node, 0
	  from taxon_node where tn_parent in (
		select tn_node from taxon_node where tn_parent == 33208)
	union all
	select parent_id, tn_node, 1
	from taxon_node join anchors on tn_parent  == child_id
	)
select '-- ' || parent_id, tn_label, sum(cnt)
 from anchors join taxon_node on parent_id == tn_node
 group by 1,2 order by 3 desc;

-- 6072 	Eumetazoa	654809
-- 6040 	Porifera	3726			# Sponge
-- 10226	Placozoa	104				# basal free-living multicellular organism
-- 10213	Mesozoa	61					# !???  tiny parasites that live in the renal appendages of cephalopods
-- 212041	environmental samples	0


.print
.print "What are the starting points under 'Eumetazoa'?\n"
WITH RECURSIVE anchors(parent_id, child_id, cnt) AS
	(select tn_parent, tn_node, 0
	  from taxon_node where tn_parent in (
		select tn_node from taxon_node where tn_parent == 6072)
	union all
	select parent_id, tn_node, 1
	from taxon_node join anchors on tn_parent  == child_id
	)
select '-- ' || parent_id, tn_label, sum(cnt)
 from anchors join taxon_node on parent_id == tn_node
 group by 1,2 order by 3 desc;

-- 33213	Bilateria	645413			# symeteric
-- 6073		Cnidaria	9176			# aquatic (jellyfish)
-- 10197	Ctenophora	200				# marine invertebrate

.print
.print "What are the starting points under 'Bilateria'?\n"
WITH RECURSIVE anchors(parent_id, child_id, cnt) AS
	(select tn_parent, tn_node, 0
	  from taxon_node where tn_parent in (
		select tn_node from taxon_node where tn_parent == 33213)
	union all
	select parent_id, tn_node, 1
	from taxon_node join anchors on tn_parent  == child_id
	)
select '-- ' || parent_id, tn_label, sum(cnt)
 from anchors join taxon_node on parent_id == tn_node
 group by 1,2 order by 3 desc;

-- 33317	Protostomia	543609			# mouth forms first
-- 33511	Deuterostomia	9136		# anus forms first   !!! BIG JUMP!!!
-- 6157 	Platyhelminthes	10045		# flatworms
-- 1312402	Xenacoelomorpha	326			# do not have a true gut
-- 66780	Gnathostomulida	48			# microscopic marine jaw worms
-- 589317	environmental samples	0

.print "I have no idea if we are head or butt first\n"

WITH RECURSIVE decendents(parent_id, child_id, cnt) AS
	(select tn_parent, tn_node, 0
	  from taxon_node where tn_node == 9606
	union
	select tn_parent, tn_node, cnt +1
	  from taxon_node join decendents on tn_node  == parent_id
	  where tn_node > 1
	)
select '-- ' || child_id, tn_label
 from decendents join taxon_node on child_id == tn_node
 order by cnt desc;

-- 131567	cellular organisms
-- 2759 	Eukaryota
-- 33154	Opisthokonta
-- 33208	Metazoa
-- 6072 	Eumetazoa
-- 33213	Bilateria
-- 33511	Deuterostomia
-- 7711 	Chordata
-- 89593	Craniata
-- 7742 	Vertebrata
-- 7776 	Gnathostomata
-- 117570	Teleostomi
-- 117571	Euteleostomi
-- 8287 	Sarcopterygii
-- 1338369	Dipnotetrapodomorpha
-- 32523	Tetrapoda
-- 32524	Amniota
-- 40674	Mammalia
-- 32525	Theria
-- 9347 	Eutheria
-- 1437010	Boreoeutheria
-- 314146	Euarchontoglires
-- 9443 	Primates
-- 376913	Haplorrhini
-- 314293	Simiiformes
-- 9526 	Catarrhini
-- 314295	Hominoidea
-- 9604 	Hominidae
-- 207598	Homininae
-- 9605 	Homo
-- 9606 	Homo sapiens

-- there yer problem,  were breech
-------------------------------------------------------------------
.print
.print "What are the starting points under 'Deuterostomia'?\n"
WITH RECURSIVE anchors(parent_id, child_id, cnt) AS
	(select tn_parent, tn_node, 0
	  from taxon_node where tn_parent in (
		select tn_node from taxon_node where tn_parent == 33511)
	union all
	select parent_id, tn_node, 1
	from taxon_node join anchors on tn_parent  == child_id
	)
select '-- ' || parent_id, tn_label, sum(cnt)
 from anchors join taxon_node on parent_id == tn_node
 group by 1,2 order by 3 desc;

-- 7711 	Chordata	86991
-- 7586 	Echinodermata	4072	# starfish
-- 10229	Chaetognatha	182		# predatory marine arrow worms
-- 10219	Hemichordata	106		# marine acorn worms

.print
.print "What are the starting points under 'Chordata'?\n"
WITH RECURSIVE anchors(parent_id, child_id, cnt) AS
	(select tn_parent, tn_node, 0
	  from taxon_node where tn_parent in (
		select tn_node from taxon_node where tn_parent == 7711)
	union all
	select parent_id, tn_node, 1
	from taxon_node join anchors on tn_parent  == child_id
	)
select '-- ' || parent_id, tn_label, sum(cnt)
 from anchors join taxon_node on parent_id == tn_node
 group by 1,2 order by 3 desc;

-- 89593	Craniata	86326			# skull & notocore (vertabrae optional)
-- 7712 	Tunicata	634				# marine filter feeders
-- 7735 	Cephalochordata	18			# segmented marine filter feeders
-- 1003298	unclassified Chordata	0
-- 547488	environmental samples	0

.print
.print "What are the starting points under 'Craniata'?\n"
WITH RECURSIVE anchors(parent_id, child_id, cnt) AS
	(select tn_parent, tn_node, 0
	  from taxon_node where tn_parent in (
		select tn_node from taxon_node where tn_parent == 89593)
	union all
	select parent_id, tn_node, 1
	from taxon_node join anchors on tn_parent  == child_id
	)
select '-- ' || parent_id, tn_label, sum(cnt)
 from anchors join taxon_node on parent_id == tn_node
 group by 1,2 order by 3 desc;

-- 7742	Vertebrata	86323	# Craniata sans hagfish/lamprey and kin



.print
.print "What are the starting points under 'Vertebrata'?\n"
WITH RECURSIVE anchors(parent_id, child_id, cnt) AS
	(select tn_parent, tn_node, 0
	  from taxon_node where tn_parent in (
		select tn_node from taxon_node where tn_parent == 7742)
	union all
	select parent_id, tn_node, 1
	from taxon_node join anchors on tn_parent  == child_id
	)
select '-- ' || parent_id, tn_label, sum(cnt)
 from anchors join taxon_node on parent_id == tn_node
 group by 1,2 order by 3 desc;

-- 7776 	Gnathostomata	86140		# jawed vertebrates
-- 1476529	Cyclostomata	177			# jawless fishes
-- 1476749	environmental samples	0


.print
.print "What are the starting points under 'Gnathostomata'?\n"
WITH RECURSIVE anchors(parent_id, child_id, cnt) AS
	(select tn_parent, tn_node, 0
	  from taxon_node where tn_parent in (
		select tn_node from taxon_node where tn_parent == 7776)
	union all
	select parent_id, tn_node, 1
	from taxon_node join anchors on tn_parent  == child_id
	)
select '-- ' || parent_id, tn_label, sum(cnt)
 from anchors join taxon_node on parent_id == tn_node
 group by 1,2 order by 3 desc;

-- 117570	Teleostomi	84385		# obsolete clade of jawed vertebrates
-- 7777 	Chondrichthyes	1751	# cartilaginous fishes


.print
.print "What are the starting points under 'Teleostomi'?\n"
WITH RECURSIVE anchors(parent_id, child_id, cnt) AS
	(select tn_parent, tn_node, 0
	  from taxon_node where tn_parent in (
		select tn_node from taxon_node where tn_parent == 117570)
	union all
	select parent_id, tn_node, 1
	from taxon_node join anchors on tn_parent  == child_id
	)
select '-- ' || parent_id, tn_label, sum(cnt)
 from anchors join taxon_node on parent_id == tn_node
 group by 1,2 order by 3 desc;

-- 117571	Euteleostomi	84383  # not much different

.print
.print "What are the starting points under 'Euteleostomi'?\n"
WITH RECURSIVE anchors(parent_id, child_id, cnt) AS
	(select tn_parent, tn_node, 0
	  from taxon_node where tn_parent in (
		select tn_node from taxon_node where tn_parent == 117571)
	union all
	select parent_id, tn_node, 1
	from taxon_node join anchors on tn_parent  == child_id
	)
select '-- ' || parent_id, tn_label, sum(cnt)
 from anchors join taxon_node on parent_id == tn_node
 group by 1,2 order by 3 desc;


-- 8287	Sarcopterygii	46980		# lobe-finned fish  < that's us
-- 7898	Actinopterygii	37397		# ray-finned fishes


.print
.print "Lots of fun but pretty sure we are past the optimal cutoff\n"
.print "Superphylum is the where the numeric discontinunity"
.print "from over half a million to under 10k\n"

--------------------------------------------------------------------
--  partition sub tree
---------------------------------

-- would like to inject/include a query from its own file
-- like
-- .import select_subtree.sql
-- but not finding an option

.print "\nFind children of #33511 Deuterostomia\n"
.timer on
.once out/human_superphylum.tab
WITH RECURSIVE subtree(parent_id, child_id, child_order) AS
    (SELECT tn_parent, tn_node, ro_order
	  FROM taxon_node
		JOIN rank_order ON ro_rank == tn_rank
	   WHERE tn_parent == 33511
	 UNION
	 SELECT tn_parent, tn_node, ro_order
	  FROM taxon_node
		JOIN rank_order ON ro_rank == tn_rank
		JOIN subtree ON tn_parent == child_id
    )
SELECT distinct
		parent_id, child_id, tn_label, tn_rank, child_order
	FROM subtree, taxon_node
	 WHERE tn_node == child_id
	 order by child_order
;

.timer off
------------------------------------


.output out/taxon_dump.sql
.dump
.output stdout


.save out/taxon_dump.db
