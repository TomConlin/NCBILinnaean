
.print "howmany taxon loaded?\n"
select '-- ' || count(*) taxon_nodes from names;
-- 2,237,473
.print "howmany edges loaded?\n"
select '-- ' || count(*) as ancestory_edges from nodes;
-- 2,237,473

-- same number of nodes and edges,
-- technicaly, a tree should have one fewer edge than nodes
-- but they have a self edge on the root

.print "How are my rank label order looking

select ro_order, rank, label 
 from rank_label join rank_order on label = ro_rank
 order by 1
;

.print "How are their ranks looking?\n"
select rank, count(*) howmany from nodes group by 1 order by 2
;

-- a quarter of the taxon (all internal nodes) have no rank
-- which means closer to half of the internal nodes are not ranked
-- which means I should do something to at least bracket unranked taxa.


.print "\nHow many by ~Linnaean~ rank?\n"
select ro_order, label, count(*) howmany
 from nodes
	join rank_label on nodes.rank = rank_label.rank
	join rank_order on label = ro_rank
 group by 1,2 order by 1
;

-----------------------------------

.print
.print "What are the top level root(s)?\n"

select '-- ' ||nodes.tax_id, names.name_txt
  from nodes
  join names on nodes.tax_id == names.tax_id
    where parent_tax_id == 1;
-- 1	root
-- 10239	Viruses
-- 12908	unclassified sequences
-- 28384	other sequences
-- 131567	cellular organisms

--             lost "viroids"

.print
.print "What are the starting points under 'cellular organisms'?\n"

select '-- ' ||nodes.tax_id, names.name_txt
  from nodes
  join names on nodes.tax_id == names.tax_id
    where parent_tax_id == 131567;

-- 2	Bacteria
-- 2157	Archaea
-- 2759	Eukaryota

.print
.print "What are the starting points under 'Eukaryotas'?\n"
select '-- ' ||nodes.tax_id, names.name_txt
  from nodes
  join names on nodes.tax_id == names.tax_id
    where parent_tax_id == 2759;

-- 2763	Rhodophyta
-- 3027	Cryptophyceae
-- 33090	Viridiplantae
-- 33154	Opisthokonta
-- 38254	Glaucocystophyceae
-- 42452	unclassified eukaryotes
-- 61964	environmental samples
-- 136087	Malawimonadidae
-- 554296	Apusozoa
-- 554915	Amoebozoa
-- 1401294	Breviatea
-- 2489521	Hemimastigophora
-- 2598132	Rhodelphea
-- 2608109	Haptista
-- 2608240	CRuMs
-- 2611341	Metamonada
-- 2611352	Discoba
-- 2683617	Eukaryota incertae sedis
-- 2686027	Ancyromonadida
-- 2698737	Sar

--  quite different from a couple of years ago, both fewer & some different

.print
.print "What are the sizes of the subtrees rooted under 'Eukaryotas'?\n"

WITH RECURSIVE anchors(parent_id, child_id, cnt) AS
	(select parent_tax_id, tax_id, 0 as cnt
	  from nodes 
      where parent_tax_id in 
        (select tax_id from nodes where parent_tax_id == 2759)
	union all
	select parent_id, tax_id, 1
	from nodes join anchors on parent_tax_id == child_id
	)
select '-- ' || parent_id, name_txt, sum(cnt)
 from anchors 
    join nodes on parent_id == nodes.tax_id
    join names on names.tax_id == nodes.tax_id
 group by 1,2 order by 3 desc
;

-- 33154	Opisthokonta	1217333     # animals and fungi
-- 33090	Viridiplantae	222596      # green algae
-- 2698737	Sar	34931                   # SAR supergroup ?
-- 2763	Rhodophyta	8637                # red algae
-- 554915	Amoebozoa	3368            # Amoeba
-- 2611352	Discoba	2639                # unicellular, heterotrophic flagellates
-- 2611341	Metamonada	913
-- 2608109	Haptista	812
-- 3027	Cryptophyceae	430
-- 61964	environmental samples	250
-- 42452	unclassified eukaryotes	221
-- 2683617	Eukaryota incertae sedis	46
-- 554296	Apusozoa	38
-- 38254	Glaucocystophyceae	27
-- 2686027	Ancyromonadida	20
-- 2608240	CRuMs	18
-- 1401294	Breviatea	8
-- 136087	Malawimonadidae	5
-- 2489521	Hemimastigophora	4
-- 2598132	Rhodelphea	4


