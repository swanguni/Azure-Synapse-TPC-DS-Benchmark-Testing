--q92.sql--

SELECT TOP 100 sum(ws_ext_discount_amt) AS [Excess Discount Amount]
FROM TPCDS.web_sales,
     TPCDS.item,
     TPCDS.date_dim
WHERE i_manufact_id = 350
  AND i_item_sk = ws_item_sk
  AND d_date BETWEEN CAST ('2000-01-27' AS date) AND (DATEADD(DAY, 90, cast('2000-01-27' AS date)))
  AND d_date_sk = ws_sold_date_sk
  AND ws_ext_discount_amt >
    (SELECT 1.3 * avg(ws_ext_discount_amt)
     FROM TPCDS.web_sales,
          TPCDS.date_dim
     WHERE ws_item_sk = i_item_sk
       AND d_date BETWEEN CAST ('2000-01-27' AS date) AND (DATEADD(DAY, 90, cast('2000-01-27' AS date)))
       AND d_date_sk = ws_sold_date_sk )
ORDER BY sum(ws_ext_discount_amt)
OPTION (LABEL = 'q92')
