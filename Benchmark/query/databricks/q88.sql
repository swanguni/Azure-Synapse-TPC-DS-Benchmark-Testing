USE CATALOG o9o9uccatalog;
--q88.sql--

SELECT *
FROM
  (SELECT count(*) h8_30_to_9
   FROM TPCDS.store_sales,
        TPCDS.household_demographics,
        TPCDS.time_dim,
        TPCDS.store
   WHERE ss_sold_time_sk = TPCDS.time_dim.t_time_sk
     AND ss_hdemo_sk = TPCDS.household_demographics.hd_demo_sk
     AND ss_store_sk = s_store_sk
     AND TPCDS.time_dim.t_hour = 8
     AND TPCDS.time_dim.t_minute >= 30
     AND ((TPCDS.household_demographics.hd_dep_count = 4
           AND TPCDS.household_demographics.hd_vehicle_count<=4+2)
          OR (TPCDS.household_demographics.hd_dep_count = 2
              AND TPCDS.household_demographics.hd_vehicle_count<=2+2)
          OR (TPCDS.household_demographics.hd_dep_count = 0
              AND TPCDS.household_demographics.hd_vehicle_count<=0+2))
     AND TPCDS.store.s_store_name = 'ese') s1
CROSS JOIN
  (SELECT count(*) h9_to_9_30
   FROM TPCDS.store_sales,
        TPCDS.household_demographics,
        TPCDS.time_dim,
        TPCDS.store
   WHERE ss_sold_time_sk = TPCDS.time_dim.t_time_sk
     AND ss_hdemo_sk = TPCDS.household_demographics.hd_demo_sk
     AND ss_store_sk = s_store_sk
     AND TPCDS.time_dim.t_hour = 9
     AND TPCDS.time_dim.t_minute < 30
     AND ((TPCDS.household_demographics.hd_dep_count = 4
           AND TPCDS.household_demographics.hd_vehicle_count<=4+2)
          OR (TPCDS.household_demographics.hd_dep_count = 2
              AND TPCDS.household_demographics.hd_vehicle_count<=2+2)
          OR (TPCDS.household_demographics.hd_dep_count = 0
              AND TPCDS.household_demographics.hd_vehicle_count<=0+2))
     AND TPCDS.store.s_store_name = 'ese') s2
CROSS JOIN
  (SELECT count(*) h9_30_to_10
   FROM TPCDS.store_sales,
        TPCDS.household_demographics,
        TPCDS.time_dim,
        TPCDS.store
   WHERE ss_sold_time_sk = TPCDS.time_dim.t_time_sk
     AND ss_hdemo_sk = TPCDS.household_demographics.hd_demo_sk
     AND ss_store_sk = s_store_sk
     AND TPCDS.time_dim.t_hour = 9
     AND TPCDS.time_dim.t_minute >= 30
     AND ((TPCDS.household_demographics.hd_dep_count = 4
           AND TPCDS.household_demographics.hd_vehicle_count<=4+2)
          OR (TPCDS.household_demographics.hd_dep_count = 2
              AND TPCDS.household_demographics.hd_vehicle_count<=2+2)
          OR (TPCDS.household_demographics.hd_dep_count = 0
              AND TPCDS.household_demographics.hd_vehicle_count<=0+2))
     AND TPCDS.store.s_store_name = 'ese') s3
CROSS JOIN
  (SELECT count(*) h10_to_10_30
   FROM TPCDS.store_sales,
        TPCDS.household_demographics,
        TPCDS.time_dim,
        TPCDS.store
   WHERE ss_sold_time_sk = TPCDS.time_dim.t_time_sk
     AND ss_hdemo_sk = TPCDS.household_demographics.hd_demo_sk
     AND ss_store_sk = s_store_sk
     AND TPCDS.time_dim.t_hour = 10
     AND TPCDS.time_dim.t_minute < 30
     AND ((TPCDS.household_demographics.hd_dep_count = 4
           AND TPCDS.household_demographics.hd_vehicle_count<=4+2)
          OR (TPCDS.household_demographics.hd_dep_count = 2
              AND TPCDS.household_demographics.hd_vehicle_count<=2+2)
          OR (TPCDS.household_demographics.hd_dep_count = 0
              AND TPCDS.household_demographics.hd_vehicle_count<=0+2))
     AND TPCDS.store.s_store_name = 'ese') s4