.print
.print "What are the starting points under 'Opisthokonta'?\n"


WITH RECURSIVE anchors(parent_id, child_id, cnt) AS
	(select parent_tax_id, tax_id, 0
	  from nodes 
      where parent_tax_id in 
        (select tax_id from nodes where parent_tax_id == 33154)
	union all
	select parent_id, tax_id, 1
	from nodes join anchors on parent_tax_id  == child_id
	)
select '-- ' || parent_id, name_txt, sum(cnt)
 from anchors 
    join nodes on parent_id == nodes.tax_id
    join names on names.tax_id == nodes.tax_id
 group by 1,2 order by 3 desc;


-- 33208	Metazoa	1049089
-- 4751	    Fungi	167764
-- 127916	Ichthyosporea	226
-- 28009	Choanoflagellata	139     # closest living relatives of the animals
-- 2686024	Rotosphaerida	45
-- 2316435	Aphelida	22
-- 42461	Opisthokonta incertae sedis	7
-- 2687318	Filasterea	6
-- 2006544	unclassified Opisthokonta	0
-- 610163	environmental samples	0



.print
.print "What are the starting points under 'Metazoa'?\n"
WITH RECURSIVE anchors(parent_id, child_id, cnt) AS
	(select parent_tax_id, tax_id, 0
	  from nodes 
      where parent_tax_id in 
        (select tax_id from nodes where parent_tax_id == 33208)
	union all
	select parent_id, tax_id, 1
	from nodes join anchors on parent_tax_id  == child_id
	)
select '-- ' || parent_id, name_txt, sum(cnt)
 from anchors 
    join nodes on parent_id == nodes.tax_id
    join names on names.tax_id == nodes.tax_id
 group by 1,2 order by 3 desc;

-- 6072	Eumetazoa	1044520
-- 6040	Porifera	4555                # Sponge
-- 212041	environmental samples	0


.print
.print "What are the starting points under 'Eumetazoa'?\n"
WITH RECURSIVE anchors(parent_id, child_id, cnt) AS
	(select parent_tax_id, tax_id, 0
	  from nodes 
      where parent_tax_id in 
        (select tax_id from nodes where parent_tax_id == 6072)
	union all
	select parent_id, tax_id, 1
	from nodes join anchors on parent_tax_id  == child_id
	)
select '-- ' || parent_id, name_txt, sum(cnt)
 from anchors 
    join nodes on parent_id == nodes.tax_id
    join names on names.tax_id == nodes.tax_id
 group by 1,2 order by 3 desc;

-- 33213	Bilateria	1032939         # linear symeteric
-- 6073	Cnidaria	11232               # aquatic (jellyfish)
-- 10197	Ctenophora	219             # marine invertebrate
-- 10226	Placozoa	108


.print
.print "What are the starting points under 'Bilateria'?\n"
WITH RECURSIVE anchors(parent_id, child_id, cnt) AS
	(select parent_tax_id, tax_id, 0
	  from nodes 
      where parent_tax_id in 
        (select tax_id from nodes where parent_tax_id == 33213)
	union all
	select parent_id, tax_id, 1
	from nodes join anchors on parent_tax_id  == child_id
	)
select '-- ' || parent_id, name_txt, sum(cnt)
 from anchors 
    join nodes on parent_id == nodes.tax_id
    join names on names.tax_id == nodes.tax_id
 group by 1,2 order by 3 desc;


-- 33317	Protostomia	926424          # mouth forms first
-- 33511	Deuterostomia	105,868     # anus forms first   !!! 2018 this was 9,136 !!!
-- 1312402	Xenacoelomorpha	637         # do not have a true gut
-- 589317	environmental samples	0

.print "I have no idea if we are head or butt first\n"

WITH RECURSIVE decendents(parent_id, child_id, cnt) AS
	(select parent_tax_id, tax_id, 0
	  from nodes where tax_id == 9606
	union
	select parent_tax_id, tax_id, cnt +1
	  from nodes join decendents on tax_id  == parent_id
	  where tax_id > 1
	)
select '-- ' || child_id, name_txt, rank
 from decendents 
    join nodes on child_id == nodes.tax_id
    join names on names.tax_id == nodes.tax_id
 order by cnt desc;

