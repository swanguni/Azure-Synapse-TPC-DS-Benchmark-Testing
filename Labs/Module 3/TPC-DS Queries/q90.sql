--q90.sql--

SELECT TOP 100 cast(amc AS decimal(15, 4))/cast(pmc AS decimal(15, 4)) am_pm_ratio
FROM
  (SELECT count(*) amc
   FROM TPCDS.web_sales,
        TPCDS.household_demographics,
        TPCDS.time_dim,
        TPCDS.web_page
   WHERE ws_sold_time_sk = TPCDS.time_dim.t_time_sk
     AND ws_ship_hdemo_sk = TPCDS.household_demographics.hd_demo_sk
     AND ws_web_page_sk = TPCDS.web_page.wp_web_page_sk
     AND TPCDS.time_dim.t_hour BETWEEN 8 AND 8+1
     AND TPCDS.household_demographics.hd_dep_count = 6
     AND TPCDS.web_page.wp_char_count BETWEEN 5000 AND 5200) AT
CROSS JOIN
  (SELECT count(*) pmc
   FROM TPCDS.web_sales,
        TPCDS.household_demographics,
        TPCDS.time_dim,
        TPCDS.web_page
   WHERE ws_sold_time_sk = TPCDS.time_dim.t_time_sk
     AND ws_ship_hdemo_sk = TPCDS.household_demographics.hd_demo_sk
     AND ws_web_page_sk = TPCDS.web_page.wp_web_page_sk
     AND TPCDS.time_dim.t_hour BETWEEN 19 AND 19+1
     AND TPCDS.household_demographics.hd_dep_count = 6
     AND TPCDS.web_page.wp_char_count BETWEEN 5000 AND 5200) pt
ORDER BY am_pm_ratio
OPTION (LABEL = 'q90')
