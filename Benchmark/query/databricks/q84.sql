USE CATALOG o9o9uccatalog;
--q84.sql--

SELECT /*TOP 100*/ c_customer_id AS customer_id ,
       coalesce(c_last_name, '') + ', ' + coalesce(c_first_name, '') AS customername
FROM TPCDS.customer ,
     TPCDS.customer_address ,
     TPCDS.customer_demographics ,
     TPCDS.household_demographics ,
     TPCDS.income_band ,
     TPCDS.store_returns
WHERE ca_city = 'Edgewood'
  AND c_current_addr_sk = ca_address_sk
  AND ib_lower_bound >= 38128
  AND ib_upper_bound <= 38128 + 50000
  AND ib_income_band_sk = hd_income_band_sk
  AND cd_demo_sk = c_current_cdemo_sk
  AND hd_demo_sk = c_current_hdemo_sk
  AND sr_cdemo_sk = cd_demo_sk
ORDER BY c_customer_id
LIMIT 100
-- OPTION (LABEL = 'q84')