-- 131567	cellular organisms	no rank
-- 2759	    Eukaryota	    superkingdom
-- 33154	Opisthokonta	no rank
-- 33208	Metazoa	        kingdom
-- 6072	    Eumetazoa	    no rank
-- 33213	Bilateria	    no rank
-- 33511	Deuterostomia	no rank
-- 7711	    Chordata	    phylum
-- 89593	Craniata	    subphylum
-- 7742	    Vertebrata	    no rank
-- 7776	    Gnathostomata	no rank
-- 117570	Teleostomi	    no rank
-- 117571	Euteleostomi	no rank
-- 8287	    Sarcopterygii	superclass
-- 1338369	Dipnotetrapodomorpha	no rank
-- 32523	Tetrapoda	    no rank
-- 32524	Amniota	        no rank
-- 40674	Mammalia	    class
-- 32525	Theria	        no rank
-- 9347	    Eutheria	    no rank
-- 1437010	Boreoeutheria	no rank
-- 314146	Euarchontoglires	superorder
-- 9443	    Primates	    order
-- 376913	Haplorrhini	    suborder
-- 314293	Simiiformes	    infraorder
-- 9526	    Catarrhini	    parvorder
-- 314295	Hominoidea	    superfamily
-- 9604	    Hominidae	    family
-- 207598	Homininae	    subfamily
-- 9605	    Homo	        genus
-- 9606	    Homo sapiens	species



-- there yer problem,  we are breech
-------------------------------------------------------------------
.print
.print "What are the starting points under 'Deuterostomia'?\n"
WITH RECURSIVE anchors(parent_id, child_id, cnt) AS
	(select parent_tax_id, tax_id, 0
	  from nodes 
      where parent_tax_id in 
        (select tax_id from nodes where parent_tax_id == 33511)
	union all
	select parent_id, tax_id, 1
	from nodes join anchors on parent_tax_id  == child_id
	)
select '-- ' || parent_id, name_txt, sum(cnt)
 from anchors 
    join nodes on parent_id == nodes.tax_id
    join names on names.tax_id == nodes.tax_id
 group by 1,2 order by 3 desc;

-- 7711	Chordata	100882          
-- 7586	Echinodermata	4826        # starfish
-- 10219	Hemichordata	150     # marine acorn worms


.print
.print "What are the starting points under 'Chordata'?\n"
WITH RECURSIVE anchors(parent_id, child_id, cnt) AS
	(select parent_tax_id, tax_id, 0
	  from nodes 
      where parent_tax_id in
        (select tax_id from nodes where parent_tax_id == 7711)
	union all
	select parent_id, tax_id, 1
	from nodes join anchors on parent_tax_id  == child_id
	)
select '-- ' || parent_id, name_txt, sum(cnt)
 from anchors 
    join nodes on parent_id == nodes.tax_id
    join names on names.tax_id == nodes.tax_id
 group by 1,2 order by 3 desc;

-- 89593	Craniata	100079          # skull & notocore (vertabrae optional)
-- 7712	Tunicata	752                 # marine filter feeders
-- 7735	Cephalochordata	29              # segmented marine filter feeders
-- 1003298	unclassified Chordata	0
-- 547488	environmental samples	0

.print
.print "What are the starting points under 'Craniata'?\n"
WITH RECURSIVE anchors(parent_id, child_id, cnt) AS
	(select parent_tax_id, tax_id, 0
	  from nodes 
      where parent_tax_id in 
        (select tax_id from nodes where parent_tax_id == 89593)
	union all
	select parent_id, tax_id, 1
	from nodes join anchors on parent_tax_id  == child_id
	)
select '-- ' || parent_id, name_txt, sum(cnt)
 from anchors 
    join nodes on parent_id == nodes.tax_id
    join names on names.tax_id == nodes.tax_id
 group by 1,2 order by 3 desc;

-- 7742	Vertebrata	100076	# Craniata sans hagfish/lamprey and kin

.print
.print "What are the starting points under 'Vertebrata'?\n"
WITH RECURSIVE anchors(parent_id, child_id, cnt) AS
	(select parent_tax_id, tax_id, 0
	  from nodes 
      where parent_tax_id in 
        (select tax_id from nodes where parent_tax_id == 7742)
	union all
	select parent_id, tax_id, 1
	from nodes join anchors on parent_tax_id  == child_id
	)
select '-- ' || parent_id, name_txt, sum(cnt)
 from anchors 
    join nodes on parent_id == nodes.tax_id
    join names on names.tax_id == nodes.tax_id
 group by 1,2 order by 3 desc;

