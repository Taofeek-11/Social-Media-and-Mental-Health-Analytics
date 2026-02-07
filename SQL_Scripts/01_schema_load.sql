/* ============================================================
   01_schema_load.sql
   social media exposure and mental health analytics
   purpose:
     - create schema and raw landing table
     - load csv into raw table (rerunnable)
   notes:
     - requires: local_infile enabled (client + server)
     - windows csv often uses \r\n line endings
   ============================================================ */

create schema if not exists health_analysis;
use health_analysis;

drop table if exists raw_data;

create table raw_data (
    respondent_id bigint unsigned not null auto_increment,
    age int null,
    gender varchar(20) null,
    relationship_status varchar(30) null,
    occupation_status varchar(30) null,
    affiliated_organization varchar(30) null,
    sm_usage varchar(10) null,
    platforms varchar(200) null,
    time_spent varchar(100) null,
    purposeless_usage tinyint null,
    distraction tinyint null,
    restless_if_not_used tinyint null,
    ease_of_distraction tinyint null,
    bothered_by_worries tinyint null,
    difficulty_in_concentration tinyint null,
    comparison_of_self_to_peers tinyint null,
    feelings_about_above_comparison tinyint null,
    validation_sought_from_sm tinyint null,
    feeling_of_depression tinyint null,
    fluctuation_of_interest tinyint null,
    sleep_issues tinyint null,
    primary key (respondent_id),
    index idx_age (age),
    index idx_relationship_status (relationship_status),
    index idx_time_spent (time_spent)
);

-- rerunnable load: clears table and resets auto_increment
truncate table raw_data;

load data local infile 'c:\\users\\user\\documents\\datavisualizationproject\\tableau\\raw_data.csv'
into table raw_data
fields terminated by ','
enclosed by '"'
lines terminated by '\r\n'
ignore 1 rows
(
    age,
    gender,
    relationship_status,
    occupation_status,
    affiliated_organization,
    sm_usage,
    platforms,
    time_spent,
    purposeless_usage,
    distraction,
    restless_if_not_used,
    ease_of_distraction,
    bothered_by_worries,
    difficulty_in_concentration,
    comparison_of_self_to_peers,
    feelings_about_above_comparison,
    validation_sought_from_sm,
    feeling_of_depression,
    fluctuation_of_interest,
    sleep_issues
);

select
  count(*) as n_rows,
  min(age) as min_age,
  max(age) as max_age
from raw_data;
