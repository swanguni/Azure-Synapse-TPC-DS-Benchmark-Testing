USE CATALOG o9o9uccatalog;
--q30.sql--
 WITH customer_total_return AS
  (SELECT wr_returning_customer_sk AS ctr_customer_sk ,
          ca_state AS ctr_state,
          sum(wr_return_amt) AS ctr_total_return
   FROM TPCDS.web_returns,
        TPCDS.date_dim,
        TPCDS.customer_address
   WHERE wr_returned_date_sk = d_date_sk
     AND d_year = 2002
     AND wr_returning_addr_sk = ca_address_sk
   GROUP BY wr_returning_customer_sk,
            ca_state)
SELECT /*TOP 100*/ c_customer_id,
       c_salutation,
       c_first_name,
       c_last_name,
       c_preferred_cust_flag ,
       c_birth_day,
       c_birth_month,
       c_birth_year,
       c_birth_country,
       c_login,
       c_email_address ,
       c_last_review_date,
       ctr_total_return
FROM customer_total_return ctr1,
     TPCDS.customer_address,
     TPCDS.customer
WHERE ctr1.ctr_total_return >
    (SELECT avg(ctr_total_return)*1.2
     FROM customer_total_return ctr2
     WHERE ctr1.ctr_state = ctr2.ctr_state)
  AND ca_address_sk = c_current_addr_sk
  AND ca_state = 'GA'
  AND ctr1.ctr_customer_sk = c_customer_sk
ORDER BY c_customer_id,
         c_salutation,
         c_first_name,
         c_last_name,
         c_preferred_cust_flag ,
         c_birth_day,
         c_birth_month,
         c_birth_year,
         c_birth_country,
         c_login,
         c_email_address ,
         c_last_review_date,
         ctr_total_return
LIMIT 100
-- OPTION (LABEL = 'q30')
