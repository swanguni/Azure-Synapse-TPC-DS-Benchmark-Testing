USE CATALOG o9o9uccatalog;
--q96.sql--

SELECT /*TOP 100*/ count(*)
FROM TPCDS.store_sales,
     TPCDS.household_demographics,
     TPCDS.time_dim,
     TPCDS.store
WHERE ss_sold_time_sk = TPCDS.time_dim.t_time_sk
  AND ss_hdemo_sk = TPCDS.household_demographics.hd_demo_sk
  AND ss_store_sk = s_store_sk
  AND TPCDS.time_dim.t_hour = 20
  AND TPCDS.time_dim.t_minute >= 30
  AND TPCDS.household_demographics.hd_dep_count = 7
  AND TPCDS.store.s_store_name = 'ese'
ORDER BY count(*)
LIMIT 100
-- OPTION (LABEL = 'q96')
