USE CATALOG o9o9uccatalog;
--q55.sql--

SELECT /*TOP 100*/ i_brand_id brand_id,
       i_brand brand,
       sum(ss_ext_sales_price) ext_price
FROM TPCDS.date_dim,
     TPCDS.store_sales,
     TPCDS.item
WHERE d_date_sk = ss_sold_date_sk
  AND ss_item_sk = i_item_sk
  AND i_manager_id=28
  AND d_moy=11
  AND d_year=1999
GROUP BY i_brand,
         i_brand_id
ORDER BY ext_price DESC,
         brand_id
LIMIT 100
-- OPTION (LABEL = 'q55')
		 