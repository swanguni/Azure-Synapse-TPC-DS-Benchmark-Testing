--q88.sql--

SELECT *
FROM
  (SELECT count(*) h8_30_to_9
   FROM dbo.store_sales,
        dbo.household_demographics,
        dbo.time_dim,
        dbo.store
   WHERE ss_sold_time_sk = dbo.time_dim.t_time_sk
     AND ss_hdemo_sk = dbo.household_demographics.hd_demo_sk
     AND ss_store_sk = s_store_sk
     AND dbo.time_dim.t_hour = 8
     AND dbo.time_dim.t_minute >= 30
     AND ((dbo.household_demographics.hd_dep_count = 4
           AND dbo.household_demographics.hd_vehicle_count<=4+2)
          OR (dbo.household_demographics.hd_dep_count = 2
              AND dbo.household_demographics.hd_vehicle_count<=2+2)
          OR (dbo.household_demographics.hd_dep_count = 0
              AND dbo.household_demographics.hd_vehicle_count<=0+2))
     AND dbo.store.s_store_name = 'ese') s1
CROSS JOIN
  (SELECT count(*) h9_to_9_30
   FROM dbo.store_sales,
        dbo.household_demographics,
        dbo.time_dim,
        dbo.store
   WHERE ss_sold_time_sk = dbo.time_dim.t_time_sk
     AND ss_hdemo_sk = dbo.household_demographics.hd_demo_sk
     AND ss_store_sk = s_store_sk
     AND dbo.time_dim.t_hour = 9
     AND dbo.time_dim.t_minute < 30
     AND ((dbo.household_demographics.hd_dep_count = 4
           AND dbo.household_demographics.hd_vehicle_count<=4+2)
          OR (dbo.household_demographics.hd_dep_count = 2
              AND dbo.household_demographics.hd_vehicle_count<=2+2)
          OR (dbo.household_demographics.hd_dep_count = 0
              AND dbo.household_demographics.hd_vehicle_count<=0+2))
     AND dbo.store.s_store_name = 'ese') s2
CROSS JOIN
  (SELECT count(*) h9_30_to_10
   FROM dbo.store_sales,
        dbo.household_demographics,
        dbo.time_dim,
        dbo.store
   WHERE ss_sold_time_sk = dbo.time_dim.t_time_sk
     AND ss_hdemo_sk = dbo.household_demographics.hd_demo_sk
     AND ss_store_sk = s_store_sk
     AND dbo.time_dim.t_hour = 9
     AND dbo.time_dim.t_minute >= 30
     AND ((dbo.household_demographics.hd_dep_count = 4
           AND dbo.household_demographics.hd_vehicle_count<=4+2)
          OR (dbo.household_demographics.hd_dep_count = 2
              AND dbo.household_demographics.hd_vehicle_count<=2+2)
          OR (dbo.household_demographics.hd_dep_count = 0
              AND dbo.household_demographics.hd_vehicle_count<=0+2))
     AND dbo.store.s_store_name = 'ese') s3
CROSS JOIN
  (SELECT count(*) h10_to_10_30
   FROM dbo.store_sales,
        dbo.household_demographics,
        dbo.time_dim,
        dbo.store
   WHERE ss_sold_time_sk = dbo.time_dim.t_time_sk
     AND ss_hdemo_sk = dbo.household_demographics.hd_demo_sk
     AND ss_store_sk = s_store_sk
     AND dbo.time_dim.t_hour = 10
     AND dbo.time_dim.t_minute < 30
     AND ((dbo.household_demographics.hd_dep_count = 4
           AND dbo.household_demographics.hd_vehicle_count<=4+2)
          OR (dbo.household_demographics.hd_dep_count = 2
              AND dbo.household_demographics.hd_vehicle_count<=2+2)
          OR (dbo.household_demographics.hd_dep_count = 0
              AND dbo.household_demographics.hd_vehicle_count<=0+2))
     AND dbo.store.s_store_name = 'ese') s4
