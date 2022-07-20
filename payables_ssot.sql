



-----------------------PAST------------------------
--get all amounts from non-frozen payables--
with main as (

select
      *
      , coalesce(attempt, review) as submissions_id

from SCALE_PROD.PUBLIC.PAYABLES, lateral flatten( input => amounts ) 

where true
      and (frozen is null or frozen = false)
      and reward is NULL
      
),
--get all amounts to be paid: pending amounts from the payable ids above, up to cutoff date (this also includes old amounts)--
amounts as (

select
      m.value :netHundredthsOfCents / 10000 pay
      , m.worker
      , case
            when u.worker_source is null then 'Crowd'
            when u.worker_source in ('modta', 'MODTA', 'modTA', 'ModTA') then 'MODTA'
            when u.worker_source in ('phqa', '2dphqa') then 'PHQA'
            else 'other'
      end as source
    , fwa.project_name
    , fwa.project
    , fwa.PERMISSION_GROUP_NAME
    , fwa.WORKER_COUNTRY_CODE
    , fwa.WORK_LEVEL
    , fwa.TASK_TYPE
    , fwa.SUBTASK_STATUS
    , case
            when (created_At >= timestamp '{{Initial date}}')
            and (created_At < timestamp '{{Final date}}') then timestamp '{{Initial date}}'
            when (
              created_At >= (timestamp '{{Initial date}}' - interval '7 day')
            )
            and (
              created_At < (timestamp '{{Final date}}' - interval '7 day')
            ) then (timestamp '{{Initial date}}' - interval '7 day')
            when (
              created_At >= (timestamp '{{Initial date}}' - interval '14 day')
            )
            and (
              created_At < (timestamp '{{Final date}}' - interval '14 day')
            ) then (timestamp '{{Initial date}}' - interval '14 day')
            when (
              created_At >= (timestamp '{{Initial date}}' - interval '21 day')
            )
            and (
              created_At < (timestamp '{{Final date}}' - interval '21 day')
            ) then (timestamp '{{Initial date}}' - interval '21 day')
            when (
              created_At >= (timestamp '{{Initial date}}' - interval '28 day')
            )
            and (
              created_At < (timestamp '{{Final date}}' - interval '28 day')
            ) then (timestamp '{{Initial date}}' - interval '28 day')
            end as wk
      , fwa.work_id
      , fwa.BEST_GUESS_HOURS_SPENT

from main m
      left join public.users u 
            on m.worker = u._id
      left join view.fact_work_aggregate fwa 
            on m.submissions_id = fwa.work_id
where TRUE
and (m.value :status <> 'pending'
      and m.value :status <> 'canceled')
and u.account_type = 'worker'
and u.worker_status <> 'banned'
and u.worker_status <> 'disabled'
and (u.paypal_email is not null
      or u.airtm_email is not null
      or u.payoneer_email is not null)
      
),
projects_past_1 as (

select
    wk
    , source
    , project_name
    , PERMISSION_GROUP_NAME
    , WORKER_COUNTRY_CODE
    , WORK_LEVEL
    , TASK_TYPE
    , SUBTASK_STATUS
    , sum(pay) as Total_pay
    , count(work_id) as tasks
    , sum(BEST_GUESS_HOURS_SPENT) as hours
    
from amounts

where true
      and wk <> '{{Initial date}}'
      and wk is not null
      and source is not null --and project_name is not null

group by 1,2,3,4,5,6,7,8

),
projects_past_2 as (

select
    *
from projects_past_1

),
-----------------------FUTURE--------------------------
--get all amounts from non-frozen payables--
main2 as (

select
      *
      , coalesce(attempt, review) as submissions_id
from SCALE_PROD.PUBLIC.PAYABLES, lateral flatten( input => amounts ) 

where true
      and frozen is null or frozen = false
      and reward is NULL
      
),
--get all payable ids with some amount to be paid (either in the pay period or forced)--
payable_ids as (

select
      distinct(_id)
from main2 p

where true
      and (
      (
        p.value :createdAt >= timestamp '2022-07-11 07:00' --00:00 for crowd (UTC) tuesday
        and p.value :createdAt < timestamp '2022-07-18 07:00'
      ) --07:00 for mods (UTC) monday
      or p.value :forcedIntoPeriod = true
    )
    
),
--get all amounts to be paid: pending amounts from the payable ids above, up to cutoff date (this also includes old amounts)--
amounts2 as (

select
      m.value :netHundredthsOfCents / 10000 pay
      , m.worker
      , case
            when u.worker_source is null then 'Crowd'
            when u.worker_source in ('modta', 'MODTA', 'modTA', 'ModTA') then 'MODTA'
            when u.worker_source in ('phqa', '2dphqa') then 'PHQA'
            else 'other'
      end as source
      , fwa.project_name
      , fwa.work_id
      , fwa.BEST_GUESS_HOURS_SPENT
      , fwa.PERMISSION_GROUP_NAME
      , fwa.WORKER_COUNTRY_CODE
      , fwa.WORK_LEVEL
      , fwa.TASK_TYPE
      , fwa.SUBTASK_STATUS

from main2 m
      left join public.users u 
            on m.worker = u._id
      left join view.fact_work_aggregate fwa 
            on m.submissions_id = fwa.work_id

where true
      and m._id in (
            select _id from payable_ids)
      and (
            m.value :createdAt < timestamp '2022-07-18 07:00'
            or m.value :forcedIntoPeriod = true
            )
      and (
            m.value :status <> 'processed'
            and m.value :status <> 'canceled'
          )
      and u.account_type = 'worker'
      and u.worker_status <> 'banned'
      and u.worker_status <> 'disabled'
      and (
            u.paypal_email is not null
            or u.airtm_email is not null
            or u.payoneer_email is not null
            )
            
),

