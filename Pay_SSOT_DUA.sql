
-------------------------- SSOT PAY query -------------------------- 
--Objective: Get pay that is supposed to go out in the next pay period as well as past pay by week


------------PAST PAY------------

--Get payables (not frozen)
with nonFrozenPayables as (

  select
    *, coalesce(attempt, review) as submissions_id
    
  from 
    SCALE_PROD.PUBLIC.PAYABLES, lateral flatten( input => amounts ) 
    
  where true
      and (frozen is null or frozen = false)
      and reward is NULL
      
),


--Get all processed amounts (with exceptions) 
  --Exceptions: Processed pay, Tasker with pay method and not banned/disabled
    --By pay period (set as input), Grouping pay into task_pay, benchmark_pay and reward_pay
    --Grouping by worker source
amounts as (

  select
    P.value:netHundredthsOfCents / 10000 pay
    , P.value:payout as payout_id
    , P._ID as payable_ID
    , case 
        when submissions_id is not null then pay else 0
      end as task_pay
    , case 
        when reward is not null then pay else 0
      end as Reward_pay
    , case 
        when training_attempt is not null then pay else 0
      end as BM_pay
    , case
        when submissions_id is not null then fwa.project
        when reward is not null then coalesce(r.project, r2.project) --r2 in case it was attributed to a work_id
        when training_attempt is not null then ta.project
      end as project_id
    , case
        when u.worker_source is null then 'Crowd'
        when u.worker_source in ('modta', 'MODTA', 'modTA', 'ModTA') then 'MODTA'
        when u.worker_source in ('phqa', '2dphqa') then 'PHQA'
        else 'other'
      end as source
    , case
        when source in ('MODTA', 'PHQA')
          then left(right(u.email, 16), 2) else ''
      end as mod_team
    , P.worker
    , coalesce(fwa.WORKER_COUNTRY_CODE, u.IP_COUNTRY_CODE) as ip_country  --get project name and permission name at the end
    , coalesce(fwa.WORK_LEVEL, ta.review_level) as work_level
    , coalesce(fwa.TASK_TYPE, ta.TASK_TYPE, r.reward_type) as TYPE
    , fwa.SUBTASK_STATUS
    , case
        when (P.created_At >= timestamp '{{Initial date}}')
          and (P.created_At < timestamp '{{Final date}}')
          then timestamp '{{Initial date}}'
        when (P.created_At >= (timestamp '{{Initial date}}' - interval '7 day'))
          and (P.created_At < (timestamp '{{Final date}}' - interval '7 day'))
          then (timestamp '{{Initial date}}' - interval '7 day')
        when (P.created_At >= (timestamp '{{Initial date}}' - interval '14 day'))
          and (P.created_At < (timestamp '{{Final date}}' - interval '14 day'))
          then (timestamp '{{Initial date}}' - interval '14 day')
        when (P.created_At >= (timestamp '{{Initial date}}' - interval '21 day'))
          and (P.created_At < (timestamp '{{Final date}}' - interval '21 day'))
          then (timestamp '{{Initial date}}' - interval '21 day')
        when (P.created_At >= (timestamp '{{Initial date}}' - interval '28 day'))
          and (P.created_At < (timestamp '{{Final date}}' - interval '28 day'))
          then (timestamp '{{Initial date}}' - interval '28 day')
        end as wk
    , coalesce(fwa.work_id, ta._ID, r._ID) as _ID
    , coalesce(fwa.BEST_GUESS_HOURS_SPENT, ta.TIME_SPENT_SECS/3600) as Time_spent
  
  from nonFrozenPayables P
      left join public.users u 
            on P.worker = u._id
      left join view.fact_work_aggregate fwa 
            on P.submissions_id = fwa.work_id
      left join public.rewards r
            on P.reward = r._ID
      left join public.trainingattempts ta
            on P.training_attempt = ta._ID
      left join public.rewards r2
            on fwa.work_ID = r2.submission_ID
            
  where TRUE
    and (P.value :status <> 'pending'
    and P.value :status <> 'canceled')
    and u.account_type = 'worker'
    and u.worker_status <> 'banned'
    and u.worker_status <> 'disabled'
    and (u.paypal_email is not null
      or u.airtm_email is not null
      or u.payoneer_email is not null)
      
),

