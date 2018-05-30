# Taxonomy

If we are going to have 'all the organisms' we should tighten up our
representation.

### Source
ftp://ftp.ncbi.nih.gov/pub/taxonomy/


wget --timestamping ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz
  
tar -tvf taxdump.tar.gz 
-rw-r--r-- tm/tm      16788608 2018-05-11 12:20 citations.dmp
-rw-r--r-- tm/tm       3568149 2018-05-11 12:20 delnodes.dmp
-rw-r--r-- tm/tm           442 2018-05-11 12:20 division.dmp
-rw-r--r-- tm/tm         15188 2018-05-11 12:20 gc.prt
-rw-r--r-- tm/tm          4575 2018-05-11 12:20 gencode.dmp
-rw-r--r-- tm/tm        919149 2018-05-11 12:20 merged.dmp
-rw-r--r-- tm/tm     154543539 2018-05-11 12:20 names.dmp
-rw-r--r-- tm/tm     119664361 2018-05-11 12:20 nodes.dmp
-rw-rw---- domrach/tm     2652 2006-06-13 12:04 readme.txt

Will start with ID, name and structure

limit divisions to non-micro fauna (for now)

0	|	BCT	|	Bacteria
1	|	INV	|	Invertebrates
-------------------------------------

2	|	MAM	|	Mammals
5	|	PRI	|	Primates
6	|	ROD	|	Rodents
8	|	UNA	|	Unassigned      (root)
10	|	VRT	|	Vertebrates

------------------------------------

4	|	PLN	|	Plants and Fungi
7	|	SYN	|	Synthetic and Chimeric
3	|	PHG	|	Phages
9	|	VRL	|	Viruses
11	|	ENV	|	Environmental samples



######

gawk -F"\t" -v"OFS='\t'" 'match("12568",$9)||$9=="10"{print $1,$3,$5,$9}' nodes.dmp > txid_parent_rank_div.tab

wc -l < txid_parent_rank_div.tab 
678,112

cut -f4 txid_parent_rank_div.tab| sort | uniq -c | sort -nr | head 
 591954 1
  75380 10
   5708 2
   4092 6
    916 5
     62 8

That is a lot of Invertebrates...
I know we need fly and maybe worm 
but I going to pass on them this first pass


gawk -F"\t" -v"OFS=\t" 'match("2568",$9)||$9=="10"{print $1,$3,$5,$9}' nodes.dmp > txid_parent_rank_div.tab

wc -l < txid_parent_rank_div.tab 
86158

# what divisions?
cut -f4 txid_parent_rank_div.tab| sort | uniq -c | sort -nr | head

  75380 10  (Vertebrates)
   5708 2	(Mammals)
   4092 6	(Rodents)
    916 5	(Primates)
     62 8	(Unassigned)

# what ranks?
cut -f3 txid_parent_rank_div.tab| sort | uniq -c | sort -nr | head 
  66614 species
   9482 genus
   7268 subspecies
   1038 family
    735 no rank
    488 subfamily
    157 order
    103 subgenus
     86 suborder
     73 tribe

# Do ranks form a hirearchy?
awk -F'\t' '{a[$1]=$3;b[NR]=$3;c[NR]=$2}END{for(i=1;i<=NR;i++)print b[i] "\t" a[c[i]]}'\
  txid_parent_rank_div.tab | grep -v "no rank" | tsort
 ... 
 -: input contains a loop:
 ...

ranks appear have cycles. 
(even when we omit the "no rank" rank)
(even when we limit to ranks per division)
divisions root into: class or order which is okay

But there is no topological sorting of ranks, which is unfortunate.

Check if all individual paths from leaf to root are cycle free

awk -F'\t' '{a[$1]=$3;b[$1]=$2;c[NR]=$1}\
	END{for(i=1;i<=NR;i++){n=c[i];p=a[n];\
		while(n in b){n=b[n];p=p"\t"a[n]}d[p]++}\
		for(p in d)print p "\t" d[p]}'  txid_parent_rank_div.tab

... no, (memory grows without bound)
but that is not suprising since there are cycles.

Check if any individual path from leaf to root is cycle free

awk -F'\t' '{a[$1]=$3;b[$1]=$2;c[NR]=$1}\
	END{for(i=1;i<=NR;i++){n=c[i];p=a[n];\
	while(n in b){n=b[n];if(match(p,"\t" a[n])){p=p"\tcycle "a[n];break}
		else{p=p"\t"a[n]}}d[p]++}for(p in d)print p "\t" d[p]}'  \
txid_parent_rank_div.tab > all_path

grep -v 'cycle' all_path 
subphylum		1

well at least it is not absoultly nothing

I can try by division

grep -v cycle *_path	1

Mammals_path:	80450
Mammals_path:class		1

Primates_path:	85242
Primates_path:order		1

Rodents_path:	82066
Rodents_path:order		1

Vertebrates_path:	10778
Vertebrates_path:subphylum	

just the empty or root-ish nodes

-----------------------------------------------------------------------------
try treating every non-rank node as distinct from every other non-rank node
(like blank nodes)

