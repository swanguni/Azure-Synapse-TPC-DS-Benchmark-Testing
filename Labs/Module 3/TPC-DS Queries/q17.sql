--q17.sql--

SELECT TOP 100 i_item_id ,
       i_item_desc ,
       s_state ,
       count(ss_quantity) AS store_sales_quantitycount ,
       avg(ss_quantity) AS store_sales_quantityave ,
       STDEV(ss_quantity) AS store_sales_quantitystdev ,
       STDEV(ss_quantity)/avg(ss_quantity) AS store_sales_quantitycov ,
       count(sr_return_quantity) as_store_returns_quantitycount ,
       avg(sr_return_quantity) as_store_returns_quantityave ,
       STDEV(sr_return_quantity) as_store_returns_quantitystdev ,
       STDEV(sr_return_quantity)/avg(sr_return_quantity) AS store_returns_quantitycov ,
       count(cs_quantity) AS catalog_sales_quantitycount,
       avg(cs_quantity) AS catalog_sales_quantityave ,
       STDEV(cs_quantity)/avg(cs_quantity) AS catalog_sales_quantitystdev ,
       STDEV(cs_quantity)/avg(cs_quantity) AS catalog_sales_quantitycov
FROM TPCDS.store_sales,
     TPCDS.store_returns,
     TPCDS.catalog_sales,
     TPCDS.date_dim d1,
     TPCDS.date_dim d2,
     TPCDS.date_dim d3,
     TPCDS.store,
     TPCDS.item
WHERE d1.d_quarter_name = '2001Q1'
  AND d1.d_date_sk = ss_sold_date_sk
  AND i_item_sk = ss_item_sk
  AND s_store_sk = ss_store_sk
  AND ss_customer_sk = sr_customer_sk
  AND ss_item_sk = sr_item_sk
  AND ss_ticket_number = sr_ticket_number
  AND sr_returned_date_sk = d2.d_date_sk
  AND d2.d_quarter_name IN ('2001Q1',
                            '2001Q2',
                            '2001Q3')
  AND sr_customer_sk = cs_bill_customer_sk
  AND sr_item_sk = cs_item_sk
  AND cs_sold_date_sk = d3.d_date_sk
  AND d3.d_quarter_name IN ('2001Q1',
                            '2001Q2',
                            '2001Q3')
GROUP BY i_item_id,
         i_item_desc,
         s_state
ORDER BY i_item_id,
         i_item_desc,
         s_state
OPTION (LABEL = 'q17')
		 