CROSS JOIN
  (SELECT count(*) h10_30_to_11
   FROM dbo.store_sales,
        dbo.household_demographics,
        dbo.time_dim,
        dbo.store
   WHERE ss_sold_time_sk = dbo.time_dim.t_time_sk
     AND ss_hdemo_sk = dbo.household_demographics.hd_demo_sk
     AND ss_store_sk = s_store_sk
     AND dbo.time_dim.t_hour = 10
     AND dbo.time_dim.t_minute >= 30
     AND ((dbo.household_demographics.hd_dep_count = 4
           AND dbo.household_demographics.hd_vehicle_count<=4+2)
          OR (dbo.household_demographics.hd_dep_count = 2
              AND dbo.household_demographics.hd_vehicle_count<=2+2)
          OR (dbo.household_demographics.hd_dep_count = 0
              AND dbo.household_demographics.hd_vehicle_count<=0+2))
     AND dbo.store.s_store_name = 'ese') s5
CROSS JOIN
  (SELECT count(*) h11_to_11_30
   FROM dbo.store_sales,
        dbo.household_demographics,
        dbo.time_dim,
        dbo.store
   WHERE ss_sold_time_sk = dbo.time_dim.t_time_sk
     AND ss_hdemo_sk = dbo.household_demographics.hd_demo_sk
     AND ss_store_sk = s_store_sk
     AND dbo.time_dim.t_hour = 11
     AND dbo.time_dim.t_minute < 30
     AND ((dbo.household_demographics.hd_dep_count = 4
           AND dbo.household_demographics.hd_vehicle_count<=4+2)
          OR (dbo.household_demographics.hd_dep_count = 2
              AND dbo.household_demographics.hd_vehicle_count<=2+2)
          OR (dbo.household_demographics.hd_dep_count = 0
              AND dbo.household_demographics.hd_vehicle_count<=0+2))
     AND dbo.store.s_store_name = 'ese') s6
CROSS JOIN
  (SELECT count(*) h11_30_to_12
   FROM dbo.store_sales,
        dbo.household_demographics,
        dbo.time_dim,
        dbo.store
   WHERE ss_sold_time_sk = dbo.time_dim.t_time_sk
     AND ss_hdemo_sk = dbo.household_demographics.hd_demo_sk
     AND ss_store_sk = s_store_sk
     AND dbo.time_dim.t_hour = 11
     AND dbo.time_dim.t_minute >= 30
     AND ((dbo.household_demographics.hd_dep_count = 4
           AND dbo.household_demographics.hd_vehicle_count<=4+2)
          OR (dbo.household_demographics.hd_dep_count = 2
              AND dbo.household_demographics.hd_vehicle_count<=2+2)
          OR (dbo.household_demographics.hd_dep_count = 0
              AND dbo.household_demographics.hd_vehicle_count<=0+2))
     AND dbo.store.s_store_name = 'ese') s7
CROSS JOIN
  (SELECT count(*) h12_to_12_30
   FROM dbo.store_sales,
        dbo.household_demographics,
        dbo.time_dim,
        dbo.store
   WHERE ss_sold_time_sk = dbo.time_dim.t_time_sk
     AND ss_hdemo_sk = dbo.household_demographics.hd_demo_sk
     AND ss_store_sk = s_store_sk
     AND dbo.time_dim.t_hour = 12
     AND dbo.time_dim.t_minute < 30
     AND ((dbo.household_demographics.hd_dep_count = 4
           AND dbo.household_demographics.hd_vehicle_count<=4+2)
          OR (dbo.household_demographics.hd_dep_count = 2
              AND dbo.household_demographics.hd_vehicle_count<=2+2)
          OR (dbo.household_demographics.hd_dep_count = 0
              AND dbo.household_demographics.hd_vehicle_count<=0+2))
     AND dbo.store.s_store_name = 'ese') s8
OPTION (LABEL = 'q88')