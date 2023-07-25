--q38.sql--

SELECT TOP 100 count(*)
FROM
  (SELECT DISTINCT c_last_name,
                   c_first_name,
                   d_date
   FROM dbo.store_sales,
        dbo.date_dim,
        dbo.customer
   WHERE dbo.store_sales.ss_sold_date_sk = dbo.date_dim.d_date_sk
     AND dbo.store_sales.ss_customer_sk = dbo.customer.c_customer_sk
     AND d_month_seq BETWEEN 1200 AND 1200 + 11 INTERSECT
     SELECT DISTINCT c_last_name,
                     c_first_name,
                     d_date
     FROM dbo.catalog_sales,
          dbo.date_dim,
          dbo.customer WHERE dbo.catalog_sales.cs_sold_date_sk = dbo.date_dim.d_date_sk
     AND dbo.catalog_sales.cs_bill_customer_sk = dbo.customer.c_customer_sk
     AND d_month_seq BETWEEN 1200 AND 1200 + 11 INTERSECT
     SELECT DISTINCT c_last_name,
                     c_first_name,
                     d_date
     FROM dbo.web_sales,
          dbo.date_dim,
          dbo.customer WHERE dbo.web_sales.ws_sold_date_sk = dbo.date_dim.d_date_sk
     AND dbo.web_sales.ws_bill_customer_sk = dbo.customer.c_customer_sk
     AND d_month_seq BETWEEN 1200 AND 1200 + 11 ) hot_cust
OPTION (LABEL = 'q38')
