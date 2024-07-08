--Creating Sequence for empty match_type_number

create or replace sequence cricket.land.match_no_generator start with 1001 increment by 1;

-- Create table in Clean layer


create or replace transient table cricket.clean.match_detail_clean as
select
    case 
    when info:match_type_number is not null then info:match_type_number::number
    else  cricket.land.match_no_generator.nextval
    end as match_type_number, 
    info:event.name::text as event_name,
    case
    when 
        info:event.match_number::text is not null then info:event.match_number::text
    when 
        info:event.stage::text is not null then info:event.stage::text
    else
        'NA'
    end as match_stage,   
    info:dates[0]::date as event_date,
    date_part('year',info:dates[0]::date) as event_year,
    date_part('month',info:dates[0]::date) as event_month,
    date_part('day',info:dates[0]::date) as event_day,
    info:match_type::text as match_type,
    info:season::text as season,
    info:team_type::text as team_type,
    case 
    when info:overs is not null then info:overs::text 
    else 'NA' 
    end as overs,
    case 
    when info:city is not null then info:city::text 
    else 'NA' 
    end as city,
    info:venue::text as venue, 
    info:gender::text as gender,
    info:teams[0]::text as first_team,
    info:teams[1]::text as second_team,
    -- case 
    --     when info:outcome.winner is not null then 'Result Declared'
    --     when info:outcome.result = 'tie' then 'Tie'
    --     when info:outcome.result = 'no result' then 'No Result'
    --     else info:outcome.result
    -- end as matach_result,
    case 
        when info:outcome.winner is not null then info:outcome.winner
        else 'NA'
    end as winner,   
    case
when info:outcome.by.runs is not null then concat('won by ', info:outcome.by.runs ,' Runs')
when info:outcome.by.wickets is not null then concat('won by ', info:outcome.by.wickets, ' Wickets')
else 
case when info:outcome.result::String = 'tie' then 'draw'
else info:outcome.result::String
end 
end as "Result" ,
    info:toss.winner::text as toss_winner,
    initcap(info:toss.decision::text) as toss_decision,
    -- metadata details tracker fields
    stg_file_name ,
    stg_file_row_number,
    stg_file_hashkey,
    stg_modified_ts
    from 
    cricket.raw.match_raw_tbl;
    

select * from cricket.clean.match_detail_clean
;

/*

select
info:match_type::String as match_type,
--info:season::String as season,
info:venue::String as venue,
info:dates::array as Date,
info:teams[0]::string as "First Team" ,
info:teams[1]::string as "Second Team",
case
when info:outcome.winner is not null then info:outcome.winner::string 
else 'N/A'
end as "Winner",
case
when info:outcome.by.runs is not null then concat('won by ', info:outcome.by.runs ,' Runs')
when info:outcome.by.wickets is not null then concat('won by ', info:outcome.by.wickets, ' Wickets')
else 
case when info:outcome.result::String = 'tie' then 'draw'
else info:outcome.result::String
end 
end as "Result" ,
--info:player_of_match = '["SM Whiteman"]'::String as "player of Match"
from cricket.raw.match_raw_tbl; 

*/

----------------------------------------------------------------------------------------------------------------
-- Player Details Table

/*
select 
case 
when info:match_type_number is not null then info:match_type_number::number
else  cricket.land.match_no_generator.nextval
end as match_type_number,
p.key::string as Team,
p_val.value::string as Players
from 
cricket.raw.match_raw_tbl ,
lateral flatten (input => info:players) p ,
lateral flatten (input => p.value) p_val
;

*/

create or replace transient table cricket.clean.player_details_clean as 
select
case 
when info:match_type_number is not null then info:match_type_number::number
else  cricket.land.match_no_generator.nextval
end as match_type_number,
p.key::string as Team,
p_val.value::string as Players ,
--metadata tracking field 
stg_file_name ,
stg_file_row_number,
stg_file_hashkey,
stg_modified_ts
from 
cricket.raw.match_raw_tbl ,
lateral flatten (input => info:players) p ,
lateral flatten (input => p.value) p_val
;


select * from cricket.clean.player_details_clean;


