Rebuild the dataset as it has been a couple of years.

in ./data

wget --timestamping ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump_readme.txt

wget --timestamping ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz
  
tar -tvf taxdump.tar.gz 

wc -l *.dmp
    54561 citations.dmp
   428784 delnodes.dmp
       12 division.dmp
       28 gencode.dmp
    57312 merged.dmp
  3182434 names.dmp
  2237473 nodes.dmp
  5960604 total


*** Each of the files store one record in the single line that are delimited by "\t|\n"
    (tab, vertical bar, and newline) characters.
*** Each record consists of one or more fields delimited by "\t|\t" 
    (tab, vertical bar, and tab) characters.


However for sqlite3  "multi-character column separators not allowed for import"

*   1	tax_id					-- node id in GenBank taxonomy database
*   2 	parent tax_id		    -- parent node id in GenBank taxonomy database
*   3 	rank					-- rank of this node (superkingdom, kingdom, ...) 
*   4 	embl code				-- locus-name prefix; not unique
*   5 	division id				-- see division.dmp file
    6 	inherited div flag  (1 or 0)		-- 1 if node inherits division from parent
*   7 	genetic code id				        -- see gencode.dmp file
    8 	inherited GC  flag  (1 or 0)		-- 1 if node inherits genetic code from parent
*   9 	mitochondrial genetic code id		-- see gencode.dmp file
    10 	inherited MGC flag  (1 or 0)		-- 1 if node inherits mitochondrial gencode from parent
    11 	GenBank hidden flag (1 or 0)        -- 1 if name is suppressed in GenBank entry lineage
    12 	hidden subtree root flag (1 or 0)   -- 1 if this subtree has no sequence data yet
    13 	comments				            -- free-text comments and citations
 

Thus
since we have to process the separators drop un-needed fields 

sed 's/\t|\t/\t/g;s/\t|$//' nodes.dmp|awk -F'\t' 'BEGIN{OFS="\t"}{print $1,$2,$3,$4,$5,$7,$9}'> nodes.tab

# they have no quoting dicipline, 
sed 's/\t|\t/\t/g;;s/|\t/\t/g;s/\t|$//' names.dmp|
    tr -d '"'|sed "s/'\t/\t/g;s/\t'/\t/g" | fgrep "scientific name"  > names.tab

# or primary key dicipline
sed 's/\t|\t/\t/g;;s/|\t/\t/g;s/\t|$//' names.dmp|
    tr -d '"'|sed "s/'\t/\t/g;s/\t'/\t/g" | fgrep -v "scientific name"  > synonyms.tab

sed 's/\t|\t/\t/g;s/\t|$//'  division.dmp > division.tab
sed 's/\t|\t/\t/g;s/\t|$//'  gencode.dmp > gencode.tab
sed 's/\t|\t/\t/g;s/\t|$//'  citations.dmp|awk -F'\t' 'BEGIN{OFS="\t"}{print $1,$2,$3,$4,$5,$7}' > citations.tab


in ./translationtable/  there is a .yaml file 
that may need to be converted to tab for loading

grep -v "^#" translationtable/NCBITaxon.yaml |
    grep -v "^ *$" |
    tr -d "\t'-" |
    tr -s ' ' |
    sed 's/ *: */:/' |
    tr ':' '\t' > translationtable/rank_label.tab

(there is also a 'rank_order.tab' already there.)
if rank_order tab needs to be re numbered:

cp translationtable/rank_order.tab translationtable/rank_order.old~
cut -f 2  translationtable/rank_order.old~ | grep -n . |
    tr ':' ' \t' > translationtable/rank_order.tab 


# make a sql load script 'SQL/create_ncbitaxon_tables.sql'

sqlite3 ncbilinnean < SQL/create_ncbitaxon_tables.sql

# runs in about 16 seconds results in a ~ 200M database


# identifying upper and lower ranges of ranks for taxa where possible
sqlite3 ncbilinnean < SQL/generate_taxon_ranks_interval.sql

# Note there are some new (non)ranks  ... section, subsection ... which are ignored 

--SQL-------------------------------------------


-- What is Viruses top tax_id?

