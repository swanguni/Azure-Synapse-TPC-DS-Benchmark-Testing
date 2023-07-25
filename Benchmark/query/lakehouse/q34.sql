--q34.sql--

SELECT c_last_name,
       c_first_name,
       c_salutation,
       c_preferred_cust_flag,
       ss_ticket_number,
       cnt
FROM
  (SELECT ss_ticket_number,
          ss_customer_sk,
          count(*) cnt
   FROM dbo.store_sales,
        dbo.date_dim,
        dbo.store,
        dbo.household_demographics
   WHERE dbo.store_sales.ss_sold_date_sk = dbo.date_dim.d_date_sk
     AND dbo.store_sales.ss_store_sk = dbo.store.s_store_sk
     AND dbo.store_sales.ss_hdemo_sk = dbo.household_demographics.hd_demo_sk
     AND (dbo.date_dim.d_dom BETWEEN 1 AND 3
          OR dbo.date_dim.d_dom BETWEEN 25 AND 28)
     AND (dbo.household_demographics.hd_buy_potential = '>10000'
          OR dbo.household_demographics.hd_buy_potential = 'unknown')
     AND dbo.household_demographics.hd_vehicle_count > 0
     AND (CASE
              WHEN dbo.household_demographics.hd_vehicle_count > 0 THEN dbo.household_demographics.hd_dep_coundbo.household_demographics.hd_vehicle_count
              ELSE NULL
          END) > 1.2
     AND dbo.date_dim.d_year IN (1999,
                                   1999+1,
                                   1999+2)
     AND dbo.store.s_county IN ('Williamson County',
                                  'Williamson County',
                                  'Williamson County',
                                  'Williamson County',
                                  'Williamson County',
                                  'Williamson County',
                                  'Williamson County',
                                  'Williamson County')
   GROUP BY ss_ticket_number,
            ss_customer_sk) dn,
     dbo.customer
WHERE ss_customer_sk = c_customer_sk
  AND cnt BETWEEN 15 AND 20
ORDER BY c_last_name,
         c_first_name,
         c_salutation,
         c_preferred_cust_flag DESC,
         ss_ticket_number
OPTION (LABEL = 'q34')