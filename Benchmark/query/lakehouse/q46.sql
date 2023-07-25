--q46.sql--

SELECT TOP 100 c_last_name,
       c_first_name,
       ca_city,
       bought_city,
       ss_ticket_number,
       amt,
       profit
FROM
  (SELECT ss_ticket_number ,
          ss_customer_sk ,
          ca_city bought_city ,
          sum(ss_coupon_amt) amt ,
          sum(ss_net_profit) profit
   FROM dbo.store_sales,
        dbo.date_dim,
        dbo.store,
        dbo.household_demographics,
        dbo.customer_address
   WHERE dbo.store_sales.ss_sold_date_sk = dbo.date_dim.d_date_sk
     AND dbo.store_sales.ss_store_sk = dbo.store.s_store_sk
     AND dbo.store_sales.ss_hdemo_sk = dbo.household_demographics.hd_demo_sk
     AND dbo.store_sales.ss_addr_sk = dbo.customer_address.ca_address_sk
     AND (dbo.household_demographics.hd_dep_count = 4
          OR dbo.household_demographics.hd_vehicle_count= 3)
     AND dbo.date_dim.d_dow IN (6,
                                  0)
     AND dbo.date_dim.d_year IN (1999,
                                   1999+1,
                                   1999+2)
     AND dbo.store.s_city IN ('Fairview',
                                'Midway',
                                'Fairview',
                                'Fairview',
                                'Fairview')
   GROUP BY ss_ticket_number,
            ss_customer_sk,
            ss_addr_sk,
            ca_city) dn,
     dbo.customer,
     dbo.customer_address current_addr
WHERE ss_customer_sk = c_customer_sk
  AND dbo.customer.c_current_addr_sk = current_addr.ca_address_sk
  AND current_addr.ca_city <> bought_city
ORDER BY c_last_name,
         c_first_name,
         ca_city,
         bought_city,
         ss_ticket_number
OPTION (LABEL = 'q46')
		 