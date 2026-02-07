/*-------------------------------
layer 2: cleaned analytical view
--------------------------------
what this view does:
- standardizes gender to: female, male, other (lowercase)
- standardizes relationship_status (lowercase, trimmed)
- derives age_group
- standardizes time_spent (lowercase, trimmed)
- encodes time_spent into time_on_sm ordinal scale for analysis
*/

create or replace view v_clean_data as
select
    respondent_id,                         
    age,
    case
        when lower(trim(gender)) in ('female','f') then 'female'
        when lower(trim(gender)) in ('male','m') then 'male'
        when gender is null or trim(gender) = '' then null
        else 'other'
    end as gender,
    nullif(lower(trim(relationship_status)), '') as relationship_status,
    case
        when age is null then null
        when age between 13 and 22 then 'adolescents'
        when age between 23 and 32 then 'young adults'
        when age between 33 and 42 then 'early adults'
        when age between 43 and 52 then 'middle-aged adults'
        else 'senior adults'
    end as age_group,
    nullif(lower(trim(time_spent)), '') as time_spent,
    case
        when lower(trim(time_spent)) = 'more than 5 hours' then 6
        when lower(trim(time_spent)) = 'between 4 and 5 hours' then 5
        when lower(trim(time_spent)) = 'between 3 and 4 hours' then 4
        when lower(trim(time_spent)) = 'between 2 and 3 hours' then 3
        when lower(trim(time_spent)) = 'between 1 and 2 hours' then 2
        when lower(trim(time_spent)) = 'less than an hour' then 1
        else null
    end as time_on_sm,
    purposeless_usage,
    distraction,
    ease_of_distraction,
    difficulty_in_concentration,
    restless_if_not_used,
    bothered_by_worries,
    feeling_of_depression,
    feelings_about_above_comparison,
    sleep_issues,
    comparison_of_self_to_peers,
    validation_sought_from_sm,
    nullif(lower(trim(platforms)), '') as platforms
from raw_data;


/*---------------------------------------
layer 2b: composite indices per respondent
-----------------------------------------
- creates null-safe composite indices for downstream aggregation
*/

create or replace view v_indices as
select
    respondent_id,
    age,
    age_group,
    gender,
    relationship_status,
    time_spent,
    time_on_sm,
    platforms,

    (
        coalesce(purposeless_usage, 0) +
        coalesce(distraction, 0) +
        coalesce(ease_of_distraction, 0) +
        coalesce(difficulty_in_concentration, 0)
    ) / nullif(
        (purposeless_usage is not null) +
        (distraction is not null) +
        (ease_of_distraction is not null) +
        (difficulty_in_concentration is not null),
        0
    ) as adhd_idx,

    (
        coalesce(restless_if_not_used, 0) +
        coalesce(bothered_by_worries, 0)
    ) / nullif(
        (restless_if_not_used is not null) +
        (bothered_by_worries is not null),
        0
    ) as anxiety_idx,

    (
        coalesce(feeling_of_depression, 0) +
        coalesce(feelings_about_above_comparison, 0) +
        coalesce(sleep_issues, 0)
    ) / nullif(
        (feeling_of_depression is not null) +
        (feelings_about_above_comparison is not null) +
        (sleep_issues is not null),
        0
    ) as depression_idx,

    (
        coalesce(comparison_of_self_to_peers, 0) +
        coalesce(validation_sought_from_sm, 0)
    ) / nullif(
        (comparison_of_self_to_peers is not null) +
        (validation_sought_from_sm is not null),
        0
    ) as self_esteem_idx
from v_clean_data;


/*========================================================
layer 3: analysis sections (queries only)
========================================================*/

/* section a: age distribution */
with total as (select count(*) as total_count from v_clean_data)
select
    age_group,
    count(*) as frequency,
    round(count(*) * 100.0 / total.total_count, 2) as percent
from v_clean_data
cross join total
group by age_group, total.total_count;

/* section b: gender distribution */
with total as (select count(*) as total_count from v_clean_data)
select
    gender,
    count(*) as frequency,
    round(count(*) * 100.0 / total.total_count, 2) as percent