select * from names where name_txt == 'Viruses';

10239|Viruses||scientific name

-- How many are there?

with recursive viruses(virus_id) as
(select 10239 union select tax_id from nodes join viruses on parent_tax_id  == virus_id)
select count(*) from viruses;

206,415


-- How many are trivially Crona related?

select count(*) from names where name_txt like '%corona%';

1,937

-- What is their common ancestor taxon?

select distinct parent_tax_id, name_txt, ro_rank, rank_hi , rank_lo
    from nodes join names on names.tax_id == nodes.tax_id 
    join taxon_ranks on parent_tax_id == taxon_ranks.tax_id
    join rank_order on rank_hi == ro_order
    where name_txt like '%corona%'
    order by rank_hi
limit 20
;
-- note tax_id is parent of rank ...
6142|Coronatae|Class_(biology)|12|12                (crown jellyfishes), order, jellyfishes
710185|Coronarctidae|Order_(biology)|21|21          family, tardigrades 

2499399|Coronaviridae|Order_(biology)#suborder|22|22 ******** family, viruses *********

40417|Clavicorona|Family_(biology)|26|26                genus, basidiomycetes
105874|Coronaster|Family_(biology)|26|26                genus, starfish
29966|Coronalpheus|Family_(biology)|26|26               genus, crustaceans

11118|Coronavirinae|Family_(biology)|26|26              subfamily, viruses ************
11118|unclassified Coronaviridae|Family_(biology)|26|26 viruses ***********************

128162|Lophocorona|Family_(biology)|26|26               genus, moths
3086|Coronastrum|Family_(biology)|26|26                 genus, green algae
216368|Corona|Family_(biology)|26|26                    genus, gastropods
5148|Coronatomyces|Family_(biology)|26|26               genus, ascomycetes
6214|Coronacanthus|Family_(biology)|26|26               genus, flatworms
195022|uncultured Clavicorona|Family_(biology)|26|35    species, basidiomycetes
1785946|Coronarctus|Family_(biology)|26|26              genus, tardigrades

1986197|Coronaviridae sp.|Family_(biology)|26|35        species, viruses **************
1260509|Auricorona|Family_(biology)|26|26               genus, gastropods
1986197|Rhinolophus pusillus coronavirus|Family_(biology)|26|35
11118|Orthocoronavirinae|Family_(biology)|26|26
1986197|Gull coronavirus|Family_(biology)|26|35


-- How many taxon below Coronaviridae reguardless of name

with recursive coronas(virus_id) as
(select 2499399 union select tax_id from nodes join coronas on parent_tax_id == virus_id)
select count(*) from coronas;

1,645


-- Collect all taxon below Coronaviridae reguardless of name
.once data/NCBItaxon_Coronaviridae.unl
with recursive coronas(virus_id) as
(select 2499399 union select nodes.tax_id from nodes join coronas on parent_tax_id == virus_id)
select distinct virus_id, name_txt , ro_rank, rank_hi, rank_lo 
 from coronas join names on virus_id == names.tax_id
    join taxon_ranks on virus_id == taxon_ranks.tax_id
    join rank_order on rank_hi == ro_order
    order by rank_hi
;


head  data/NCBItaxon_Coronaviridae.unl
2499399|Cornidovirineae|Order_(biology)#suborder|22|22
11118|Coronaviridae|Family_(biology)|26|26
1986197|unclassified Coronaviridae|Family_(biology)|26|35
693995|Coronavirinae|Subfamily|27|27
2501931|Orthocoronavirinae|Subfamily|27|27
2664420|unclassified Coronavirinae|Subfamily|27|35
441985|Guangxi coronaviridae|Subfamily|27|35
693996|Alphacoronavirus|Genus|31|31
694002|Betacoronavirus|Genus|31|31
694013|Gammacoronavirus|Genus|31|31


drop table if not exists coronaviridae;
create table coronaviridae(virus_id, name, rank, rank_hi, rank_lo);

