--q32.sql--

SELECT TOP 100 sum(cs_ext_discount_amt) AS [excess discount amount]
FROM TPCDS.catalog_sales,
     TPCDS.item,
     TPCDS.date_dim
WHERE i_manufact_id = 977
  AND i_item_sk = cs_item_sk
  AND d_date BETWEEN CAST ('2000-01-27' AS date) AND (DATEADD(DAY, 90, cast('2000-01-27' AS date)))
  AND d_date_sk = cs_sold_date_sk
  AND cs_ext_discount_amt >
    (SELECT 1.3 * avg(cs_ext_discount_amt)
     FROM TPCDS.catalog_sales,
          TPCDS.date_dim
     WHERE cs_item_sk = i_item_sk
       AND d_date BETWEEN CAST ('2000-01-27' AS date) AND (DATEADD(DAY, 90, cast('2000-01-27' AS date)))
       AND d_date_sk = cs_sold_date_sk)
OPTION (LABEL = 'q32')
