--q3.sql--

SELECT TOP 100 dt.d_year,
       dbo.item.i_brand_id brand_id,
       dbo.item.i_brand brand,
       SUM(ss_ext_sales_price) sum_agg
FROM dbo.date_dim dt,
     dbo.store_sales,
     dbo.item
WHERE dt.d_date_sk = dbo.store_sales.ss_sold_date_sk
  AND dbo.store_sales.ss_item_sk = dbo.item.i_item_sk
  AND dbo.item.i_manufact_id = 128
  AND dt.d_moy=11
GROUP BY dt.d_year,
         dbo.item.i_brand,
         dbo.item.i_brand_id
ORDER BY dt.d_year,
         sum_agg DESC,
         brand_id
OPTION (LABEL = 'q3')
		 