-- 7776	Gnathostomata	99501           # jawed vertebrates
-- 1476529	Cyclostomata	569         # jawless fishes
-- 1476749	environmental samples	0


.print
.print "What are the starting points under 'Gnathostomata'?\n"
WITH RECURSIVE anchors(parent_id, child_id, cnt) AS
	(select parent_tax_id, tax_id, 0
	  from nodes 
      where parent_tax_id in 
        (select tax_id from nodes where parent_tax_id == 7776)
	union all
	select parent_id, tax_id, 1
	from nodes join anchors on parent_tax_id  == child_id
	)
select '-- ' || parent_id, name_txt, sum(cnt)
 from anchors 
    join nodes on parent_id == nodes.tax_id
    join names on names.tax_id == nodes.tax_id
 group by 1,2 order by 3 desc;

-- 117570	Teleostomi	97411		# obsolete clade of jawed vertebrates
-- 7777 	Chondrichthyes	2086	# cartilaginous fishes


.print
.print "What are the starting points under 'Teleostomi'?\n"
WITH RECURSIVE anchors(parent_id, child_id, cnt) AS
	(select parent_tax_id, tax_id, 0
	  from nodes 
      where parent_tax_id in 
        (select tax_id from nodes where parent_tax_id == 117570)
	union all
	select parent_id, tax_id, 1
	from nodes join anchors on parent_tax_id  == child_id
	)
select '-- ' || parent_id, name_txt, sum(cnt)
 from anchors 
    join nodes on parent_id == nodes.tax_id
    join names on names.tax_id == nodes.tax_id
 group by 1,2 order by 3 desc;

-- 117571	Euteleostomi	97409  # not much different

.print
.print "What are the starting points under 'Euteleostomi'?\n"
WITH RECURSIVE anchors(parent_id, child_id, cnt) AS
	(select parent_tax_id, tax_id, 0
	  from nodes where parent_tax_id in 
        (select tax_id from nodes where parent_tax_id == 117571)
	union all
	select parent_id, tax_id, 1
	from nodes join anchors on parent_tax_id  == child_id
	)
select '-- ' || parent_id, name_txt, sum(cnt)
 from anchors 
    join nodes on parent_id == nodes.tax_id
    join names on names.tax_id == nodes.tax_id
 group by 1,2 order by 3 desc;


-- 8287	Sarcopterygii	52374		# lobe-finned fish  < that's us
-- 7898	Actinopterygii	45029		# ray-finned fishes


.print
.print "Lots of fun but pretty sure we are past the optimal cutoff\n"
.print "Superphylum is the where the numeric discontinunity"
.print "from over half a million to under 10k\n"  2018

-- 2020 things have changed more (10x) species in our path now 

.print
.print "What are the starting points under 'Sarcopterygii'?\n"
WITH RECURSIVE anchors(parent_id, child_id, cnt) AS
	(select parent_tax_id, tax_id, 0
	  from nodes where parent_tax_id in 
        (select tax_id from nodes where parent_tax_id == 8287)
	union all
	select parent_id, tax_id, 1
	from nodes join anchors on parent_tax_id  == child_id
	)
select '-- ' || parent_id, name_txt, sum(cnt)
 from anchors 
    join nodes on parent_id == nodes.tax_id
    join names on names.tax_id == nodes.tax_id
 group by 1,2 order by 3 desc;

-- 1338369	Dipnotetrapodomorpha	52367
-- 118072	Coelacanthimorpha	4
-- that does not help much

.print
.print "What are the starting points under 'Dipnotetrapodomorpha'?\n"
WITH RECURSIVE anchors(parent_id, child_id, cnt) AS
	(select parent_tax_id, tax_id, 0
	  from nodes where parent_tax_id in 
        (select tax_id from nodes where parent_tax_id == 1338369)
	union all
	select parent_id, tax_id, 1
	from nodes join anchors on parent_tax_id  == child_id
	)
select '-- ' || parent_id, name_txt, sum(cnt)
 from anchors 
    join nodes on parent_id == nodes.tax_id
    join names on names.tax_id == nodes.tax_id
 group by 1,2 order by 3 desc;

-- 32523	Tetrapoda	52337
-- 7878	Dipnoi	27

.print
.print "What are the starting points under 'Tetrapoda'?\n"
WITH RECURSIVE anchors(parent_id, child_id, cnt) AS
	(select parent_tax_id, tax_id, 0
	  from nodes where parent_tax_id in 
        (select tax_id from nodes where parent_tax_id == 32523)
	union all
	select parent_id, tax_id, 1
	from nodes join anchors on parent_tax_id  == child_id
	)
