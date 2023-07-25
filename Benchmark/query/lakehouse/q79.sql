--q79.sql--

SELECT TOP 100 c_last_name,
       c_first_name,
       SUBSTRING(s_city, 1, 30),
       ss_ticket_number,
       amt,
       profit
FROM
  (SELECT ss_ticket_number ,
          ss_customer_sk ,
          dbo.store.s_city ,
          sum(ss_coupon_amt) amt ,
          sum(ss_net_profit) profit
   FROM dbo.store_sales,
        dbo.date_dim,
        dbo.store,
        dbo.household_demographics
   WHERE dbo.store_sales.ss_sold_date_sk = dbo.date_dim.d_date_sk
     AND dbo.store_sales.ss_store_sk = dbo.store.s_store_sk
     AND dbo.store_sales.ss_hdemo_sk = dbo.household_demographics.hd_demo_sk
     AND (dbo.household_demographics.hd_dep_count = 6
          OR dbo.household_demographics.hd_vehicle_count > 2)
     AND dbo.date_dim.d_dow = 1
     AND dbo.date_dim.d_year IN (1999,
                                   1999+1,
                                   1999+2)
     AND dbo.store.s_number_employees BETWEEN 200 AND 295
   GROUP BY ss_ticket_number,
            ss_customer_sk,
            ss_addr_sk,
            dbo.store.s_city) ms,
     dbo.customer
WHERE ss_customer_sk = c_customer_sk
ORDER BY c_last_name,
         c_first_name,
         SUBSTRING(s_city, 1, 30),
         profit
OPTION (LABEL = 'q79')
		 