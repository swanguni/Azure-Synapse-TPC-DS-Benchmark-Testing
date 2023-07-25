--q96.sql--

SELECT TOP 100 count(*)
FROM dbo.store_sales,
     dbo.household_demographics,
     dbo.time_dim,
     dbo.store
WHERE ss_sold_time_sk = dbo.time_dim.t_time_sk
  AND ss_hdemo_sk = dbo.household_demographics.hd_demo_sk
  AND ss_store_sk = s_store_sk
  AND dbo.time_dim.t_hour = 20
  AND dbo.time_dim.t_minute >= 30
  AND dbo.household_demographics.hd_dep_count = 7
  AND dbo.store.s_store_name = 'ese'
ORDER BY count(*)
OPTION (LABEL = 'q96')
