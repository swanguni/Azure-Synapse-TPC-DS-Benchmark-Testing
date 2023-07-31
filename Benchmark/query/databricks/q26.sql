USE CATALOG o9o9uccatalog;
--q26.sql--

SELECT /*TOP 100*/ i_item_id,
       avg(cs_quantity) agg1,
       avg(cs_list_price) agg2,
       avg(cs_coupon_amt) agg3,
       avg(cs_sales_price) agg4
FROM TPCDS.catalog_sales,
     TPCDS.customer_demographics,
     TPCDS.date_dim,
     TPCDS.item,
     TPCDS.promotion
WHERE cs_sold_date_sk = d_date_sk
  AND cs_item_sk = i_item_sk
  AND cs_bill_cdemo_sk = cd_demo_sk
  AND cs_promo_sk = p_promo_sk
  AND cd_gender = 'M'
  AND cd_marital_status = 'S'
  AND trim(cd_education_status) = 'College'
  AND (p_channel_email = 'N'
       OR p_channel_event = 'N')
  AND d_year = 2000
GROUP BY i_item_id
ORDER BY i_item_id
LIMIT 100
-- OPTION (LABEL = 'q26')
