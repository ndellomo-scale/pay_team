with 

/*Get every worker + info that worked or completed work in the last weeks*/
  ActiveWorkers as (
    SELECT 
    worker
    , worker_email
    , max(work_time) as last_submission
    , max(subtask_completed_at) as last_completed_submission
    FROM VIEW.FACT_WORK_AGGREGATE fwa
    LEFT JOIN public.users u on u._ID = fwa.worker
    group by 1,2
    HAVING (last_submission >= CAST(current_timestamp() as DATE) - interval '14 day'
            or last_completed_submission >= CAST(current_timestamp() as DATE) - interval '14 day')
  ),

/*Expand json*/
  payables as (
    select *,  value:status as status
    from SCALE_PROD.PUBLIC.PAYABLES, lateral flatten( input => amounts ) 
    where 
    created_at >= date '2022-05-01'
  ),

FWA as (        
  SELECT
  worker_email
  , project_name
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
  AND worker_email in (select worker_email from ActiveWorkers)
  GROUP BY 1,2
)


SELECT
Worker_email
, project_name
, avg_base_Acc as Base_Accuracy
, tot_submissions as throughput
, tot_base_pay as tot_pay
, speed
, norm_hourly_rate
from FWA

