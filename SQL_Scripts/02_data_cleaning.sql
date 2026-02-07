/* ============================================================
   02_data_cleaning.sql
   purpose:
     - standardize raw survey fields for analysis and tableau
     - preserve raw_data; create clean layer as a view
   design:
     - clean_data_v: typed + standardized fields
     - includes derived age_group and time_spent_order
   ============================================================ */

use health_analysis;

drop view if exists clean_data_v;

create view clean_data_v as
with base as (
    select
        respondent_id,

        -- age: numeric + sanity bounds
        case
            when age is null then null
            when age < 0 or age > 120 then null
            else age
        end as age,

        -- standardize text fields: trim + lower
        nullif(lower(trim(gender)), '') as gender_raw,
        nullif(lower(trim(relationship_status)), '') as relationship_status_raw,
        nullif(lower(trim(occupation_status)), '') as occupation_status_raw,
        nullif(lower(trim(affiliated_organization)), '') as affiliated_organization_raw,
        nullif(lower(trim(sm_usage)), '') as sm_usage_raw,
        nullif(lower(trim(platforms)), '') as platforms_raw,
        nullif(lower(trim(time_spent)), '') as time_spent_raw,

        -- likert items: keep as-is, but enforce plausible range (1–5); else null
        case when purposeless_usage between 1 and 5 then purposeless_usage end as purposeless_usage,
        case when distraction between 1 and 5 then distraction end as distraction,
        case when restless_if_not_used between 1 and 5 then restless_if_not_used end as restless_if_not_used,
        case when ease_of_distraction between 1 and 5 then ease_of_distraction end as ease_of_distraction,
        case when bothered_by_worries between 1 and 5 then bothered_by_worries end as bothered_by_worries,
        case when difficulty_in_concentration between 1 and 5 then difficulty_in_concentration end as difficulty_in_concentration,
        case when comparison_of_self_to_peers between 1 and 5 then comparison_of_self_to_peers end as comparison_of_self_to_peers,
        case when feelings_about_above_comparison between 1 and 5 then feelings_about_above_comparison end as feelings_about_above_comparison,
        case when validation_sought_from_sm between 1 and 5 then validation_sought_from_sm end as validation_sought_from_sm,
        case when feeling_of_depression between 1 and 5 then feeling_of_depression end as feeling_of_depression,
        case when fluctuation_of_interest between 1 and 5 then fluctuation_of_interest end as fluctuation_of_interest,
        case when sleep_issues between 1 and 5 then sleep_issues end as sleep_issues
    from raw_data
),
std as (
    select
        respondent_id,
        age,

        -- gender normalization
        case
            when gender_raw in ('female','f') then 'female'
            when gender_raw in ('male','m') then 'male'
            when gender_raw is null then null
            else 'other'
        end as gender,

        -- relationship status normalization
        case
            when relationship_status_raw in ('single') then 'single'
            when relationship_status_raw in ('married') then 'married'
            when relationship_status_raw in ('divorced') then 'divorced'
            when relationship_status_raw in ('in a relationship','in relationship','relationship') then 'in a relationship'
            when relationship_status_raw is null then null
            else relationship_status_raw
        end as relationship_status,

        occupation_status_raw as occupation_status,
        affiliated_organization_raw as affiliated_organization,

        -- sm_usage normalization (optional; keep raw if already standardized)
        case
            when sm_usage_raw is null then null
            else sm_usage_raw
        end as sm_usage,

        platforms_raw as platforms,

        -- time_spent normalization (align to your exact category labels)
        case
            when time_spent_raw in ('<1hr','< 1hr','less than an hour','less than 1 hour','<1 hour') then 'less than an hour'
            when time_spent_raw in ('1-2','1 - 2','between 1 and 2 hours','between 1 & 2 hrs','1–2') then 'between 1 and 2 hours'
            when time_spent_raw in ('2-3','2 - 3','between 2 and 3 hours','between 2 & 3 hrs','2–3') then 'between 2 and 3 hours'
            when time_spent_raw in ('3-4','3 - 4','between 3 and 4 hours','between 3 & 4 hrs','3–4') then 'between 3 and 4 hours'
            when time_spent_raw in ('4-5','4 - 5','between 4 and 5 hours','between 4 & 5 hrs','4–5') then 'between 4 and 5 hours'
            when time_spent_raw in ('>5','> 5','more than 5 hours','more than five hours','5+','>=5') then 'more than 5 hours'
            else time_spent_raw
        end as time_spent,

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
    from base
)
select
    respondent_id,
    age,

    case
        when age between 13 and 22 then 'adolescents'
        when age between 23 and 32 then 'young adults'
        when age between 33 and 42 then 'early adults'
        when age between 43 and 52 then 'middle-aged adults'
        when age is null then null
        else 'senior adults'
    end as age_group,

    gender,
    relationship_status,
    occupation_status,
    affiliated_organization,
    sm_usage,
    platforms,
    time_spent,

    -- ordered key for tableau sorting
    case time_spent
        when 'less than an hour' then 1
        when 'between 1 and 2 hours' then 2
        when 'between 2 and 3 hours' then 3
        when 'between 3 and 4 hours' then 4
        when 'between 4 and 5 hours' then 5
        when 'more than 5 hours' then 6
        else null
    end as time_spent_order,

    -- composite indices (means) used in your analysis
    (purposeless_usage + distraction + ease_of_distraction + difficulty_in_concentration) / 4.0 as attention_mean,
    (restless_if_not_used + bothered_by_worries) / 2.0 as anxiety_mean,
    (feeling_of_depression + feelings_about_above_comparison + sleep_issues) / 3.0 as depression_mean,
    (comparison_of_self_to_peers + validation_sought_from_sm) / 2.0 as self_esteem_mean,

    -- keep individual items available for audit
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
from std;

-- quick integrity checks (optional)
-- select count(*) as n_rows from clean_data_v;
-- select time_spent, count(*) n from clean_data_v group by time_spent order by min(time_spent_order);