select '-- ' || parent_id, name_txt, sum(cnt)
 from anchors 
    join nodes on parent_id == nodes.tax_id
    join names on names.tax_id == nodes.tax_id
 group by 1,2 order by 3 desc;

-- 32524	Amniota	41194
-- 8292	Amphibia	11138

.print
.print "What are the starting points under 'Amniota'?\n"
WITH RECURSIVE anchors(parent_id, child_id, cnt) AS
	(select parent_tax_id, tax_id, 0
	  from nodes where parent_tax_id in 
        (select tax_id from nodes where parent_tax_id == 32524)
	union all
	select parent_id, tax_id, 1
	from nodes join anchors on parent_tax_id  == child_id
	)
select '-- ' || parent_id, name_txt, sum(cnt)
 from anchors 
    join nodes on parent_id == nodes.tax_id
    join names on names.tax_id == nodes.tax_id
 group by 1,2 order by 3 desc;

-- 8457	Sauropsida	29202
-- 40674	Mammalia	11987

-------------------------------------------------------------------
-------------------------------------------------------------------

-- I previously made  taxa  with "no rank" the rank of their nearest ranked ancestor. 
-- now I want (all) taxa to have a range or interval which is a better representation 
-- of the inherent uncertinty ecpecially reguarding presumed ancestor taxon. 


drop table if exists taxon_ranks;
create table taxon_ranks(
    tax_id int not null references names(tax_id),
    rank_hi smallint default NULL,
    rank_lo smallint default NULL
);

insert into taxon_ranks 
select tax_id, ro_order, ro_order 
    from nodes 
    join rank_label on nodes.rank == rank_label.rank
    join rank_order on rank_label.label == ro_rank
;

-- select count(*) from taxon_ranks;  --1,969,541 out of 2,237,473

-- does an unranked taxon ever have conflicting parent ranks?
select nodes.tax_id, count(rank_lo) 
 from taxon_ranks join nodes on taxon_ranks.tax_id == parent_tax_id
 where nodes.rank == "no rank" 
 group by 1 having count(rank_lo) > 1
;
-- no results ... is good

-- howmany unranked taxon have an single parent rank?
select count(*) 
 from taxon_ranks join nodes on taxon_ranks.tax_id == parent_tax_id
 where nodes.rank == "no rank" 
;
-- 119,081   about half the unranked have a unambigiously ranked parent 
-- these parent.rank_lo would become rank_hi of the unranked node

-- does an unranked taxon ever have conflicting children ranks?
-- (it does seem more likely than conclicting parents as there are more oppertunities)


select parent.tax_id, count(distinct rank_hi) 
 from taxon_ranks 
    join nodes child on taxon_ranks.tax_id == child.tax_id
    join nodes parent on parent.tax_id = child.parent_tax_id
 where parent.rank == "no rank" 
  group by 1 
    having count(distinct rank_hi) > 1 order by 2
;


-- perhaps a hundred with two, and a dozen or so with three, and one with four 
-- should be able to handle this by being maximaly inclusive
-- so the deepest rank of a child becomes an unranked taxon's 'rank_lo'
-- hmmm I think could be a failure mode where a deeper taxon appear in a later itteration.
-- try setting the more difficult rank_lo first using the null rank_hi as a flag
-- to continue reconsidering lower updates.



insert into taxon_ranks(tax_id, rank_lo)
select parent.tax_id, max(rank_hi) 
    from taxon_ranks 
    join nodes child on taxon_ranks.tax_id == child.tax_id
    join nodes parent on parent.tax_id = child.parent_tax_id
 where parent.rank == "no rank" 
  group by 1 
;

-- select count(*) from taxon_ranks where rank_hi is NULL; 
-- adds 48,842  or ~20% of what is needed



---------------------------------------------------------------------------
-----------------------------------------------------------------------------
























--------------------------------------------------------------------
--  partition sub tree
---------------------------------
-- In 2018 I took the superphylum for human and it included about 10k taxon
-- in 2020 dropping down to phylum results in over 100k
-- I'm not comfortable starting lower in the tree as we quickly loose spiny fin fish
-- .read SQL/select_human_phylum.sql

.read SQL/select_human_phylum.sql

------------------------------------


--.output out/taxon_dump.sql
--.dump
--.output stdout
--.save out/taxon_dump.db
