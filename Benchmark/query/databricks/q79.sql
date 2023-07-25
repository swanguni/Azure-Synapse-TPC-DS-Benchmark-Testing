USE CATALOG o9o9uccatalog;
--q79.sql--

SELECT /*TOP 100*/ c_last_name,
       c_first_name,
       SUBSTRING(s_city, 1, 30),
       ss_ticket_number,
       amt,
       profit
FROM
  (SELECT ss_ticket_number ,
          ss_customer_sk ,
          TPCDS.store.s_city ,
          sum(ss_coupon_amt) amt ,
          sum(ss_net_profit) profit
   FROM TPCDS.store_sales,
        TPCDS.date_dim,
        TPCDS.store,
        TPCDS.household_demographics
   WHERE TPCDS.store_sales.ss_sold_date_sk = TPCDS.date_dim.d_date_sk
     AND TPCDS.store_sales.ss_store_sk = TPCDS.store.s_store_sk
     AND TPCDS.store_sales.ss_hdemo_sk = TPCDS.household_demographics.hd_demo_sk
     AND (TPCDS.household_demographics.hd_dep_count = 6
          OR TPCDS.household_demographics.hd_vehicle_count > 2)
     AND TPCDS.date_dim.d_dow = 1
     AND TPCDS.date_dim.d_year IN (1999,
                                   1999+1,
                                   1999+2)
     AND TPCDS.store.s_number_employees BETWEEN 200 AND 295
   GROUP BY ss_ticket_number,
            ss_customer_sk,
            ss_addr_sk,
            TPCDS.store.s_city) ms,
     TPCDS.customer
WHERE ss_customer_sk = c_customer_sk
ORDER BY c_last_name,
         c_first_name,
         SUBSTRING(s_city, 1, 30),
         profit
LIMIT 100
-- OPTION (LABEL = 'q79')
		 