--q3.sql--

SELECT TOP 100 dt.d_year,
       TPCDS.item.i_brand_id brand_id,
       TPCDS.item.i_brand brand,
       SUM(ss_ext_sales_price) sum_agg
FROM TPCDS.date_dim dt,
     TPCDS.store_sales,
     TPCDS.item
WHERE dt.d_date_sk = TPCDS.store_sales.ss_sold_date_sk
  AND TPCDS.store_sales.ss_item_sk = TPCDS.item.i_item_sk
  AND TPCDS.item.i_manufact_id = 128
  AND dt.d_moy=11
GROUP BY dt.d_year,
         TPCDS.item.i_brand,
         TPCDS.item.i_brand_id
ORDER BY dt.d_year,
         sum_agg DESC,
         brand_id
OPTION (LABEL = 'q3')
		 