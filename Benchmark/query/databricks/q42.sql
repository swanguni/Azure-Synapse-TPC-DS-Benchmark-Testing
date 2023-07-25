USE CATALOG o9o9uccatalog;
--q42.sql--

SELECT /*TOP 100*/ dt.d_year,
       TPCDS.item.i_category_id,
       TPCDS.item.i_category,
       sum(ss_ext_sales_price)
FROM TPCDS.date_dim dt,
     TPCDS.store_sales,
     TPCDS.item
WHERE dt.d_date_sk = TPCDS.store_sales.ss_sold_date_sk
  AND TPCDS.store_sales.ss_item_sk = TPCDS.item.i_item_sk
  AND TPCDS.item.i_manager_id = 1
  AND dt.d_moy=11
  AND dt.d_year=2000
GROUP BY dt.d_year ,
         TPCDS.item.i_category_id ,
         TPCDS.item.i_category
ORDER BY sum(ss_ext_sales_price) DESC,dt.d_year ,
                                      TPCDS.item.i_category_id ,
                                      TPCDS.item.i_category
LIMIT 100
-- OPTION (LABEL = 'q42')
