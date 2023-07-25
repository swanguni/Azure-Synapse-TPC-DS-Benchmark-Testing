--q52.sql--

SELECT TOP 100 dt.d_year ,
       dbo.item.i_brand_id brand_id ,
       dbo.item.i_brand brand ,
       sum(ss_ext_sales_price) ext_price
FROM dbo.date_dim dt,
     dbo.store_sales,
     dbo.item
WHERE dt.d_date_sk = dbo.store_sales.ss_sold_date_sk
  AND dbo.store_sales.ss_item_sk = dbo.item.i_item_sk
  AND dbo.item.i_manager_id = 1
  AND dt.d_moy=11
  AND dt.d_year=2000
GROUP BY dt.d_year,
         dbo.item.i_brand,
         dbo.item.i_brand_id
ORDER BY dt.d_year,
         ext_price DESC,
         brand_id
OPTION (LABEL = 'q52')
		 