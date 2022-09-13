select 
  b.*
  , u2.worker_status as referring_status
  , u2.IP_COUNTRY_CODE as referring_country
  , max(fwa.WORK_TIME) as referring_last_task
  , u2.email as worker_email
  , u2.paypal_email as paypal
  , u2.airtm_email as airtm
  , u2.first_name as firstname
  , u2.last_name as lastname
from (
  select 
    a.*
    ,u1.WORKER_STATUS as referred_status
    ,u1.IP_COUNTRY_CODE as referred_country 
    ,sum(fwa.PAYOUT) as referred_pay
  from (
    select 
    distinct
      date_trunc('day',AWARDED_AT) as award_date
      , date_trunc('day',__DUMP_TIME) as txn_date
      , _id as reward_id
      , cast(EXTRA_JSON:referral as varchar) as ref_id
      , cast(EXTRA_JSON:referredId as varchar) as referred
      , cast(EXTRA_JSON:referringId  as varchar) as referring
      , PAYOUT_AMOUNT_HUNDREDTHS_OF_CENTS/10000 as pay
    from SCALE_PROD.PUBLIC.REWARDS
    where reward_type = 'referral'
    and __DUMP_TIME >= CAST(current_timestamp() as DATE) - interval '7 day'
    and __DUMP_TIME < CAST(current_timestamp() as DATE)
  ) a 
  left join SCALE_PROD.PUBLIC.USERS u1
  on a.referred = u1._ID
  left join SCALE_PROD.VIEW.FACT_WORK_AGGREGATE fwa 
  on a.referred = fwa.WORKER
  group by 1,2,3,4,5,6,7,8,9
) b 
left join SCALE_PROD.PUBLIC.USERS u2
on b.referring = u2._ID
left join SCALE_PROD.VIEW.FACT_WORK_AGGREGATE fwa 
on b.referring = fwa.WORKER
group by 1,2,3,4,5,6,7,8,9,10,11,12,14,15,16,17,18