alter table cricket.clean.player_details_clean ;
desc table cricket.clean.player_details_clean;

-- Adding constraints to both the Tables
alter table cricket.clean.match_detail_clean add primary key (match_type_number) ;

alter table cricket.clean.player_details_clean modify column match_type_number set not null;
alter table cricket.clean.player_details_clean add primary key (match_type_number,Team,players);
alter table cricket.clean.player_details_clean add foreign key (match_type_number) references cricket.clean.match_detail_clean(match_type_number);

select get_ddl('table', 'cricket.clean.player_details_clean');
select get_ddl('table', 'cricket.clean.match_detail_clean');


/*

create or replace TRANSIENT TABLE PLAYER_DETAILS_CLEAN (
	MATCH_TYPE_NUMBER NUMBER(38,0) NOT NULL,
	TEAM VARCHAR(16777216) NOT NULL,
	PLAYERS VARCHAR(16777216) NOT NULL,
	STG_FILE_NAME VARCHAR(16777216),
	STG_FILE_ROW_NUMBER NUMBER(38,0),
	STG_FILE_HASHKEY VARCHAR(16777216),
	STG_MODIFIED_TS TIMESTAMP_NTZ(9),
	primary key (MATCH_TYPE_NUMBER, TEAM, PLAYERS),
	foreign key (MATCH_TYPE_NUMBER) references CRICKET.CLEAN.MATCH_DETAIL_CLEAN(MATCH_TYPE_NUMBER)
);


create or replace TRANSIENT TABLE MATCH_DETAIL_CLEAN (
	MATCH_TYPE_NUMBER NUMBER(38,0),
	EVENT_NAME VARCHAR(16777216),
	MATCH_STAGE VARCHAR(16777216),
	EVENT_DATE DATE,
	EVENT_YEAR NUMBER(4,0),
	EVENT_MONTH NUMBER(2,0),
	EVENT_DAY NUMBER(2,0),
	MATCH_TYPE VARCHAR(16777216),
	SEASON VARCHAR(16777216),
	TEAM_TYPE VARCHAR(16777216),
	OVERS VARCHAR(16777216),
	CITY VARCHAR(16777216),
	VENUE VARCHAR(16777216),
	GENDER VARCHAR(16777216),
	FIRST_TEAM VARCHAR(16777216),
	SECOND_TEAM VARCHAR(16777216),
	WINNER VARCHAR(16777216),
	"Result" VARCHAR(16777216),
	TOSS_WINNER VARCHAR(16777216),
	TOSS_DECISION VARCHAR(16777216),
	STG_FILE_NAME VARCHAR(16777216),
	STG_FILE_ROW_NUMBER NUMBER(38,0),
	STG_FILE_HASHKEY VARCHAR(16777216),
	STG_MODIFIED_TS TIMESTAMP_NTZ(9),
	primary key (MATCH_TYPE_NUMBER)
);

*/

-------------------------------------------------------------------------------

/*

select 
    m.info:match_type_number::int as match_type_number, 
    i.value:team::text as country,
    o.value:over::int+1 as over,
    d.value:bowler::text as bowler,
    d.value:batter::text as batter,
    d.value:non_striker::text as non_striker,
    d.value:runs.batter::text as runs,
    d.value:runs.extras::text as extras,
    d.value:runs.total::text as total,
    e.key::string as extra_type ,
    e.value::number as extra_runs ,
    w.value:player_out::text as player_out,
    w.value:kind::text as player_out_kind,
    po.value:name::string as player_out_fielders,
    m.stg_file_name ,
    m.stg_file_row_number,
    m.stg_file_hashkey,
    m.stg_modified_ts
from cricket.raw.match_raw_tbl m,
lateral flatten (input => m.innings) i,
lateral flatten (input => i.value:overs) o,
lateral flatten (input => o.value:deliveries) d,
lateral flatten (input => d.value:wickets, outer => True) w ,
lateral flatten (input => d.value:extras , outer => true) e,
lateral flatten (input => w.value:fielders, outer => True) po 
where match_type_number is null;

*/


-- create table delivery Cleaned

