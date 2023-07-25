--q90.sql--

SELECT TOP 100 cast(amc AS decimal(15, 4))/cast(pmc AS decimal(15, 4)) am_pm_ratio
FROM
  (SELECT count(*) amc
   FROM dbo.web_sales,
        dbo.household_demographics,
        dbo.time_dim,
        dbo.web_page
   WHERE ws_sold_time_sk = dbo.time_dim.t_time_sk
     AND ws_ship_hdemo_sk = dbo.household_demographics.hd_demo_sk
     AND ws_web_page_sk = dbo.web_page.wp_web_page_sk
     AND dbo.time_dim.t_hour BETWEEN 8 AND 8+1
     AND dbo.household_demographics.hd_dep_count = 6
     AND dbo.web_page.wp_char_count BETWEEN 5000 AND 5200) AT
CROSS JOIN
  (SELECT count(*) pmc
   FROM dbo.web_sales,
        dbo.household_demographics,
        dbo.time_dim,
        dbo.web_page
   WHERE ws_sold_time_sk = dbo.time_dim.t_time_sk
     AND ws_ship_hdemo_sk = dbo.household_demographics.hd_demo_sk
     AND ws_web_page_sk = dbo.web_page.wp_web_page_sk
     AND dbo.time_dim.t_hour BETWEEN 19 AND 19+1
     AND dbo.household_demographics.hd_dep_count = 6
     AND dbo.web_page.wp_char_count BETWEEN 5000 AND 5200) pt
ORDER BY am_pm_ratio
OPTION (LABEL = 'q90')
