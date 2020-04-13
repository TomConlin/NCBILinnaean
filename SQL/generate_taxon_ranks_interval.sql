/*  
*  generate_taxon_ranks_interval.sql

    Logicaly, many taxon do not have a now obsolete Linnean rank.   
    however if their nearest ancestors and decendents are assigned a rank
    we can infer the bracket wuthin which the omitted rank is expected to fall.

    Root and Leaves taxon should have one sided brckets, 
    leaves have no 'lo' side and root has no 'hi' side

    note: this also means we should expect far fewer 'lo' ranks infered 
    not only because they represent actual currently existing species 
    but because decendents do not exist yet.
*
*/


drop table if exists taxon_leafs;
create table taxon_leafs(leaf_id int not null unique references names(tax_id));
insert into taxon_leafs 
    select tax_id from names where tax_id not in (select parent_tax_id from nodes);

drop table if exists taxon_ranks;
create table taxon_ranks(
    tax_id int not null unique references names(tax_id),
    rank_hi smallint default NULL,
    rank_lo smallint default NULL
);

drop table if exists txrk_lo;
create table txrk_lo(
    tax_id int not null references names(tax_id),
    rank_lo smallint default NULL
);
drop table if exists txrk_hi;
create table txrk_hi(
    tax_id int not null references names(tax_id),
    rank_hi smallint default NULL
);

-- lock in the explicit ranks
insert into taxon_ranks 
select tax_id, ro_order, ro_order 
    from nodes 
    join rank_label on nodes.rank == rank_label.rank
    join rank_order on rank_label.label == ro_rank
;
-- omit the lower range of leaf intervals 
update taxon_ranks set rank_lo = NULL 
    where (select 1 from taxon_leafs where tax_id == leaf_id);


-- iterativly find the best deepest ranked direct child's upper rank 
-- note by construction;  none of this set could be leafs
WITH RECURSIVE lorank(node_id, rank_lo) AS
    (SELECT tax_id, rank_hi from taxon_ranks
	 UNION
	 SELECT parent.tax_id, rank_lo
	  FROM lorank 
        join nodes on node_id == nodes.tax_id
		join nodes as parent on parent.tax_id == nodes.parent_tax_id
    where parent.rank == "no rank" 
     and  parent.tax_id not in (select tax_id from taxon_ranks)
    )
insert into txrk_lo(tax_id, rank_lo) 
select node_id, max(rank_lo) 
  from lorank 
   where node_id not in (select tax_id from taxon_ranks)
    group by 1
;

-------------------------------------------------------------
/*
select nodes.tax_id, count(rank_lo) 
 from txrk_lo join nodes on taxon_ranks.tax_id == parent_tax_id
 where nodes.rank == "no rank" 
 group by 1 having count(rank_lo) > 1
;
*/

-- iterativly find the best shallowest ranked direct parent's lower rank
-- note although these taxon could be leaves we are not setting a lower range
WITH RECURSIVE hirank(node_id, rank_hi) AS
    (SELECT tax_id, rank_lo from taxon_ranks 
	 UNION
	 SELECT tax_id, rank_hi
	  FROM hirank 
        join nodes on node_id == nodes.parent_tax_id
    where rank == "no rank" 
     and nodes.tax_id not in (select tax_id from taxon_ranks where rank_hi is null)
    )
insert into txrk_hi(tax_id, rank_hi) 
select node_id, min(rank_hi) 
  from hirank 
   where node_id not in (select tax_id from taxon_ranks)
    group by 1
;
--------------------------------------------------------


-- select count(*)bz from txrk_hi where tax_id in(select tax_id from taxon_ranks); -- 0
-- select count(*)bz from txrk_lo where tax_id in(select tax_id from taxon_ranks); -- 0
--
/*
select count(*) -- 48,948
    -- txrk_hi.tax_id, rank_hi, rank_lo
 from txrk_hi join txrk_lo on txrk_hi.tax_id == txrk_lo.tax_id 
;
-- are there any in perfect agreement (should not have been "no rank")? yes but only 8
select count(*) -- 8 -- 
 from txrk_hi join txrk_lo on txrk_hi.tax_id == txrk_lo.tax_id 
 where rank_lo is NULL or (rank_hi == rank_lo)   
;

select distinct name_txt, ro_rank 
 from txrk_hi join txrk_lo on txrk_hi.tax_id == txrk_lo.tax_id 
 join names on names.tax_id == txrk_hi.tax_id
 join rank_order on ro_order == rank_hi
 where rank_lo is NULL or (rank_hi == rank_lo) 
; 
-- 2 virus & 6 env samples as "Species"
--
*/

-- enter the two sided intervals
insert into taxon_ranks 
 select txrk_hi.tax_id, rank_hi, rank_lo
 from txrk_hi join txrk_lo on txrk_hi.tax_id == txrk_lo.tax_id 
;

--
/*
select count(*) from taxon_ranks join taxon_leafs on tax_id == leaf_id
 where rank_lo is not NULL;
 -- there are zero

-- omit the lower range of leaf intervals 
update taxon_ranks set rank_lo = NULL 
    where (select 1 from taxon_leafs where tax_id == leaf_id);
*/

delete from txrk_hi where tax_id in (select tax_id from taxon_ranks);
delete from txrk_lo where tax_id in (select tax_id from taxon_ranks);

-- select count(*) from txrk_hi; -- 218,535
-- select count(*) from txrk_lo; -- 33
/*
select distinct name_txt, ro_rank 
 from txrk_lo join names on names.tax_id == txrk_lo.tax_id
 join rank_order on ro_order == rank_lo  
;

not alot to worry about:
     vectors,plasimds,insertions,transposons,synthetics,samples,metagenomes ...

a few to keep an eye on:
    root	Subspecies  --> set as higest tank

    Otophysi	Order_(biology)#superorder
    Anotophysi	Order_(biology
    unclassified Saintpaulia	Species
    core Knesebeckia	Species
    Knesebeckia group I	Species
    Knesebeckia group II	Species
    Knesebeckia group III	Species

*/

update txrk_lo set rank_lo = (select min(ro_order) from rank_order) where tax_id = 1;


-- double check there are no  new taxon already in taxon_rank
-- select count(*)bezero from txrk_hi where tax_id in(select tax_id from taxon_ranks);
-- select count(*)bezero from txrk_lo where tax_id in(select tax_id from taxon_ranks);

insert into taxon_ranks(tax_id, rank_hi) select * from txrk_hi;
insert into taxon_ranks(tax_id, rank_lo) select * from txrk_lo;

/*
select count(*) from names;         -- 2237473
select count(*) from taxon_ranks;   -- 2237064
--                                         409  missing 

select nodes.* from nodes where tax_id not in (select tax_id from taxon_ranks);
-- half dozen are "no rank", 'series'

select count(distinct nodes.parent_tax_id) 
  from nodes where tax_id not in (select tax_id from taxon_ranks);

-- many have the same (53) parents

interesting, but not likely important just now.
leaving the stragglers and new types of ranks for now

*/

-- clean up
drop table if exists txrk_lo; 
drop table if exists txrk_hi;
drop table if exists taxon_leafs;  

vaccum;