create or replace table cricket.clean.delivery_clean_tbl as
select 
    case 
    when info:match_type_number is not null then info:match_type_number::number
    else  cricket.land.match_no_generator.nextval
    end as match_type_number,
    i.value:team::text as country,
    o.value:over::int+1 as over,
    d.value:bowler::text as bowler,
    d.value:batter::text as batter,
    d.value:non_striker::text as non_striker,
    d.value:runs.batter::text as runs,
    d.value:runs.extras::text as extras,
    d.value:runs.total::text as total,
    e.key::string as extra_type ,
    e.value::number as extra_runs ,
    w.value:player_out::text as player_out,
    w.value:kind::text as player_out_kind,
    w.value:fielders::variant as player_out_fielders,
    -- po.value:name::string as player_out_fielders,
    m.stg_file_name ,
    m.stg_file_row_number,
    m.stg_file_hashkey,
    m.stg_modified_ts
from cricket.raw.match_raw_tbl m,
lateral flatten (input => m.innings) i,
lateral flatten (input => i.value:overs) o,
lateral flatten (input => o.value:deliveries) d,
lateral flatten (input => d.value:wickets, outer => True) w ,
lateral flatten (input => d.value:extras , outer => true) e
-- ,lateral flatten (input => w.value:fielders, outer => True) po 
;

select * from cricket.raw.match_raw_tbl where  info:match_type_number::number= 4686;


select * from cricket.clean.delivery_clean_tbl where match_type_number is null;

select * from cricket.clean.delivery_clean_tbl where PLAYER_OUT_KIND = 'run out';

/*

select 
d.*,
po.*
from 
cricket.raw.match_raw_tbl m,
lateral flatten (input => m.innings) i,
lateral flatten (input => i.value:overs) o,
lateral flatten (input => o.value:deliveries) d,
lateral flatten (input => d.value:wickets, outer => True) w ,
lateral flatten (input => d.value:extras , outer => true) e,
lateral flatten (input => w.value:fielders, outer => True) po  
where w.value:kind::text = 'run out';




select 
    case 
    when info:match_type_number is not null then info:match_type_number::number
    else  cricket.land.match_no_generator.nextval
    end as match_type_number,
    i.value:team::text as country,
    o.value:over::int+1 as over,
    d.value:bowler::text as bowler,
    d.value:batter::text as batter,
    d.value:non_striker::text as non_striker,
    d.value:runs.batter::text as runs,
    d.value:runs.extras::text as extras,
    d.value:runs.total::text as total,
    e.key::string as extra_type ,
    e.value::number as extra_runs ,
    w.value:player_out::text as player_out,
    w.value:kind::text as player_out_kind,
    w.value:fielders::variant as player_out_fielders,
    w.*,
    -- po.value:name::string as player_out_fielders,
    m.stg_file_name ,
    m.stg_file_row_number,
    m.stg_file_hashkey,
    m.stg_modified_ts
from cricket.raw.match_raw_tbl m,
lateral flatten (input => m.innings) i,
lateral flatten (input => i.value:overs) o,
lateral flatten (input => o.value:deliveries) d,
lateral flatten (input => d.value:wickets, outer => True) w ,
lateral flatten (input => d.value:extras , outer => true) e
-- ,lateral flatten (input => w.value:fielders, outer => True) po  
where w.value:kind::text = 'run out';

*/



alter table cricket.clean.delivery_clean_tbl
modify column match_type_number set not null;

alter table cricket.clean.delivery_clean_tbl
modify column country set not null;

alter table cricket.clean.delivery_clean_tbl
modify column over set not null;

alter table cricket.clean.delivery_clean_tbl
modify column bowler set not null;

alter table cricket.clean.delivery_clean_tbl
modify column batter set not null;

alter table cricket.clean.delivery_clean_tbl
modify column non_striker set not null;

-- fk relationship
alter table cricket.clean.delivery_clean_tbl
add constraint fk_delivery_match_id
foreign key (match_type_number)
references cricket.clean.match_detail_clean (match_type_number);


select get_ddl('table', 'cricket.clean.delivery_clean_tbl') ;


------------------------------------------------------------------------------------------------
