with 

/*Get every worker + info that worked or completed work in the last weeks*/
ActiveProjects as (
  SELECT 
  project
  , project_name
  , max(work_time) as last_submission
  , max(subtask_completed_at) as last_completed_submission
  FROM VIEW.FACT_WORK_AGGREGATE fwa
  LEFT JOIN public.users u on u._ID = fwa.worker
  group by 1,2
  HAVING (last_submission >= CAST(current_timestamp() as DATE) - interval '14 day'
          or last_completed_submission >= CAST(current_timestamp() as DATE) - interval '14 day')
),


payables as (
  select *,  value:status as status
  from SCALE_PROD.PUBLIC.PAYABLES, lateral flatten( input => amounts ) 
  where 
  created_at >= date '2022-05-01'
),

FWA as (        
  SELECT
  project_name
  , avg(BASE_ACCURACY) as avg_base_acc
  , count(*) as tot_submissions
  , sum(best_guess_hours_spent) as tot_base_hours
  , sum(payout) as tot_base_pay
  , div0(sum(normalized_payout),sum(best_guess_hours_spent)) as norm_hourly_rate
  , div0(count(*),sum(best_guess_hours_spent)) as speed
  FROM view.fact_work_aggregate fwa
  left join payables p on coalesce(p.review, p.attempt) = fwa.work_id
  WHERE
  P.created_At >= current_timestamp() - interval '7 day'
  AND P.created_At < current_timestamp()
  AND project_name in (select project_name from ActiveProjects)
  GROUP BY 1
),

BM as (
  SELECT
  pp.name as project_name
  , avg(accuracy) as avg_bm_acc
  , count(*) as tot_bm_subs
  , sum(TIME_SPENT_SECS)/3600 as tot_bm_hours
  , sum(PAYOUT_AMOUNT_HUNDREDTHS_OF_CENTS)/10000 as tot_bm_pay
  FROM full.trainingattempts ta
  left join public.projects pp on pp._ID = ta.project
  left join payables p on p.TRAINING_ATTEMPT = ta._ID
  WHERE
  P.created_At >= current_timestamp() - interval '7 day'
  AND P.created_At < current_timestamp()  
  AND project_name in (select project_name from ActiveProjects)
  GROUP BY 1
)



SELECT
ap.project_name
, ap.project
, avg_base_Acc as Base_Accuracy
, avg_bm_acc as BM_Accuracy
, tot_submissions as throughput
, tot_base_hours + tot_bm_hours as tot_hours 
, tot_base_pay + tot_bm_pay as tot_pay
, tot_bm_subs as BM_count
, speed
, norm_hourly_rate
from ActiveProjects ap
left join FWA on FWA.project_name = AP.project_name
left join BM on BM.project_name = AP.project_name




