--q19.sql--

SELECT TOP 100 i_brand_id brand_id,
       i_brand brand,
       i_manufact_id,
       i_manufact,
       sum(ss_ext_sales_price) ext_price
FROM TPCDS.date_dim,
     TPCDS.store_sales,
     TPCDS.item,
     TPCDS.customer,
     TPCDS.customer_address,
     TPCDS.store
WHERE d_date_sk = ss_sold_date_sk
  AND ss_item_sk = i_item_sk
  AND i_manager_id = 8
  AND d_moy = 11
  AND d_year = 1998
  AND ss_customer_sk = c_customer_sk
  AND c_current_addr_sk = ca_address_sk
  AND SUBSTRING(ca_zip, 1, 5) <> SUBSTRING(s_zip, 1, 5)
  AND ss_store_sk = s_store_sk
GROUP BY i_brand,
         i_brand_id,
         i_manufact_id,
         i_manufact
ORDER BY ext_price DESC,
         brand,
         brand_id,
         i_manufact_id,
         i_manufact
OPTION (LABEL = 'q19')