projects_future_1 as (
select
      '{{Initial date}}' as wk
      , source
      , project_name
      , PERMISSION_GROUP_NAME
      , WORKER_COUNTRY_CODE
      , WORK_LEVEL
      , TASK_TYPE
      , SUBTASK_STATUS
      , sum(pay) as Total_pay
      , count(work_id) as tasks
      , sum(BEST_GUESS_HOURS_SPENT) as hours
      
from amounts2

where true
      and  source is not null --and project_name is not null

group by 1,2,3,4,5,6,7,8

),
projects_future_2 as (

select
      *
from projects_future_1

),

-----------------------PAST REWARDS--------------------------
main_r1 as (

select
      *
      , REWARD as submissions_id

from SCALE_PROD.PUBLIC.PAYABLES, lateral flatten( input => amounts ) 

where true
      and frozen is null or frozen = false
      and REWARD is not NULL
      
),
--get all amounts to be paid: pending amounts from the payable ids above, up to cutoff date (this also includes old amounts)--
amounts_r1 as (

select
      m.value :netHundredthsOfCents / 10000 pay
      , m.worker
      , case
            when u.worker_source is null then 'Crowd'
            when u.worker_source in ('modta', 'MODTA', 'modTA', 'ModTA') then 'MODTA'
            when u.worker_source in ('phqa', '2dphqa') then 'PHQA'
            else 'other'
      end as source
    , p.project_name
    , r.project
    , p.PERMISSION_GROUP_NAME
    , u.COUNTRY_CODE as WORKER_COUNTRY_CODE
    , case
            when (created_At >= timestamp '{{Initial date}}')
            and (created_At < timestamp '{{Final date}}') then timestamp '{{Initial date}}'
            when (
              created_At >= (timestamp '{{Initial date}}' - interval '7 day')
            )
            and (
              created_At < (timestamp '{{Final date}}' - interval '7 day')
            ) then (timestamp '{{Initial date}}' - interval '7 day')
            when (
              created_At >= (timestamp '{{Initial date}}' - interval '14 day')
            )
            and (
              created_At < (timestamp '{{Final date}}' - interval '14 day')
            ) then (timestamp '{{Initial date}}' - interval '14 day')
            when (
              created_At >= (timestamp '{{Initial date}}' - interval '21 day')
            )
            and (
              created_At < (timestamp '{{Final date}}' - interval '21 day')
            ) then (timestamp '{{Initial date}}' - interval '21 day')
            when (
              created_At >= (timestamp '{{Initial date}}' - interval '28 day')
            )
            and (
              created_At < (timestamp '{{Final date}}' - interval '28 day')
            ) then (timestamp '{{Initial date}}' - interval '28 day')
            end as wk
      , 1 as work_id
      , 0 as BEST_GUESS_HOURS_SPENT

from main_r1 m
      left join public.users u 
            on m.worker = u._id
            
      left join PUBLIC.REWARDS r 
            on m.submissions_id = r.SUBMISSION_ID
      
      left join VIEW.DIM_PROJECTS p
            on r.project = p.PROJECT_ID
            
where 
 (m.value :status <> 'pending'
      and m.value :status <> 'canceled')
and u.account_type = 'worker'
and u.worker_status <> 'banned'
and u.worker_status <> 'disabled'
and (u.paypal_email is not null
      or u.airtm_email is not null
      or u.payoneer_email is not null)
      
),
projects_past_r1 as (

select
      wk
      , source
      , project_name
      , PERMISSION_GROUP_NAME
      , WORKER_COUNTRY_CODE
      , 'rewards' as WORK_LEVEL
      , 'rewards' as TASK_TYPE
      , 'rewards' as SUBTASK_STATUS
      , sum(pay) as Total_pay
      , count(work_id) as tasks
      , sum(BEST_GUESS_HOURS_SPENT) as hours
    
from amounts_r1

where true
      and wk <> '{{Initial date}}'
      and wk is not null
      and source is not null --and project_name is not null

group by 1,2,3,4,5,6,7,8

),
projects_past_r2 as (

select
    *
from projects_past_r1

),

