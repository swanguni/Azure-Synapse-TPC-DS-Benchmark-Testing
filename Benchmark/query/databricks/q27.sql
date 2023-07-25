USE CATALOG o9o9uccatalog;
--q27.sql--

SELECT /*TOP 100*/ i_item_id,
       s_state,
       grouping(s_state) g_state,
       avg(ss_quantity) agg1,
       avg(ss_list_price) agg2,
       avg(ss_coupon_amt) agg3,
       avg(ss_sales_price) agg4
FROM TPCDS.store_sales,
     TPCDS.customer_demographics,
     TPCDS.date_dim,
     TPCDS.store,
     TPCDS.item
WHERE ss_sold_date_sk = d_date_sk
  AND ss_item_sk = i_item_sk
  AND ss_store_sk = s_store_sk
  AND ss_cdemo_sk = cd_demo_sk
  AND cd_gender = 'M'
  AND cd_marital_status = 'S'
  AND cd_education_status = 'College'
  AND d_year = 2002
  AND s_state IN ('TN',
                  'TN',
                  'TN',
                  'TN',
                  'TN',
                  'TN')
GROUP BY ROLLUP (i_item_id,
                 s_state)
ORDER BY i_item_id,
         s_state
LIMIT 100
-- OPTION (LABEL = 'q27')
		 