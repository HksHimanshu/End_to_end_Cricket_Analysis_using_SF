use role sysadmin;
grant usage on warehouse compute_wh to role sysadmin;

create database cricket;

create schema land;
create schema raw;
create schema clean;
create schema consumption;


show schemas in database cricket;


-- json file format
create or replace file format cricket.land.my_json_format
 type = json
 null_if = ('\\n', 'null', '')
    strip_outer_array = true
    comment = 'Json File Format with outer stip array flag true'; 

-- creating an internal stage
create or replace stage cricket.land.my_stg; 

-- lets list the internal stage
list @my_stg;

-- check if data is being loaded or not
list @my_stg/cricket/;

-- quick check if data is coming correctly or not
select 
        t.$1:meta::variant as meta, 
        t.$1:info::variant as info, 
        t.$1:innings::array as innings, 
        metadata$filename as file_name,
        metadata$file_row_number int,
        metadata$file_content_key text,
        metadata$file_last_modified stg_modified_ts
     from @my_stg/cricket/ (file_format => 'my_json_format') t;


select * from @my_stg/cricket/ (file_format => 'my_json_format');



-- create a table inside the raw layer
create or replace transient table cricket.raw.match_raw_tbl (
    meta object not null,
    info variant not null,
    innings ARRAY not null,
    stg_file_name text not null,
    stg_file_row_number int not null,
    stg_file_hashkey text not null,
    stg_modified_ts timestamp not null
)
comment = 'This is raw table to store all the json data file with root elements extracted'
;

-- loading stage JSON files into the RAW table with extra metradata columns to keep track of the history.

copy into cricket.raw.match_raw_tbl from 
    (
    select 
        t.$1:meta::object as meta, 
        t.$1:info::variant as info, 
        t.$1:innings::array as innings, 
        metadata$filename,
        metadata$file_row_number,
        metadata$file_content_key,
        metadata$file_last_modified
    from @cricket.land.my_stg/cricket/ (file_format => 'cricket.land.my_json_format') t
    )
    on_error = continue;

select count(*) from cricket.raw.match_raw_tbl; --200

-- top 10 records.
select * from cricket.raw.match_raw_tbl 
where lower(info:match_type::string) in ('test' ,'mdm');