-----------------------FUTURE REWARDS--------------------------

--get all amounts from non-frozen payables--
main_r2 as (

select
      *
      , REWARD as submissions_id

from SCALE_PROD.PUBLIC.PAYABLES, lateral flatten( input => amounts ) 

where true
      and frozen is null or frozen = false
      and REWARD is not NULL
      
),
--get all payable ids with some amount to be paid (either in the pay period or forced)--
payable_ids_r as (

select
      distinct(_id)
from main_r2 p

where true
      and (
      (
        p.value :createdAt >= timestamp '2022-07-11 07:00' --00:00 for crowd (UTC) tuesday
        and p.value :createdAt < timestamp '2022-07-18 07:00'
      ) --07:00 for mods (UTC) monday
      or p.value :forcedIntoPeriod = true
    )
    
),
--get all amounts to be paid: pending amounts from the payable ids above, up to cutoff date (this also includes old amounts)--
amounts_r2 as (

select
      m.value :netHundredthsOfCents / 10000 pay
      , m.worker
      , case
            when u.worker_source is null then 'Crowd'
            when u.worker_source in ('modta', 'MODTA', 'modTA', 'ModTA') then 'MODTA'
            when u.worker_source in ('phqa', '2dphqa') then 'PHQA'
            else 'other'
            end as source
      , 1 as work_id
      , 0 as BEST_GUESS_HOURS_SPENT
      , p.project_name
      , r.project
      , p.PERMISSION_GROUP_NAME
      , u.COUNTRY_CODE as WORKER_COUNTRY_CODE

from main_r2 m

      left join public.users u 
            on m.worker = u._id
            
      left join PUBLIC.REWARDS r 
            on m.submissions_id = r.SUBMISSION_ID
      
      left join VIEW.DIM_PROJECTS p
            on r.project = p.PROJECT_ID

where true
      and m._id in (
            select _id from payable_ids_r
            )
      and (
            m.value :createdAt < timestamp '2022-07-18 07:00'
            or m.value :forcedIntoPeriod = true
            )
      and (
            m.value :status <> 'processed'
            and m.value :status <> 'canceled'
          )
      and u.account_type = 'worker'
      and u.worker_status <> 'banned'
      and u.worker_status <> 'disabled'
      and (
            u.paypal_email is not null
            or u.airtm_email is not null
            or u.payoneer_email is not null
            )
            
),

projects_future_r1 as (
select
      '{{Initial date}}' as wk
      , source
      , project_name
      , PERMISSION_GROUP_NAME
      , WORKER_COUNTRY_CODE
      , 'rewards' as WORK_LEVEL
      , 'rewards' as TASK_TYPE
      , 'rewards' as SUBTASK_STATUS
      , sum(pay) as Total_pay
      , count(work_id) as tasks
      , sum(BEST_GUESS_HOURS_SPENT) as hours
      
from amounts_r2

where true
      and  source is not null --and project_name is not null

group by 1,2,3,4,5,6,7,8

),

projects_future_r2 as (
select *
from projects_future_r1
)


-----------------------Unions--------------------------
select *
from projects_past_2

union

select *
from projects_future_2

union

select *
from projects_past_r1

union

select *
from projects_past_r2
 