CROSS JOIN
  (SELECT count(*) h10_30_to_11
   FROM TPCDS.store_sales,
        TPCDS.household_demographics,
        TPCDS.time_dim,
        TPCDS.store
   WHERE ss_sold_time_sk = TPCDS.time_dim.t_time_sk
     AND ss_hdemo_sk = TPCDS.household_demographics.hd_demo_sk
     AND ss_store_sk = s_store_sk
     AND TPCDS.time_dim.t_hour = 10
     AND TPCDS.time_dim.t_minute >= 30
     AND ((TPCDS.household_demographics.hd_dep_count = 4
           AND TPCDS.household_demographics.hd_vehicle_count<=4+2)
          OR (TPCDS.household_demographics.hd_dep_count = 2
              AND TPCDS.household_demographics.hd_vehicle_count<=2+2)
          OR (TPCDS.household_demographics.hd_dep_count = 0
              AND TPCDS.household_demographics.hd_vehicle_count<=0+2))
     AND TPCDS.store.s_store_name = 'ese') s5
CROSS JOIN
  (SELECT count(*) h11_to_11_30
   FROM TPCDS.store_sales,
        TPCDS.household_demographics,
        TPCDS.time_dim,
        TPCDS.store
   WHERE ss_sold_time_sk = TPCDS.time_dim.t_time_sk
     AND ss_hdemo_sk = TPCDS.household_demographics.hd_demo_sk
     AND ss_store_sk = s_store_sk
     AND TPCDS.time_dim.t_hour = 11
     AND TPCDS.time_dim.t_minute < 30
     AND ((TPCDS.household_demographics.hd_dep_count = 4
           AND TPCDS.household_demographics.hd_vehicle_count<=4+2)
          OR (TPCDS.household_demographics.hd_dep_count = 2
              AND TPCDS.household_demographics.hd_vehicle_count<=2+2)
          OR (TPCDS.household_demographics.hd_dep_count = 0
              AND TPCDS.household_demographics.hd_vehicle_count<=0+2))
     AND TPCDS.store.s_store_name = 'ese') s6
CROSS JOIN
  (SELECT count(*) h11_30_to_12
   FROM TPCDS.store_sales,
        TPCDS.household_demographics,
        TPCDS.time_dim,
        TPCDS.store
   WHERE ss_sold_time_sk = TPCDS.time_dim.t_time_sk
     AND ss_hdemo_sk = TPCDS.household_demographics.hd_demo_sk
     AND ss_store_sk = s_store_sk
     AND TPCDS.time_dim.t_hour = 11
     AND TPCDS.time_dim.t_minute >= 30
     AND ((TPCDS.household_demographics.hd_dep_count = 4
           AND TPCDS.household_demographics.hd_vehicle_count<=4+2)
          OR (TPCDS.household_demographics.hd_dep_count = 2
              AND TPCDS.household_demographics.hd_vehicle_count<=2+2)
          OR (TPCDS.household_demographics.hd_dep_count = 0
              AND TPCDS.household_demographics.hd_vehicle_count<=0+2))
     AND TPCDS.store.s_store_name = 'ese') s7
CROSS JOIN
  (SELECT count(*) h12_to_12_30
   FROM TPCDS.store_sales,
        TPCDS.household_demographics,
        TPCDS.time_dim,
        TPCDS.store
   WHERE ss_sold_time_sk = TPCDS.time_dim.t_time_sk
     AND ss_hdemo_sk = TPCDS.household_demographics.hd_demo_sk
     AND ss_store_sk = s_store_sk
     AND TPCDS.time_dim.t_hour = 12
     AND TPCDS.time_dim.t_minute < 30
     AND ((TPCDS.household_demographics.hd_dep_count = 4
           AND TPCDS.household_demographics.hd_vehicle_count<=4+2)
          OR (TPCDS.household_demographics.hd_dep_count = 2
              AND TPCDS.household_demographics.hd_vehicle_count<=2+2)
          OR (TPCDS.household_demographics.hd_dep_count = 0
              AND TPCDS.household_demographics.hd_vehicle_count<=0+2))
     AND TPCDS.store.s_store_name = 'ese') s8
-- OPTION (LABEL = 'q88')