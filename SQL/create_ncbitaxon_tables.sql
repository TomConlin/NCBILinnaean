-- create_ncbitaxon_tables.sql
-- column names (derived) from ncbi taxon's readme 
-- 
.timer on
.mode tabs

.print "load primary names"
drop table if exists names;
create table names (
	tax_id int not null primary key,  
	name_txt text,
	name_unique	text, -- not unique,
	name_class text
);
.import data/names.tab names

-- duplicate names table
.print "load secondary names"
drop table if exists synonyms;
create table synonyms (
	tax_id int not null references names(tax_id),
	name_txt text,
	name_unique	text,
	name_class text
);
.import data/synonyms.tab synonyms

.print "load GB Divisions"
drop table if exists division;
create table division (
	div_id smallint not null primary key,
	div_cde text not null,	
	div_name text not null,	
	div_comments
);
.import data/division.tab division

.print "load GB genetic codes"
drop table if exists gencode;
create table gencode (
	gc_id smallint not null primary key,	
	gc_abbrev text not null,
	gc_name	 text not null,
    gc_cde	 text not null,
    gc_starts text not null
);
.import data/gencode.tab gencode

.print "load taxon partial order (edges)"
drop table if exists nodes;
create table nodes (
    tax_id int not null references names(tax_id),			
    parent_tax_id int not null references names(tax_id),
    rank text,			
    embl_code text,
    div_id smallint not null references division(div_id),
    gc_id smallint not null references gencode(gc_id),		       
    mt_gc_id smallint not null references gencode(gc_id)
);
.import data/nodes.tab nodes

.print "load taxon pubs"
drop table if exists citations;
create table citations (
	cit_id int not null,  -- not unique
	cit_key text not null,
    medline_id text,
	pubmed_id text,
	cit_url text,			
	taxid_list text  -- list of node ids separated by a single space
);
.import data/citations.tab citations


-- My take on an ordering scheme
.print "load rank order labels"
drop table if exists rank_order;
create table rank_order(
	ro_order smallint NOT NULL unique,
	ro_rank varchar(30) not null unique
);

drop table if exists rank_label;
create table rank_label(
	rank varchar(30) NOT NULL unique,
	label varchar(30) not null unique
);

.import translationtable/rank_order.tab rank_order
.import translationtable/rank_label.tab rank_label


VACUUM;

.timer off