awk -F'\t' '$4==$4{a[$1]=$3=="no rank"?"_"$1"_":$3;b[$1]=$2;c[NR]=$1}\
	END{for(i=1;i<=NR;i++){n=c[i];p="\t"a[n];\
	while(n in b){n=b[n];if((a[n]!="")&& match(p,"\t" a[n])){p=p"\tcycle "a[n];break}\
	else{p=p"\t"a[n]}}d[p]++}for(p in d)print p "\t" d[p]}'  \
	txid_parent_rank_div.tab > all_path
 
grep cycle all_path 
	species	_12908_	_1_	cycle _1_	5
	_28384_	_1_	cycle _1_	1
	_12908_	_1_	cycle _1_	1
	_131567_	_1_	cycle _1_	1
	_1_	cycle _1_	1
	_1515699_	_12908_	_1_	cycle _1_	1
	species	_684672_	_12908_	_1_	cycle _1_	1
	_1306155_	_12908_	_1_	cycle _1_	1
	_684672_	_12908_	_1_	cycle _1_	1
	species	_704107_	_12908_	_1_	cycle _1_	2
	species	_1515699_	_12908_	_1_	cycle _1_	28
	_164974_	_28384_	_1_	cycle _1_	1
	_2671_	_28384_	_1_	cycle _1_	1
	_2387_	_28384_	_1_	cycle _1_	1
	species	_2387_	_28384_	_1_	cycle _1_	11
	_704107_	_12908_	_1_	cycle _1_	1
	species	_1306155_	_12908_	_1_	cycle _1_	2
	species	_28384_	_1_	cycle _1_	2

This is promising! all these cycles are just the root pointing to itself _1_<-> _1_


There are over 2,050 distinct paths in all_paths. 
collapsing all blank nodes brings it down to:

sed 's/[0-9_]*//g;s/\t\t*/\t/g' all_path |sort -u | wc -l
482

under 500 distinct paths

these paths will further collapse with shorter subpaths into longer paths

sed 's/[0-9_]*//g;s/\t\t*/\t/g' all_path |sort -u | awk '{print length, $0}' | sort -n | cut -d" " -f2- > all_distinct_path

awk '{a[NR]=$0}END{for(i=1;i<NR;i++){for(j=i+1;j<=NR;j++){x=1;if(match(a[j],a[i])){x=0;break}}if(x)print a[i]}}' all_distinct_path > all_distinct_longest_path 
 
wc -l < all_distinct_longest_path
175

# find the explicit partial orders
awk '{for(i=2;i<=NF;i++)a[$(i-1)"\t"$i]++}END{for(x in a)print x}' all_distinct_longest_path | sort -u > rank_partial_order

wc -l < rank_partial_order 
68  (flavors of edges between ranks)

Are there cycles?
awk '{for(i=2;i<=NF;i++)a[$(i-1)"\t"$i]++}END{for(x in a)print x}' all_distinct_longest_path | tsort

subspecies
species
cycle
group
subgenus
genus
tribe
subfamily
family
superfamily
parvorder
infraorder
suborder
order
superorder
infraclass
subclass
class
superclass
subphylum

# this is excellent, just what I hoped for

20 ranks 19+18+17...+2+1

awk 'BEGIN{for(i=1;i<20;i++)x+=i;print x}'
190

awk 'BEGIN{print"{"}{a[NR]=$1}\
	END{for(i=1;i<length(a);i++){for(j=i+1;j<=length(a);j++){\
	print "<" a[i] "> <part_of> <" a[j] "> ."}}}' \
ordered_rank.list > rank_transitive_closure.nt


68 of 190 possible? edges are represented in the data
many of these omissions make sense, not everything includes 'subspecies'
if you are in the Rodent division do not go above 'order'... etc 
but it would be nice to be positive no two ranks are equivlent. 




# check leaf and root
awk '{print $1, $NF}' all_distinct_longest_path | sort -u
species cycle
species subphylum
subspecies subphylum

A few species are "disconnected" 
but most are attached to some branches of a pylogenetic tree


favoring JB's model here slide 25:
https://www.slideserve.com/axel/names-ranks-clades-and-taxonomy-ontologies


Scouring
https://www.ncbi.nlm.nih.gov/books/NBK21100/
for hints as well.


----------------------------------------------------------------------------
names

cut -f7 names.dmp | sort | uniq -c | sort -nr
1755607 scientific name
 417924 authority
 170546 synonym
 117626 type material
  37609 includes
  36622 misspelling
  28354 genbank common name
  25932 equivalent name
  14266 common name
   2984 genbank synonym
   1384 misnomer
   1170 acronym
    693 in-part
    486 genbank acronym
    297 anamorph
    227 blast name
    179 teleomorph
     95 genbank anamorph



-----------------------------------------------------------------------------
I think it is worth trying to build a NCBI taxonomy ontology-like-resource 
then dropping everything but txids from the other ingests/ontologies.

want 
txid, 
	label,
	common_name, 
	rank,
 	division,
	citation (pubmed|medline),
	nearest_ancestor_rank_txid  (skipping no-rank txids) 