with recursive coronas(virus_id) as
(select 2499399 union select nodes.tax_id from nodes join coronas on parent_tax_id == virus_id)
insert into coronaviridae
select distinct virus_id, name_txt name, ro_rank  rank, rank_hi, rank_lo 
 from coronas join names on virus_id == names.tax_id
    join taxon_ranks on virus_id == taxon_ranks.tax_id
    join rank_order on rank_hi == ro_order
    order by rank_hi
;


########################################################################################
In ./Viral/data

cut -f 22 assembly_summary_refseq-1.txt | dist
 177424 
  12869 assembly from type material
   5017 ICTV species exemplar
    226 assembly from synonym type material
    154 ICTV additional isolate
     37 assembly from pathotype material
     22 assembly designated as reftype
     17 assembly designated as neotype
      1 #   See ftp://ftp.ncbi.nlm.nih.gov/genomes/README_assembly_summary.txt for a description of the columns in this file.
      1 relation_to_type_material


# Being more inclusive
grep -E "virus|phage|ICTV" assembly_summary_refseq-1.txt  | wc -l
    9,172

# Being more particular
grep "ICTV " assembly_summary_refseq-1.txt > viral_assembly_summary_refseq.txt

wc -l < viral_assembly_summary_refseq.txt 
    5,171 


head -2 assembly_summary_refseq-1.txt | tail -1 | tr '\t' '\n' | grep -n .
1:# assembly_accession
2:bioproject
3:biosample
4:wgs_master
5:refseq_category
6:taxid
7:species_taxid
8:organism_name
9:infraspecific_name
10:isolate
11:version_status
12:assembly_level
13:release_type
14:genome_rep
15:seq_rel_date
16:asm_name
17:submitter
18:gbrs_paired_asm
19:paired_asm_comp
20:ftp_path
21:excluded_from_refseq
22:relation_to_type_material


cut -f 21 viral_assembly_summary_refseq.txt | dist
   4857 
    314 partial


cut -f 5 viral_assembly_summary_refseq.txt | dist
   5137 na
     33 reference genome
      1 representative genome

grep "reference genome" viral_assembly_summary_refseq.txt | cut -f8| sort
Chlamydia phage 2
Chlamydia phage CPG1
Cyrtanthus elatus virus A
Dengue virus 2
Enterovirus C
Equine arteritis virus
Escherichia phage alpha3
Escherichia virus T4
Hepatitis C virus genotype 1
Hepatitis C virus genotype 7
Hippeastrum mosaic virus
Human immunodeficiency virus 1
Human mastadenovirus A
Human mastadenovirus B
Influenza C virus (C/Ann Arbor/1/50)
Japanese encephalitis virus
Marburg marburgvirus
Measles morbillivirus
Middle East respiratory syndrome-related coronavirus
Murray Valley encephalitis virus
Norovirus GI
Panicum mosaic satellite virus
Pegivirus A
Rodent pegivirus
Sesbania mosaic virus
Severe acute respiratory syndrome-related coronavirus
Simian immunodeficiency virus
Sudan ebolavirus
Sweet potato virus 2
Tai Forest ebolavirus
West Nile virus
Yellowtail ascites virus
Zika virus


# that is a start


grep "corona" viral_assembly_summary_refseq.txt |  cut -f8| sort
Bat coronavirus 1A
Bat coronavirus CDPHE15/USA/2006
Bat Hp-betacoronavirus/Zhejiang2013
Beluga whale coronavirus SW1
Betacoronavirus Erinaceus/VMC/DEU/2012
Betacoronavirus HKU24
Bulbul coronavirus HKU11-934
Common moorhen coronavirus HKU21
Human coronavirus 229E
Human coronavirus HKU1
Human coronavirus NL63
Human coronavirus OC43
Lucheng Rn rat coronavirus
Middle East respiratory syndrome-related coronavirus
Miniopterus bat coronavirus HKU8
Mink coronavirus strain WD1127
Munia coronavirus HKU13-3514
Night heron coronavirus HKU19
Pipistrellus bat coronavirus HKU5
Porcine coronavirus HKU15
Rhinolophus bat coronavirus HKU2
Rousettus bat coronavirus
Rousettus bat coronavirus HKU10
Rousettus bat coronavirus HKU9
Scotophilus bat coronavirus 512
Severe acute respiratory syndrome-related coronavirus
Tylonycteris bat coronavirus HKU4
White-eye coronavirus HKU16
Wigeon coronavirus HKU20

