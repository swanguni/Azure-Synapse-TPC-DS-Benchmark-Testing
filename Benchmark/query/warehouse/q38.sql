--q38.sql--

SELECT TOP 100 count(*)
FROM
  (SELECT DISTINCT c_last_name,
                   c_first_name,
                   d_date
   FROM TPCDS.store_sales,
        TPCDS.date_dim,
        TPCDS.customer
   WHERE TPCDS.store_sales.ss_sold_date_sk = TPCDS.date_dim.d_date_sk
     AND TPCDS.store_sales.ss_customer_sk = TPCDS.customer.c_customer_sk
     AND d_month_seq BETWEEN 1200 AND 1200 + 11 INTERSECT
     SELECT DISTINCT c_last_name,
                     c_first_name,
                     d_date
     FROM TPCDS.catalog_sales,
          TPCDS.date_dim,
          TPCDS.customer WHERE TPCDS.catalog_sales.cs_sold_date_sk = TPCDS.date_dim.d_date_sk
     AND TPCDS.catalog_sales.cs_bill_customer_sk = TPCDS.customer.c_customer_sk
     AND d_month_seq BETWEEN 1200 AND 1200 + 11 INTERSECT
     SELECT DISTINCT c_last_name,
                     c_first_name,
                     d_date
     FROM TPCDS.web_sales,
          TPCDS.date_dim,
          TPCDS.customer WHERE TPCDS.web_sales.ws_sold_date_sk = TPCDS.date_dim.d_date_sk
     AND TPCDS.web_sales.ws_bill_customer_sk = TPCDS.customer.c_customer_sk
     AND d_month_seq BETWEEN 1200 AND 1200 + 11 ) hot_cust
OPTION (LABEL = 'q38')