from v_clean_data
cross join total
group by gender, total.total_count;

/* section c: relationship status distribution */
with total as (select count(*) as total_count from v_clean_data)
select
    relationship_status,
    count(*) as frequency,
    round(count(*) * 100.0 / total.total_count, 2) as percent
from v_clean_data
cross join total
group by relationship_status, total.total_count;

/* section d: platform usage (long format for tableau) */
select platform, n,
       round(n * 100.0 / total_n, 2) as percent
from (
    select 'youtube' as platform,
           sum(platforms like '%youtube%') as n,
           count(*) as total_n
    from v_clean_data
    union all
    select 'facebook', sum(platforms like '%facebook%'), count(*) from v_clean_data
    union all
    select 'instagram', sum(platforms like '%instagram%'), count(*) from v_clean_data
    union all
    select 'discord', sum(platforms like '%discord%'), count(*) from v_clean_data
    union all
    select 'snapchat', sum(platforms like '%snapchat%'), count(*) from v_clean_data
    union all
    select 'pinterest', sum(platforms like '%pinterest%'), count(*) from v_clean_data
    union all
    select 'twitter', sum(platforms like '%twitter%'), count(*) from v_clean_data
    union all
    select 'reddit', sum(platforms like '%reddit%'), count(*) from v_clean_data
    union all
    select 'tiktok', sum(platforms like '%tiktok%'), count(*) from v_clean_data
) t
order by percent desc;

/* section e: modal time spent by relationship status */
with counts as (
    select relationship_status, time_spent, count(*) as cnt
    from v_clean_data
    group by relationship_status, time_spent
),
ranked as (
    select relationship_status, time_spent,
           row_number() over(partition by relationship_status order by cnt desc) as rn
    from counts
)
select relationship_status, time_spent as most_common_time_online
from ranked
where rn = 1;

/* section f: modal time spent by age group */
with counts as (
    select age_group, time_spent, count(*) as cnt
    from v_clean_data
    group by age_group, time_spent
),
ranked as (
    select age_group, time_spent,
           row_number() over(partition by age_group order by cnt desc) as rn
    from counts
)
select age_group, time_spent as most_common_time_online
from ranked
where rn = 1;

/* section g: age vs time spent correlation (pearson) */
with stats as (
    select
        count(*) as n,
        sum(age) as sum_x,
        sum(time_on_sm) as sum_y,
        sum(age * time_on_sm) as sum_xy,
        sum(age * age) as sum_x2,
        sum(time_on_sm * time_on_sm) as sum_y2
    from v_clean_data
    where age is not null and time_on_sm is not null
)
select
    case
        when (n * sum_x2 - sum_x * sum_x) = 0
          or (n * sum_y2 - sum_y * sum_y) = 0
        then null
        else (1.0 * (n * sum_xy - sum_x * sum_y)) /
             sqrt((n * sum_x2 - sum_x * sum_x) * (n * sum_y2 - sum_y * sum_y))
    end as time_age_correlation
from stats;

/* section h: time spent vs composite indices */
select
    time_spent,
    avg(adhd_idx) as adhd_mean,
    avg(anxiety_idx) as anxiety_mean,
    avg(depression_idx) as depression_mean,
    avg(self_esteem_idx) as self_esteem_mean
from v_indices
group by time_spent
order by min(time_on_sm);

/* section i: age group vs composite indices */
select
    age_group,
    avg(adhd_idx) as adhd_mean,
    avg(anxiety_idx) as anxiety_mean,
    avg(depression_idx) as depression_mean,
    avg(self_esteem_idx) as self_esteem_mean
from v_indices
group by age_group;

/* section j: relationship status vs composite indices */
select
    relationship_status,
    avg(adhd_idx) as adhd_mean,
    avg(anxiety_idx) as anxiety_mean,
    avg(depression_idx) as depression_mean,
    avg(self_esteem_idx) as self_esteem_mean
from v_indices
group by relationship_status;