--Clean
projects_past as (

  select
    wk
    , payable_ID, payout_ID, source, a._ID
    , task_pay, BM_pay, Reward_pay, Time_spent
    , project_id, p.name
    , ip_country, mod_team
    , WORK_LEVEL, TYPE, SUBTASK_STATUS
    
  from amounts a
      left join public.projects p
            on a.project_id = p._id
  
  where true
    and wk <> '{{Initial date}}'
    and wk is not null
    and source is not null
    
),


------------Future PAY------------

--Get all payable ids with some amount to be paid (either in the pay period or forced)--
payable_ids as (

  select
    distinct(_id)
    
  from nonFrozenPayables p

  where true
      and (
        (p.value :createdAt >= timestamp '{{Initial date}}' --00:00 for crowd (UTC) tuesday
        and p.value :createdAt < timestamp '{{Final date}}') --07:00 for mods (UTC) monday
        or p.value :forcedIntoPeriod = true)
        
),

--get all amounts to be paid: pending amounts from the payable ids above, up to cutoff date (this also includes old amounts)--
amounts2 as (

  select
    P.value :netHundredthsOfCents / 10000 pay
    , P.value:payout as payout_id
    , P._ID as payable_ID
    , case 
        when submissions_id is not null then pay else 0
      end as task_pay
    , case 
        when reward is not null then pay else 0
      end as Reward_pay
    , case 
        when training_attempt is not null then pay else 0
      end as BM_pay
    , case
        when submissions_id is not null then fwa.project
        when reward is not null then coalesce(r.project, r2.project) --r2 in case it was attributed to a work_id
        when training_attempt is not null then ta.project
      end as project_id
    , case
        when u.worker_source is null then 'Crowd'
        when u.worker_source in ('modta', 'MODTA', 'modTA', 'ModTA') then 'MODTA'
        when u.worker_source in ('phqa', '2dphqa') then 'PHQA'
        else 'other'
      end as source
    , case
        when source in ('MODTA', 'PHQA')
          then left(right(u.email, 16), 2) else ''
      end as mod_team
    , P.worker
    , coalesce(fwa.WORKER_COUNTRY_CODE, u.IP_COUNTRY_CODE) as ip_country  --get project name and permission name at the end
    , coalesce(fwa.WORK_LEVEL, ta.review_level) as work_level
    , coalesce(fwa.TASK_TYPE, ta.TASK_TYPE, r.reward_type) as TYPE
    , fwa.SUBTASK_STATUS
    , coalesce(fwa.work_id, ta._ID, r._ID) as _ID
    , coalesce(fwa.BEST_GUESS_HOURS_SPENT, ta.TIME_SPENT_SECS/3600) as Time_spent

  from nonFrozenPayables P
      left join public.users u 
            on P.worker = u._id
      left join view.fact_work_aggregate fwa 
            on P.submissions_id = fwa.work_id
      left join public.rewards r
            on P.reward = r._ID
      left join public.trainingattempts ta
            on P.training_attempt = ta._ID
      left join public.rewards r2
            on fwa.work_ID = r2.submission_ID

where true
      and p._id in (select _id from payable_ids)
      and (
            P.value :createdAt < timestamp '{{Final date}}'
            or P.value :forcedIntoPeriod = true
          )
      and (
            P.value :status <> 'processed'
            and P.value :status <> 'canceled'
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


--Clean
projects_future as (

  select
    '{{Initial date}}' as wk
    , payable_ID, payout_ID, source, a._ID
    , task_pay, BM_pay, Reward_pay, Time_spent
    , project_id, p.name
    , ip_country, mod_team
    , WORK_LEVEL, TYPE, SUBTASK_STATUS
    
  from amounts2 a
      left join public.projects p
            on a.project_id = p._id

)


-----------------------Unions--------------------------
select *
from projects_past

union

select *
from projects_future


