USE CATALOG o9o9uccatalog;
--q52.sql--

SELECT /*TOP 100*/ dt.d_year ,
       TPCDS.item.i_brand_id brand_id ,
       TPCDS.item.i_brand brand ,
       sum(ss_ext_sales_price) ext_price
FROM TPCDS.date_dim dt,
     TPCDS.store_sales,
     TPCDS.item
WHERE dt.d_date_sk = TPCDS.store_sales.ss_sold_date_sk
  AND TPCDS.store_sales.ss_item_sk = TPCDS.item.i_item_sk
  AND TPCDS.item.i_manager_id = 1
  AND dt.d_moy=11
  AND dt.d_year=2000
GROUP BY dt.d_year,
         TPCDS.item.i_brand,
         TPCDS.item.i_brand_id
ORDER BY dt.d_year,
         ext_price DESC,
         brand_id
LIMIT 100
-- OPTION (LABEL = 'q52')
		 