# that is some more

need someting to associate with hosts...

#################################################

https://www.genome.jp/virushostdb/

curl ftp://ftp.genome.jp/pub/db/virushostdb/
-rw-r--r--   1 500      ideas        3737 May 30  2019 README
-rw-rw-r--   1 500      ideas          76 Mar 17 05:10 dbrel.txt
-rw-rw-r--   1 500      ideas      478435 Mar 17 05:11 non-segmented_virus_list.tsv
drwxrwxr-x  24 500      ideas        4096 Mar 19 00:53 old
-rw-rw-r--   1 500      ideas       77632 Mar 17 05:10 segmented_virus_list.tsv
-rw-r--r--   1 500      ideas     1711674 Apr  5 21:01 taxid2lineage_abbreviated_VH.tsv
-rw-r--r--   1 500      ideas     2227020 Apr  5 21:01 taxid2lineage_full_VH.tsv
-rw-r--r--   1 500      ideas     4130896 Apr  5 21:01 taxid2parents_VH.tsv
-rw-rw-r--   1 500      ideas     3479720 Mar 17 05:15 virus_genome_type.tsv
-rw-rw-r--   1 500      ideas    75863368 Mar 17 04:24 virushostdb.cds.faa.gz
-rw-rw-r--   1 500      ideas    114524400 Mar 17 04:23 virushostdb.cds.fna.gz
-rw-rw-r--   1 500      ideas     4129007 Apr  5 21:01 virushostdb.daily.tsv
-rw-r--r--   6 500      ideas    13620326 Jan 10  2019 virushostdb.environmental.cds.faa.gz
-rw-r--r--   6 500      ideas    24212765 Jan 10  2019 virushostdb.environmental.genomic.fna.gz
-rw-rw-r--   1 500      ideas    72524590 Mar 17 04:41 virushostdb.formatted.cds.faa.gz
-rw-rw-r--   1 500      ideas    110811247 Mar 17 04:58 virushostdb.formatted.cds.fna.gz
-rw-rw-r--   1 500      ideas    118614719 Mar 17 05:09 virushostdb.formatted.genomic.fna.gz
-rw-rw-r--   1 500      ideas    289470697 Mar 17 04:17 virushostdb.gbff.gz
-rw-rw-r--   1 500      ideas    117800732 Mar 17 04:17 virushostdb.genomic.fna.gz
-rw-rw-r--   1 500      ideas     4129007 Mar 17 04:14 virushostdb.tsv



 curl ftp://ftp.genome.jp/pub/db/virushostdb/
wget -N  ftp://ftp.genome.jp/pub/db/virushostdb/README
wget -N  ftp://ftp.genome.jp/pub/db/virushostdb/virushostdb.tsv
wget -N  ftp://ftp.genome.jp/pub/db/virushostdb/taxid2*
wget -N  ftp://ftp.genome.jp/pub/db/virushostdb/virus_genome_type.tsv
wget -N  ftp://ftp.genome.jp/pub/db/virushostdb/virushostdb.daily.tsv


virus_genome_type is not on the README

head -1 virus_genome_type.tsv | tr '\t' '\n' | grep -n .
1:virus_tax_id
2:genome_type
3:genome_composition
4:superkingdom
5:phylum
6:subphylum
7:class
8:order
9:suborder
10:family
11:subfamily
12:genus
13:subgenus
14:species
15:virus

### oh my, this looks promising!

cut -f2  virus_genome_type.tsv  | dist
  10443 0
   1091 1
      6 
      1 genome_type

Guessing  [0|1] is reference / completness 

cut -f3  virus_genome_type.tsv  | dist
   4088 dsDNA
   3373 ssRNA
   1746 ssDNA
   1420 OtherVirus
    454 dsRNA
    324 Satellite
     66 Viroid
     40 Retrovirus
     15 
      9 ssRNA-RT
      5 dsDNA-RT
      1 genome_composition

lools like at least part of the 'Baltimore classification' 
https://en.wikipedia.org/wiki/Baltimore_classification.


