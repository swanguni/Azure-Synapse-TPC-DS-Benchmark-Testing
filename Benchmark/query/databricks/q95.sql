USE CATALOG o9o9uccatalog;
--q95.sql--
 WITH ws_wh AS
  (SELECT ws1.ws_order_number,
          ws1.ws_warehouse_sk wh1,
          ws2.ws_warehouse_sk wh2
   FROM TPCDS.web_sales ws1,
        TPCDS.web_sales ws2
   WHERE ws1.ws_order_number = ws2.ws_order_number
     AND ws1.ws_warehouse_sk <> ws2.ws_warehouse_sk)
SELECT /*TOP 100*/ count(DISTINCT ws_order_number) AS [order count] ,
       sum(ws_ext_ship_cost) AS [total shipping cost] ,
       sum(ws_net_profit) AS [total net profit]
FROM TPCDS.web_sales ws1,
     TPCDS.date_dim,
     TPCDS.customer_address,
     TPCDS.web_site
WHERE d_date BETWEEN CAST ('1999-02-01' AS date) AND (DATEADD(DAY, 60, cast('1999-02-01' AS date)))
  AND ws1.ws_ship_date_sk = d_date_sk
  AND ws1.ws_ship_addr_sk = ca_address_sk
  AND ca_state = 'IL'
  AND ws1.ws_web_site_sk = web_site_sk
  AND web_company_name = 'pri'
  AND ws1.ws_order_number IN
    (SELECT ws_order_number
     FROM ws_wh)
  AND ws1.ws_order_number IN
    (SELECT wr_order_number
     FROM TPCDS.web_returns,
          ws_wh
     WHERE wr_order_number = ws_wh.ws_order_number)
ORDER BY count(DISTINCT ws_order_number)
LIMIT 100
-- OPTION (LABEL = 'q95')
