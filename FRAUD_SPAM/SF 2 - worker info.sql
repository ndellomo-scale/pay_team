with 

/*Get every worker + info that worked or completed work in the last weeks*/
  ActiveWorkers as (
    SELECT 
    worker
    , worker_email
    , worker_country_code as country
    , case when fwa.worker_source is null
    then 'Crowd'
    when fwa.worker_source in ('modta', 'phqa', '2dphqa')
    then 'modta/phqa'
    else 'other'
    end as source
    , case when source = 'modta/phqa'
    then left(right(worker_email, 16), 2) else 'not_modta'
    end as mod_team
    , case when u.AIRTM_EMAIL is not null then 'AIRTM' else 'PAYPAL' end as pay_method
    , coalesce(AIRTM_EMAIL, PAYPAL_EMAIL) as pay_email
    , max(work_time) as last_submission
    , max(subtask_completed_at) as last_completed_submission
    FROM VIEW.FACT_WORK_AGGREGATE fwa
    LEFT JOIN public.users u on u._ID = fwa.worker
    group by 1,2,3,4,5,6,7
    HAVING (last_submission >= CAST(current_timestamp() as DATE) - interval '14 day'
            or last_completed_submission >= CAST(current_timestamp() as DATE) - interval '14 day')
  ),

/*Count IP addresses per worker*/ 
  IPcount as (
    SELECT
    worker,
    count(distinct(IP)) as IPCount
    FROM public.useractions 
    WHERE worker in (SELECT distinct(worker) FROM ActiveWorkers)
    GROUP BY 1
  ),

/*Count workers sharing IP addresses*/
  AccountsSharingIP as (
    SELECT
    IP,
    count(distinct(worker)) as wCount
    FROM public.useractions 
    WHERE worker in (SELECT distinct(worker) FROM ActiveWorkers)
    GROUP BY 1
  ),

/*Join IP count and shared IP count by worker*/
  uaCount as (
    SELECT
    ua.worker, ua.IP,
    ipc.ipcount,
    asip.wcount
    FROM public.useractions ua
    LEFT JOIN IPcount ipc on ipc.worker = ua.worker
    LEFT JOIN AccountsSharingIP asip on asip.ip = ua.ip
    WHERE ua.worker in (SELECT distinct(worker) FROM ActiveWorkers)
  ),

/*Count worker sharing their pay_email*/
  pay_email_count as (
    SELECT 
    pay_email,
    count(worker) as sharing_pay_email
    FROM ActiveWorkers
    GROUP BY 1
  ),

/*Join everything*/
  final as (
    SELECT 
    aw.*
      , uac.ipcount
    , pec.sharing_pay_email
    , max(uac.wcount) as IP_MOST_SHARED_WITH
    FROM ActiveWorkers AW
    LEFT JOIN uaCount uac on uac.worker = AW.worker
    LEFT JOIN pay_email_count pec on pec.pay_email = AW.pay_email
    GROUP BY 1,2,3,4,5,6,7,8,9,10,11
  )

SELECT
*
  , ifnull(IPCOUNT, 0) + 
  ifnull(SHARING_PAY_EMAIL, 0) as flag
FROM final
ORDER BY flag desc