grep corona virushostdb.tsv | wc -l
238
grep corona virus_genome_type.tsv | wc -l
208
----------------------------------------------------
head -1 virushostdb.tsv | tr '\t' '\n' | grep -n .
1:virus tax id
2:virus name
3:virus lineage
4:refseq id
5:KEGG GENOME
6:KEGG DISEASE
7:DISEASE
8:host tax id
9:host name
10:host lineage
11:pmid
12:evidence
13:sample type
14:source organism

# perfect

for i in $(seq 14); do echo -ne "$i\t" ; cut -f $i virushostdb.tsv |sort -u |wc -l;done
1	11541
2	11541
3	3617
4	11597
5	341
6	89
7	89
8	3304
9	3275
10	2017
11	1067
12	16
13	9
14	83

wc -l < virushostdb.tsv # 14,679

Nothing is "not null unique" refseq_id comes closest

colums 1,8,14 are taxon 
when host is '1' NCBIroot and source_organism exists
and is not already a host for the virus, then a weaker association


head -1 virushostdb.tsv | tr '\tA-Z ' '\na-z_'  


--create table vh_sample_type(vh_samp_type text not null unique);
--insert into vh_sample_type ('Freshwater','Freshwater sediment','Marine','Marine sediment','Organismal','Other','Soil') 

    virus_tax_id int,
--    virus_name 
--    virus_lineage
    refseq_id_list ,            -- csv
--    kegg_genome ,
    kegg_disease_list text,     -- csv  (do we have a kegg-disease - mondo?) 
                                    -- https://www.genome.jp/kegg/files/disease2gene.xl
                                    -- https://www.genome.jp/kegg/files/disease2genome.xl
    disease_list text,          -- comma & semicolon?
    host_tax_id int,
--    host_name text
--    host_lineage_list text,     -- semicolon
    pmid_list int,              -- csv
    evidence_list text,         --csv   (Literature, NCBIVirus, RefSeq, UniPro)
    sample_type text,           -- ('Organismal','Other')
    source_organism int


--------------------------------------------------------------------

cut -f 1,8,14 virushostdb.tsv|tail -n+2|tr -s ' ' '\t'|sort -u  > virus_host_sample.tab

drop table if exists virus_host_sample;
create table virus_host_sample (
    virus_tax_id int not null references names(tax_id), 
    host_tax_id int default null references names(tax_id), 
    sample_tax_id int default null references names(tax_id)
);

.import Viral/data/VirusHostDB/virus_host_sample.tab virus_host_sample

-- think these are removable
select count(*) removable
    -- sample_tax_id 
from virus_host_sample s join virus_host_sample h on h.virus_tax_id = s.virus_tax_id
where s.host_tax_id == 1
  and s.sample_tax_id is not null
  and h.host_tax_id is not null
  and s.sample_tax_id == h.host_tax_id
  --and h.sample_tax_id is null
;  -- 55

select count(*) 
 from coronaviridae join virus_host_sample on virus_tax_id == virus_id;
-- 235


.once  Viral/corona_host.tab
select distinct virus_id, host_tax_id
 from coronaviridae 
    join virus_host_sample on virus_tax_id == virus_id
    join nodes on host_tax_id == nodes.tax_id
    where host_tax_id > 1
;
 

(aside/tangent:  READEME.host_corona_lattice)




-----------------






with grandchild(child_tax_id ) as 
(select distinct parent_tax_id 
      from coronaviridae 
      join virus_host_sample on virus_tax_id == virus_id
      join nodes on host_tax_id == nodes.tax_id
      where host_tax_id > 1
) 
select distinct parent_tax_id -- , name_txt, rank_hi
    from grandchild   
    join nodes on child_tax_id == nodes.tax_id
    join names on nodes.tax_id == names.tax_id
    join taxon_ranks on nodes.tax_id == taxon_ranks.tax_id
    group by parent_tax_id, name_txt --, taxon_ranks.rank_hi
    order by taxon_ranks.rank_hi 
    -- limit 100
;
  





---------------------------------------------------------

https://www.viprbrc.org/brc/home.spg?decorator=vipr


