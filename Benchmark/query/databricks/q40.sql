USE CATALOG o9o9uccatalog;
--q40.sql--

SELECT /*TOP 100*/ w_state ,
       i_item_id ,
       sum(CASE
               WHEN (cast(d_date AS date) < cast('2000-03-11' AS date)) THEN cs_sales_price - coalesce(cr_refunded_cash, 0)
               ELSE 0
           END) AS sales_before ,
       sum(CASE
               WHEN (cast(d_date AS date) >= cast('2000-03-11' AS date)) THEN cs_sales_price - coalesce(cr_refunded_cash, 0)
               ELSE 0
           END) AS sales_after
FROM TPCDS.catalog_sales
LEFT OUTER JOIN TPCDS.catalog_returns ON (cs_order_number = cr_order_number
                                          AND cs_item_sk = cr_item_sk) ,TPCDS.warehouse,
                                                                        TPCDS.item,
                                                                        TPCDS.date_dim
WHERE i_current_price BETWEEN 0.99 AND 1.49
  AND i_item_sk = cs_item_sk
  AND cs_warehouse_sk = w_warehouse_sk
  AND cs_sold_date_sk = d_date_sk
  AND d_date BETWEEN (DATEADD(DAY, -30, cast('2000-03-11' AS date))) AND (DATEADD(DAY, 30, cast('2000-03-11' AS date)))
GROUP BY w_state,
         i_item_id
ORDER BY w_state,
         i_item_id
LIMIT 100
-- OPTION (LABEL = 'q40')
